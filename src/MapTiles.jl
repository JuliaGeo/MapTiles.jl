module MapTiles

import HTTP, ImageMagick, ProtoBuf
using Base: @kwdef # exist since julia 1.1, exported only since 1.9
using Extents

include("providers.jl")
include("tiles.jl")
include("utils.jl")

end
