module VectorTile

include("vector_tile_pb.jl")

# make the protobuf types easier to write
const Value = var"Tile.Value"
const GeomType = var"Tile.GeomType"
const Feature = var"Tile.Feature"
const Layer = var"Tile.Layer"

export Value, GeomType, Feature, Layer, Tile

end # module VectorTile