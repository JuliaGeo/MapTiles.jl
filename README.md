# MapTiles

[![CI](https://github.com/JuliaGeo/MapTiles.jl/workflows/CI/badge.svg)](https://github.com/JuliaGeo/MapTiles.jl/actions?query=workflow%3ACI)
[![codecov.io](http://codecov.io/github/JuliaGeo/MapTiles.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaGeo/MapTiles.jl?branch=master)

MapTiles is a [Julia](https://julialang.org/) package for working with
[tiled web maps](https://en.wikipedia.org/wiki/Tiled_web_map), also known as slippy maps.
It mainly concerns itself with getting a set of tile indices based on a given area of
interest and zoom level, specified in WGS84 longitude/latitude or Web Mercator.
It does not download any tile images, but can be used together with
[TileProviders.jl](https://github.com/JuliaGeo/TileProviders.jl) to create URIs for tiles,
which can then be downloaded and plotted. [Tyler.jl](https://github.com/MakieOrg/Tyler.jl)
is a [Makie](http://makie.org/) package that uses MapTiles and TileProviders to plot
interactive web maps, for instance as a background layer to plot geospatial data on top of.

## Installation

[MapTiles.jl](https://github.com/JuliaGeo/MapTiles.jl) is not currently a [Julia registered package](https://juliapackages.com/).

Currently only developer version is available. It can be installed using:

```bash
$ julia
julia> ]
(@v1.8) pkg> add https://github.com/JuliaGeo/MapTiles.jl
```

## Usage

```julia
using MapTiles, TileProviders
import HTTP, ImageMagick
using GeoInterface: Extent, extent

# get a single Tile with x, y and z index from a point and zoom level
point_wgs = (-105.0, 40.0)
tile = Tile(point_wgs, 8, MapTiles.wgs84)
# -> Tile(53, 96, 8)

# get the extent of a Tile in Web Mercator coordinates
bbox = extent(tile, MapTiles.web_mercator)
# -> Extent(X = (-1.1740727e7, -1.1584184e7), Y = (4.8528340e6, 5.0093770e6))

# get a TileGrid from an Extent and zoom level
bbox = Extent(X = (-1.23, 5.65), Y = (-5.68, 4.77))
tilegrid = TileGrid(bbox, 8, MapTiles.wgs84)
# -> TileGrid(CartesianIndices((127:132, 124:132)), 8)

# load the zoom 0 OpenStreetMap tile into an image
provider = OpenStreetMap()
tile = Tile(0, 0, 0)
url = geturl(provider, tile.x, tile.y, tile.z)
result = HTTP.get(url)
img = ImageMagick.readblob(result.body)
# -> 256×256 Array{RGB{N0f8},2}
```

![Tile(0, 0, 0) of OpenStreetMap](https://user-images.githubusercontent.com/4471859/213268199-bacda46b-8b16-4695-befb-25ae10898693.png)

## Packages in other Languages
If you're coming from Python or R, you might be interested in the following packages instead:
- [mercantile: Spherical mercator tile and coordinate utilities](https://github.com/mapbox/mercantile)
  - The design of this package is largely based on mercantile.
- [Smopy: OpenStreetMap Image Tiles in Python](https://github.com/rossant/smopy)
- [Rio-tiler: Rasterio pluggin to serve tiles from AWS S3 hosted files](https://github.com/mapbox/rio-tiler)
- [ggmap: makes it easy to retrieve raster map tiles from popular online mapping services](https://github.com/dkahle/ggmap)
