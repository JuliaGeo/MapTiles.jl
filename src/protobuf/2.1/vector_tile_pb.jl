# syntax: proto2
using ProtoBuf

export Tile_GeomType, Tile_Value, Tile_Feature, Tile_Layer, Tile

struct __enum_Tile_GeomType <: ProtoEnum
    UNKNOWN::Int32
    POINT::Int32
    LINESTRING::Int32
    POLYGON::Int32
    __enum_Tile_GeomType() = new(0,1,2,3)
end #struct __enum_Tile_GeomType
const Tile_GeomType = __enum_Tile_GeomType()

struct Tile_Value
    string_value::AbstractString
    float_value::Float32
    double_value::Float64
    int_value::Int64
    uint_value::UInt64
    sint_value::Int64
    bool_value::Bool
    Tile_Value(; kwargs...) = (o=new(); fillunset(o); isempty(kwargs) || ProtoBuf._protobuild(o, kwargs); o)
end #struct Tile_Value
const __wtype_Tile_Value = Dict(:sint_value => :sint64)
ProtoBuf.meta(t::Type{Tile_Value}) = ProtoBuf.meta(t, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, true, ProtoBuf.DEF_PACK, __wtype_Tile_Value, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
Base.hash(v::Tile_Value) = ProtoBuf.protohash(v)
Base.isequal(v1::Tile_Value, v2::Tile_Value) = ProtoBuf.protoisequal(v1, v2)
Base.==(v1::Tile_Value, v2::Tile_Value) = ProtoBuf.protoeq(v1, v2)

struct Tile_Feature
    id::UInt64
    tags::Array{UInt32,1}
    _type::Int32
    geometry::Array{UInt32,1}
    Tile_Feature(; kwargs...) = (o=new(); fillunset(o); isempty(kwargs) || ProtoBuf._protobuild(o, kwargs); o)
end #struct Tile_Feature
const __val_Tile_Feature = Dict(:id => 0, :_type => Tile_GeomType.UNKNOWN)
const __pack_Tile_Feature = Symbol[:tags,:geometry]
ProtoBuf.meta(t::Type{Tile_Feature}) = ProtoBuf.meta(t, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, __val_Tile_Feature, true, __pack_Tile_Feature, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
Base.hash(v::Tile_Feature) = ProtoBuf.protohash(v)
Base.isequal(v1::Tile_Feature, v2::Tile_Feature) = ProtoBuf.protoisequal(v1, v2)
Base.==(v1::Tile_Feature, v2::Tile_Feature) = ProtoBuf.protoeq(v1, v2)

struct Tile_Layer
    version::UInt32
    name::AbstractString
    features::Array{Tile_Feature,1}
    keys::Array{AbstractString,1}
    values::Array{Tile_Value,1}
    extent::UInt32
    Tile_Layer(; kwargs...) = (o=new(); fillunset(o); isempty(kwargs) || ProtoBuf._protobuild(o, kwargs); o)
end #struct Tile_Layer
const __req_Tile_Layer = Symbol[:version,:name]
const __val_Tile_Layer = Dict(:version => 1, :extent => 4096)
const __fnum_Tile_Layer = Int[15,1,2,3,4,5]
ProtoBuf.meta(t::Type{Tile_Layer}) = ProtoBuf.meta(t, __req_Tile_Layer, __fnum_Tile_Layer, __val_Tile_Layer, true, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
Base.hash(v::Tile_Layer) = ProtoBuf.protohash(v)
Base.isequal(v1::Tile_Layer, v2::Tile_Layer) = ProtoBuf.protoisequal(v1, v2)
Base.==(v1::Tile_Layer, v2::Tile_Layer) = ProtoBuf.protoeq(v1, v2)

struct Tile
    layers::Array{Tile_Layer,1}
    Tile(; kwargs...) = (o=new(); fillunset(o); isempty(kwargs) || ProtoBuf._protobuild(o, kwargs); o)
end #struct Tile
const __fnum_Tile = Int[3]
ProtoBuf.meta(t::Type{Tile}) = ProtoBuf.meta(t, ProtoBuf.DEF_REQ, __fnum_Tile, ProtoBuf.DEF_VAL, true, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
Base.hash(v::Tile) = ProtoBuf.protohash(v)
Base.isequal(v1::Tile, v2::Tile) = ProtoBuf.protoisequal(v1, v2)
Base.==(v1::Tile, v2::Tile) = ProtoBuf.protoeq(v1, v2)
