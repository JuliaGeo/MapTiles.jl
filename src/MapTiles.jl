module MapTiles

import HTTP, ImageMagick
using Base: @kwdef # exist since julia 1.1, exported only since 1.9
using Extents
using GeoInterface: GeoInterface, extent
using GeoFormatTypes: GeoFormatTypes, CoordinateReferenceSystemFormat
import TileProviders

using TileProviders: geturl, AbstractProvider, Provider

const Providers = TileProviders

export Tile, TileGrid, geturl, Providers

include("tiles.jl")

end
