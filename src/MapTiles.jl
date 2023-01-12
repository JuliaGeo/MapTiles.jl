module MapTiles

import HTTP, ImageMagick, ProtoBuf
using Base: @kwdef # exist since julia 1.1, exported only since 1.9
using Extents
using GeoInterface: GeoInterface, extent
import GeoFormatTypes

export Tile, TileGrid

include("tiles.jl")
include("providers.jl")

end
