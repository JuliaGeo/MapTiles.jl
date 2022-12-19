# MapTiles

[![CI](https://github.com/yeesian/MapTiles.jl/workflows/CI/badge.svg)](https://github.com/yeesian/MapTiles.jl/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/yeesian/MapTiles.jl/badge.svg)](https://coveralls.io/r/yeesian/MapTiles.jl) 
[![codecov.io](http://codecov.io/github/yeesian/MapTiles.jl/coverage.svg?branch=master)](http://codecov.io/github/yeesian/MapTiles.jl?branch=master)

## Installation

[MapTiles.jl](https://github.com/yeesian/MapTiles.jl) is not currently a [Julia registered package](https://juliapackages.com/).

Currently only developer version is available. It can be installed using:

```bash
$ julia
julia> ]
(@v1.5) pkg> dev https://github.com/yeesian/MapTiles.jl
```

## Display map
### Display map from buildin mapsource providers
```julia
using MapTiles
using Plots
provider = MapTiles.OpenStreetMapProvider()
minlon, minlat, maxlon, maxlat = -0.4, 46.2, 1.0, 46.9
minlon, minlat, maxlon, maxlat = -11.250, 40.984, 16.853, 52.483
basemap  = MapTiles.fetchmap(minlon, minlat, maxlon, maxlat, provider=provider)
plot(basemap)
```

It's possible to list all existing map providers using `subtypes(MapTiles.AbstractProvider)`.

To get information about a specific map provider, you can use docstrings help using `?`. It should show possible variants, terms of services...

```
julia> ?
help?> MapTiles.OpenStreetMapProvider
```


### Display map from custom mapsource providers

A custom map source provider need to inherit abstract type `AbstractProvider` and implements `geturl` function for this custom map source.

Then, such a custom map provider can be used using:

```julia
using MapTiles
using MapTiles: AbstractProvider
import MapTiles: geturl
using Parameters
using Plots

Parameters.@with_kw struct CustomMapProvider <: AbstractProvider
    maxtiles::Int = typemax(Int)
end

function geturl(provider::CustomMapProvider, x::Integer, y::Integer, z::Integer)
    "https://domain.com/$z/$y/$x.png"
end

provider = CustomMapProvider()
minlon, minlat, maxlon, maxlat = -0.4, 46.2, 1.0, 46.9
basemap  = MapTiles.fetchmap(minlon, minlat, maxlon, maxlat, provider=provider)
plot(basemap)
```

## Other relevant Julia packages
- [Leaflet.jl: integrates with WebIO.jl to render leaflet maps for outputs like Blink.jl, Mux.jl, and for Jupyter notebooks](https://github.com/JuliaGeo/Leaflet.jl)

## Packages in other Languages
If you're coming from Python or R, you might be interested in the following packages instead:
- [Smopy: OpenStreetMap Image Tiles in Python](https://github.com/rossant/smopy)
- [Rio-tiler: Rasterio pluggin to serve tiles from AWS S3 hosted files](https://github.com/mapbox/rio-tiler)
- [ggmap: makes it easy to retrieve raster map tiles from popular online mapping services](https://github.com/dkahle/ggmap)
