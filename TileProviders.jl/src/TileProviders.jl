module TileProviders

using Dates, JSON3

export Provider

export geturl

include("provider.jl")
include("nasagibs.jl")

end
