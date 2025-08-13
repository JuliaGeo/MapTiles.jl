module MapTiles

using GeoInterface: GeoInterface, Extent, extent
using GeoFormatTypes: EPSG, CoordinateReferenceSystemFormat
import Extents, GeoFormatTypes

export Tile, TileGrid, AbstractTile, AbstractTileGrid
export CustomTile, CustomTileGrid, TileGridSpec
export x, y, z, zoom, bounds, create_raster_tiles

include("abstract_types.jl")
include("tiles.jl")
include("custom_tiles.jl")

end
