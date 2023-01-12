module TileProviders

using Dates, JSON3

export Provider

export CARTO, Esri, Google, Jawg, MapBox, OSM, OSMDE, OSMFrance, OSMHumanitarian,
       OpenWeatherMap, OpenTopoMap, Stamen, Thunderforest

export interpolate_url

include("provider.jl")
include("nasagibs.jl")

end
