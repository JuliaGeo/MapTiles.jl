"""
Determine the amount of meters per pixel

### Parameters
* `lat`: latitude in radians
* `z`: zoom level

Source: http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames#Resolution_and_Scale
"""
function resolution(lat::Real, z::Integer)
    meter_per_pixel = 156543.03 # For zoom = 0 at equator
    meter_per_pixel * cos(lat) / (2^z)
end

"Convert from `lat,lon` to tile numbers (float64)"
function lonlat2tile(lon::Real, lat::Real, z::Integer)
    latradian = deg2rad(lat); n = 2^z
    x = (lon + 180)/360*n
    y = (1 - log(tan(latradian) + 1/cos(latradian))/pi)/2*n
    x, y
end

"Convert from `lat,lon` to tile numbers, rounding them down to integers"
function ilonlat2tile(lon::Real, lat::Real, z::Integer)
    x, y = lonlat2tile(lon, lat, z)
    floor(Int, x), floor(Int, y)
end

"Convert geographical coordinates to tile coordinates"
function lonlat2tile(
        lon::Real, lat::Real, z::Integer, xmin::Real, ymin::Real,
        tilesizex::Integer, tilesizey::Integer
    )
    x, y = lonlat2tile(lon, lat, z)
    floor(Int,(x-xmin)*tilesizex)+1, floor(Int,(y-ymin)*tilesizey)+1
end

lonlat2tile(basemap::BaseMap, lon::Real, lat::Real) = lonlat2tile(
    lon, lat, basemap.zoom, basemap.xmin, basemap.ymin,
    basemap.tilesize[2], basemap.tilesize[1]
)

"""
Convert a box from geographical to tile coordinates (integers), at a given zoom.
"""

function tilebox(minlon::Real, minlat::Real, maxlon::Real, maxlat::Real, z::Integer)
    xmin, ymin = ilonlat2tile(minlon, minlat, z)
    xmax, ymax = ilonlat2tile(maxlon, maxlat, z)
    xmin, ymin, xmax, ymax
end

function correctbox(xmin::Integer, ymin::Integer, xmax::Integer, ymax::Integer, z::Integer)
    new_xmin = max(0, min(xmin, xmax))
    new_ymin = max(0, min(ymin, ymax))
    new_xmax = min(2^z - 1, max(xmin, xmax))
    new_ymax = min(2^z - 1, max(ymin, ymax))
    new_xmin, new_ymin, new_xmax, new_ymax
end

function boxsize(provider::AbstractProvider, xmin, ymin, xmax, ymax)
    abs(xmax - xmin) + 1, abs(ymax - ymin) + 1
end
