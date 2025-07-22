module MapTiles

using GeoInterface: GeoInterface, Extent, extent
using GeoFormatTypes: EPSG, CoordinateReferenceSystemFormat
import Extents, GeoFormatTypes

export Tile, TileGrid, AbstractTile, AbstractTileGrid
export x, y, z, zoom, bounds

include("abstract_types.jl")
include("tiles.jl")

end
