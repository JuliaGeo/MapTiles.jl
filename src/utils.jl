"""
Determine the amount of meters per pixel

### Parameters
* `lat`: latitude in radians
* `z`: zoom level

Source: http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames#Resolution_and_Scale
"""
function resolution(lat, z)
    meter_per_pixel = 156543.03 # For zoom = 0 at equator
    meter_per_pixel * cos(lat) / (2^z)
end

"Convert from `lat,lon` to tile numbers (float64)"
function deg2num(lat,lon,z)
    latradian = deg2rad(lat); n = 2^z
    x = (lon + 180)/360*n
    y = (1 - log(tan(latradian) + 1/cos(latradian))/pi)/2*n
    x, y
end

"Convert from `lat,lon` to tile numbers, rounding them down to integers"
function ideg2num(lat,lon,z)
    x, y = deg2num(lat,lon,z)
    floor(Int, x), floor(Int, y)
end

function num2deg(x,y,z)
    n = 2^z
    londegree = x / n * 360 - 180
    latdegree = rad2deg(atan(sinh(pi * (1-2*y/n))))
    latdegree,londegree
end

# def get_tile_coords(lat, lon, z):
#     """Convert geographical coordinates to tile coordinates (integers),
#     at a given zoom level."""
#     return deg2num(lat, lon, z, do_round=False)

"Convert geographical coordinates to tile coordinates"
function deg2px(lat, lon, z, xmin, ymin, tilesizex, tilesizey)
    x, y = deg2num(lat, lon, z)
    floor(Int,(x-xmin)*tilesizex)+1, floor(Int,(y-ymin)*tilesizey)+1
end

deg2px(map::Map, lat, lon) = deg2px(
    lat, lon, map.zoom, map.xmin, map.ymin, map.tilesize[2], map.tilesize[1]
)

"""
Convert a box from geographical to tile coordinates (integers), at a given zoom.
"""
function tilebox(lat0, lon0, lat1, lon1, z)
    x0, y0 = ideg2num(lat0, lon0, z)
    x1, y1 = ideg2num(lat1, lon1, z)
    (x0, y0, x1, y1)
end

function correctbox(x0,y0,x1,y1,z)
    new_x0 = max(0, min(x0, x1))
    new_y0 = max(0, min(y0, y1))
    new_x1 = min(2^z - 1, max(x0, x1))
    new_y1 = min(2^z - 1, max(y0, y1))
    new_x0, new_y0, new_x1, new_y1
end

function boxsize(provider::AbstractProvider,x0,y0,x1,y1)
    sx = abs(x1 - x0) + 1
    sy = abs(y1 - y0) + 1
    if sx * sy >= provider.maxtiles
        error(usagewarning(provider))
    end
    sx,sy
end
