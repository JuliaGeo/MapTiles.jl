module MapTiles

import HTTP, ImageMagick, ProtoBuf
using Base: @kwdef # exist since julia 1.1, exported only since 1.9
using Extents
using GeoInterface: GeoInterface, extent
using GeoFormatTypes: GeoFormatTypes, CoordinateReferenceSystemFormat

import TileProviders as Providers

using TileProviders: geturl, AbstractProvider, Provider

export Tile, TileGrid, geturl

include("tiles.jl")

end
