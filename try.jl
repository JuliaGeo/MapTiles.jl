using MapTiles: MapTiles
import MapTiles as MT
using Extents
using GeoInterface: GeoInterface, extent
import GeoFormatTypes
using HTTP
using Makie
using GLMakie
import ImageMagick

const R2D = 180 / pi
const RE = 6378137.0
const CE = 2 * pi * RE
const EPSILON = 1e-14
const LL_EPSILON = 1e-11

# represent the two major CRS so we can dispatch on them
struct WGS84 <: GeoFormatTypes.CoordinateReferenceSystemFormat end
struct WebMercator <: GeoFormatTypes.CoordinateReferenceSystemFormat end

Base.convert(::Type{GeoFormatTypes.EPSG}, ::WebMercator) = EPSG(3857)
Base.convert(::Type{GeoFormatTypes.EPSG}, ::WGS84) = EPSG(4326)
Base.convert(::Type{String}, ::WebMercator) = "EPSG:3857"
Base.convert(::Type{String}, ::WGS84) = "EPSG:4326"
Base.convert(::Type{Int}, ::WebMercator) = 3857
Base.convert(::Type{Int}, ::WGS84) = 4326

"Convert web mercator x, y to longitude and latitude"
function project(point, from::WebMercator, to::WGS84)
    x = GeoInterface.x(point)
    y = GeoInterface.y(point)

    lng = x * R2D / RE
    lat = ((pi / 2) - 2.0 * atan(exp(-y / RE))) * R2D
    return lng, lat
end

"Convert longitude and latitude to web mercator x, y"
function project(point, from::WGS84, to::WebMercator)
    lng = GeoInterface.x(point)
    lat = GeoInterface.y(point)

    x = RE * deg2rad(lng)

    y = if lat <= -90
        -Inf
    elseif lat >= 90
        Inf
    else
        RE * log(tan((pi / 4) + (0.5 * deg2rad(lat))))
    end

    return x, y
end

const web_mercator = WebMercator()
const wgs84 = WGS84()

struct Tile
    x::Int
    y::Int
    z::Int
end

Tile(index::CartesianIndex{2}, zoom::Integer) = Tile(index[1], index[2], zoom)

"Get the tile containing a longitude and latitude"
function Tile(point, zoom::Integer, crs::WGS84)
    lng = GeoInterface.x(point)
    lat = GeoInterface.y(point)

    x = lng / 360.0 + 0.5
    sinlat = sin(deg2rad(lat))
    y = 0.5 - 0.25 * log((1.0 + sinlat) / (1.0 - sinlat)) / pi

    Z2 = 2^zoom

    xtile = if x <= 0
        0
    elseif x >= 1
        Z2 - 1
    else
        # To address loss of precision in round-tripping between tile
        # and lng/lat, points within EPSILON of the right side of a tile
        # are counted in the next tile over.
        floor(Int, (x + EPSILON) * Z2)
    end
    ytile = if y <= 0
        0
    elseif y >= 1
        Z2 - 1
    else
        floor(Int, (y + EPSILON) * Z2)
    end
    return Tile(xtile, ytile, zoom)
end

struct TileGrid
    grid::CartesianIndices{2, Tuple{UnitRange{Int}, UnitRange{Int}}}
    z::Int
end

TileGrid(tile::Tile) = TileGrid(CartesianIndices((tile.x:tile.x, tile.y:tile.y)), tile.z)

Base.length(tilegrid::TileGrid) = length(tilegrid.grid)
Base.size(tilegrid::TileGrid, dims...) = size(tilegrid.grid, dims...)
Base.getindex(tilegrid::TileGrid, i) = Tile(tilegrid.grid[i], tilegrid.z)
Base.firstindex(tilegrid::TileGrid) = firstindex(tilegrid.grid)
Base.lastindex(tilegrid::TileGrid) = lastindex(tilegrid.grid)

function Base.iterate(tilegrid::TileGrid, state=1)
    if state > length(tilegrid)
        nothing
    else
        (tilegrid[state], state+1)
    end
end

"Returns the bounding box of a tile in lng lat"
function GeoInterface.extent(tile::Tile, crs::WGS84)
    Z2 = 2^tile.z

    ul_lon_deg = tile.x / Z2 * 360.0 - 180.0
    ul_lat_rad = atan(sinh(pi * (1 - 2 * tile.y / Z2)))
    ul_lat_deg = rad2deg(ul_lat_rad)

    lr_lon_deg = (tile.x + 1) / Z2 * 360.0 - 180.0
    lr_lat_rad = atan(sinh(pi * (1 - 2 * (tile.y + 1) / Z2)))
    lr_lat_deg = rad2deg(lr_lat_rad)

    return Extent(X = (ul_lon_deg, lr_lon_deg), Y = (lr_lat_deg, ul_lat_deg))
end

"Get the web mercator bounding box of a tile"
function GeoInterface.extent(tile::Tile, crs::WebMercator)
    tile_size = CE / 2^tile.z

    left = tile.x * tile_size - CE / 2
    right = left + tile_size

    top = CE / 2 - tile.y * tile_size
    bottom = top - tile_size

    return Extent(X=(left, right), Y=(bottom, top))
end

