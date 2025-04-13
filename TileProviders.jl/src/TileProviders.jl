module TileProviders

using Dates, JSON3

export AbstractProvider, Provider

export geturl

export Google, NASAGIBSTimeseries # Others are exported from @eval code

include("provider.jl")
include("nasagibs.jl")

end
