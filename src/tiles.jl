struct Tile
    x::Int
    y::Int
    zoom::Int
end

struct TileGrid3 <: AbstractMatrix{Tile}
    zoom::Int
    grid
end

function cartesian2tile(index::CartesianIndex, zoom::Int)
    return Tile(Tuple(index)..., zoom)
end

function cartesian2tile(index::Tuple, zoom::Int)
    return Tile(index..., zoom)
end


Base.size(grid::TileGrid3) = size(grid.grid)
function Base.getindex(grid::TileGrid3, idx...)
    ci = getindex(grid.grid, idx...)
    return cartesian2tile(ci, grid.zoom)
end


function Base.:(:)(mintile::Tile, maxtile::Tile)
    @assert mintile.zoom == maxtile.zoom
    minx = min(mintile.x, maxtile.x)
    maxx = max(mintile.x, maxtile.x)
    miny = min(mintile.y, maxtile.y)
    maxy = max(mintile.y, maxtile.y)
    grid = CartesianIndices((minx:maxx, miny:maxy))
    return TileGrid3(mintile.zoom, grid)
end

function Base.iterate(grid::TileGrid3)
    zoom = grid.zoom
    idx1, state1 = iterate(grid.grid)
    return cartesian2tile(idx1, zoom), state1
end

function Base.iterate(grid::TileGrid3, state)
    zoom = grid.zoom
    next_state = iterate(grid.grid, state)
    isnothing(next_state) && return nothing
    return cartesian2tile(next_state[1], zoom), next_state[2]
end

const EPSILON = 1e-14
const R2D = 180 / pi
const RE = 6378137.0
const CE = 2 * pi * RE
const EPSILON = 1e-14
const LL_EPSILON = 1e-11

"Get the tile containing a longitude and latitude"
function tile(lng, lat, zoom)
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

function fetchrastertile(provider::AbstractProvider, tile::Tile)
    return fetchrastertile(provider, tile.x, tile.y, tile.zoom)
end

"""
Fetch map tiles composing a box at a given zoom level, and
return the assembled image.
"""
function get_tiles(
        minlon::Real, minlat::Real, maxlon::Real, maxlat::Real, zoom::Integer=18;
        maxtiles::Int=16,
        provider::AbstractProvider=OpenStreetMapProvider(variant="standard")
    )
    min_tile = tile(minlon, minlat, zoom)
    max_tile = tile(maxlon, maxlat, zoom)
    return min_tile:max_tile
end


function bounds(tile::MapTiles.Tile)
    Z2 = 2^tile.zoom
    ul_lon_deg = tile.x / Z2 * 360.0 - 180.0
    ul_lat_rad = atan(sinh(pi * (1 - 2 * tile.y / Z2)))
    ul_lat_deg = rad2deg(ul_lat_rad)

    lr_lon_deg = (tile.x + 1) / Z2 * 360.0 - 180.0
    lr_lat_rad = atan(sinh(pi * (1 - 2 * (tile.y + 1) / Z2)))
    lr_lat_deg = rad2deg(lr_lat_rad)
    return Extent(X=(ul_lon_deg, lr_lon_deg), Y=(lr_lat_deg, ul_lat_deg))
end