"Get the tiles overlapped by a geographic bounding box"
function TileGrid(bbox::Extent, zoom::Int, crs::WGS84)
    # Mercantile splits the bbox in two along the antimeridian if this happens.
    # Decide if that case should be handled here or before, also considering
    # antimeridian discussion in https://github.com/rafaqz/Extents.jl/issues/4
    @assert bbox.X[1] < bbox.X[2]

    # Clamp bounding values.
    max_bbox = Extent(X = (-180.0, 180.0), Y = (-85.051129, 85.051129))
    bbox = Extents.intersect(bbox, max_bbox)

    ul_tile = Tile((bbox.X[1], bbox.Y[1]), zoom, crs)
    lr_tile = Tile((bbox.X[2] - LL_EPSILON, bbox.Y[2] + LL_EPSILON), zoom, crs)

    grid = CartesianIndices((ul_tile.x:lr_tile.x, lr_tile.y:ul_tile.y))
    return TileGrid(grid, zoom)
end

"Returns the bounding box of a tile in lng lat"
function GeoInterface.extent(tilegrid::TileGrid, crs::WGS84)
    Z2 = 2^tilegrid.z

    ul_idx = tilegrid.grid[begin]
    lr_idx = tilegrid.grid[end]
    ul_x, ul_y = ul_idx[1], ul_idx[2]
    lr_x, lr_y = lr_idx[1], lr_idx[2]

    ul_lon_deg = ul_x / Z2 * 360.0 - 180.0
    ul_lat_rad = atan(sinh(pi * (1 - 2 * ul_y / Z2)))
    ul_lat_deg = rad2deg(ul_lat_rad)

    lr_lon_deg = (lr_x + 1) / Z2 * 360.0 - 180.0
    lr_lat_rad = atan(sinh(pi * (1 - 2 * (lr_y + 1) / Z2)))
    lr_lat_deg = rad2deg(lr_lat_rad)

    return Extent(X = (ul_lon_deg, lr_lon_deg), Y = (lr_lat_deg, ul_lat_deg))
end

"Get the web mercator bounding box of a tile"
function GeoInterface.extent(tilegrid::TileGrid, crs::WebMercator)
    tile_size = CE / 2^tilegrid.z

    ul_idx = tilegrid.grid[begin]
    ul_x, ul_y = ul_idx[1], ul_idx[2]
    nx, ny = size(tilegrid)

    left = ul_x * tile_size - CE / 2
    right = left + tile_size * nx

    top = CE / 2 - ul_y * tile_size
    bottom = top - tile_size * ny

    return Extent(X=(left, right), Y=(bottom, top))
end

plotimg(img::Matrix) = image(rotr90(img), axis=(;aspect=DataAspect()))

function Makie.image!(ax::Axis, provider::MT.AbstractProvider, tile::Tile, crs)
    img = MT.fetchrastertile(provider, tile)
    bbox = extent(tile, crs)
    x = bbox.X[1]..bbox.X[2]
    y = bbox.Y[1]..bbox.Y[2]
    image!(ax, x, y, rotr90(img))
end

function Makie.image(provider::MT.AbstractProvider, tile::Tile, crs)
    fig = Figure()
    ax = Axis(fig[1,1], aspect=DataAspect())
    image!(ax, provider, tile, crs)
    return fig
end

function Makie.image(provider::MT.AbstractProvider, tilegrid::TileGrid, crs)
    bbox = extent(tilegrid, crs)
    fig = Figure()
    ax = Axis(fig[1,1], aspect=DataAspect())
    for tile in tilegrid
        image!(ax, provider, tile, crs)
    end
    xlims!(ax, bbox.X...)
    ylims!(ax, bbox.Y...)
    return fig
end



point_wgs = (-105.0, 40.0)
tile = Tile(point_wgs, 1, wgs84)
bbox = extent(tile, wgs84)
extent(tile, web_mercator)
point_web = project(point_wgs, wgs84, web_mercator)
project(point_web, web_mercator, wgs84)
TileGrid(tile)
TileGrid(bbox, 0, wgs84)
tilegrid = TileGrid(bbox, 3, wgs84)
extent(tilegrid, wgs84)
extent(tilegrid, web_mercator)

bbox = Extent(X = (-11.250, 16.853), Y = (40.984, 52.483))
tilegrid = TileGrid(bbox, 4, wgs84)
extent(tilegrid, web_mercator)

provider = MapTiles.OpenStreetMapProvider()

MT.geturl(provider::MT.AbstractProvider, tile::Tile) = MT.geturl(provider, tile.x, tile.y, tile.z)
MT.request(provider::MT.AbstractProvider, tile::Tile) = MT.request(provider, tile.x, tile.y, tile.z)
MT.fetchrastertile(provider::MT.AbstractProvider, tile::Tile) = MT.fetchrastertile(provider, tile.x, tile.y, tile.z)
img

img = MT.fetchrastertile(provider, tile)
bbox = extent(tile, web_mercator)

image(provider, tile, web_mercator)
image(provider, tile, wgs84)
image(provider, tilegrid, web_mercator)
image(provider, tilegrid, wgs84)

# provider = MT.CARTOProvider()
provider = MT.NASAGIBSProvider()
bbox = Extent(X = (-11.250, 16.853), Y = (40.984, 52.483))
tilegrid = TileGrid(bbox, 5, wgs84)
image(provider, tilegrid, web_mercator)
image(provider, tilegrid, wgs84)
