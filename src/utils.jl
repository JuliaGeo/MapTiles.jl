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

"Convert from `lat,lon` to tile numbers"
function deg2num(lat,lon,z)
    latradian = deg2rad(lat); n = 2^z
    xtile = floor(Int, (lon + 180)/360*n)
    ytile = floor(Int, (1 - log(tan(latradian) + 1/cos(latradian))/pi)/2*n)
    xtile, ytile
end

function num2deg(x,y,z)
    n = 2^z
    londegree = x / n * 360 - 180
    latdegree = rad2deg(atan(sinh(pi * (1-2*y/n))))
    latdegree,londegree
end

# Tile numbers to lon./lat.
# import math
# def num2deg(xtile, ytile, zoom):
#   n = 2.0 ** zoom
#   lon_deg = xtile / n * 360.0 - 180.0
#   lat_rad = math.atan(math.sinh(math.pi * (1 - 2 * ytile / n)))
#   lat_deg = math.degrees(lat_rad)
#   return (lat_deg, lon_deg)

function tilebox(lat0, lon0, lat1, lon1, z)
    """Convert a box in geographical coordinates to a box in
    tile coordinates (integers), at a given zoom level.
    box_latlon is lat0, lon0, lat1, lon1.
    """
    x0, y0 = deg2num(lat0, lon0, z)
    x1, y1 = deg2num(lat1, lon1, z)
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
