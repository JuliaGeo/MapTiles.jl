module TileProviders

using Dates, JSON3

export AbstractProvider, Provider

export geturl

include("provider.jl")
include("nasagibs.jl")

end
