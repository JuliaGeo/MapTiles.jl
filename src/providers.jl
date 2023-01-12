"""
A Raster Tileset Provider typically follows the following conventions:
    * Tiles are 256 × 256 pixel PNG files
    * Each zoom level is a directory, each column is a subdirectory, and
        each tile in that column is a file
    * Filename(url) format is `/zoom/x/y.png`

The slippy map expects tiles to be served up at URLs following this scheme, so
all tile server URLs look pretty similar. (We currently only assume support for
raster tiles.)

Tiles are not always in these dimensions; for example there could be 64×64 pixel
images for mobile use, however 256×256 pixel images are a de facto standard.
515×512 pixel seems to be the usual size of high-resolution tiles.

Please obey the usage restrictions of each tile server if you use it heavily!

# Interface
In this interface, an AbstractProvider must implement the following method:
```
geturl(provider::AbstractProvider,x,y,z)
```
which returns a string representing the url to poll for tiles by that provider.

In addition, the AbstractProvider should contain the following attributes
    * `maxtiles`: maximum number of tiles to fetch, before issuing an error.

The AbstractProvider can override the default error message (when the max.
number of tiles is exceeded) by providing an implementation for
```
usagewarning(provider::AbstractProvider)
```

# Methods
`MapTiles.fetchtile(provider::AbstractProvider,x,y,z)` will return a
matrix of values corresponding to the raster tile at `/z/x/y.png`

# References
For more details see
* http://mapschool.io/
* http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
* http://wiki.openstreetmap.org/wiki/Tiles
* http://leaflet-extras.github.io/leaflet-providers/preview/
"""
abstract type AbstractProvider end

usagewarning(provider::AbstractProvider) =
    string("You are requesting a very large map, please consider ",
           "setting up your own tile server instead. For details, ",
           "please see https://switch2osm.org/serving-tiles/.")

function geturl(provider::AbstractProvider, tile::Tile)
    geturl(provider, tile.x, tile.y, tile.z)
end

function request(
        provider::AbstractProvider,
        tile::Tile,
    )
    url = geturl(provider,tile)
    result = HTTP.get(url)
    result.body
end

function fetchrastertile(
        provider::AbstractProvider,
        tile::Tile,
    )
    data = request(provider, tile)
    ImageMagick.readblob(data)
end

function fetchvectortile(
        provider::AbstractProvider,
        tile::Tile
    )
    data = request(provider, tile)
    ProtoBuf.readproto(IOBuffer(data), MapTiles.vector_tile.Tile())
end

"""
```
struct GBIFProvider <: AbstractProvider
    maxtiles::Int = typemax(Int)
    epsg::Int = 3857
    tileset::String = "omt"
    format::String = "pbf"
end
```

GBIF hosts map tiles in four projections, for use on GBIF.org and by users of
our API. We serve vector tiles based on the OpenMapTiles.org schema, and from
these generate raster tiles in several styles. Both the vector and raster tiles
are available for public use.

## Data schema and sources

The Web Mercator tiles are simply those from OpenMapTiles.org, see the
OpenMapTiles schema for details. The other projections have been generated to
fit the same layer schema, but with fewer layers — see https://tile.gbif.org/ui/
for details.

* Web Mercator tiles are from 2017-07-03.
* The other projections use OpenStreetMap and Natural Earth data. We do not plan
    to make frequent updates to the tiles, since the geological features of most
    interest to us do not often change.
* WGS84 tiles are from OpenStreetMap as of 2017-08-28, and Natural Earth version
    2.0.0.
* Polar tiles are from OpenStreetMap as of 2017-02-27, and Natural Earth version
    2.0.0. (They will soon be processed to add extra layers.)

## Vector Tiles

The schema for the vector tile layers follows the OpenMapTiles schema, but with
fewer layers included for the non-Mercator projections. In addition, the Arctic
LAEA projection includes a graticule layer, containing a polygon for the
Northern Hemisphere and lines for 60°N and the Arctic Circle.

## Format

* `format`: Either `.pbf` for a vector tile, or `@1x.png`, ..., `@4x.png` for
    PNG tiles at various pixel densities. Use higher pixel densities for high
    resolution screens, otherwise the tiles will appear fuzzy.
* `params`: Only for PNG tiles, specify a style e.g. `?style=gbif-classic`

## Feedback and issues

The process used by GBIF to generate the tiles in the three other projections
is on GitHub. Please log issues there, or use the GBIF API Users mailing list.

## Credits and copyright

* OpenStreetMap and Natural Earth for the map data,
* OpenMapTiles for the cartography and processing to produce vector tiles,
* OpenLayers for good support of non-Mercator projections.
* Base map tiles are © OpenMapTiles © OpenStreetMap contributors, and use
    Natural Earth data.

## References
https://tile.gbif.org/
https://www.gbif.org/developer/maps
"""
@kwdef struct GBIFProvider <: AbstractProvider
    maxtiles::Int = typemax(Int)
    epsg::Int = 3857
    tileset::String = "omt"
    format::String = "pbf"
end
geturl(p::GBIFProvider, x::Integer, y::Integer, z::Integer) =
    "https://tile.gbif.org/$(p.epsg)/$(p.tileset)/$z/$x/$y.$(p.format)"

"""
```
struct OpenStreetMapProvider <: AbstractProvider
    variant::String = "standard"
    maxtiles::Int = 16
end
```
## Possible variants
    * `"standard"` (default)
    * `"blackwhite"`
    * `"deutschland"`
    * `"nolabels"`
    * `"france"`
    * `"humanitarian"`

## Where does the map data come from
OpenStreetMap is open data, created by OpenStreetMap contributors,
and available under the Open Data Commons Open Database License (ODbL).

## How do I fix an error on the map
https://www.openstreetmap.org/fixthemap

## Remarks
Apart from very limited testing purposes, you should not use the tiles supplied
by OpenStreetMap.org itself. OpenStreetMap is a volunteer-run non-profit body
and cannot supply tiles for large-scale commercial use. Rather, you should use
a third party provider that makes tiles from OSM data, or generate your own.

## References
See
    * https://switch2osm.org/using-tiles/
    * http://wiki.openstreetmap.org/wiki/Tile_servers
for details.
"""
@kwdef struct OpenStreetMapProvider <: AbstractProvider
    variant::String = "standard"
    maxtiles::Int = 16
end

function geturl(provider::OpenStreetMapProvider, x::Integer, y::Integer, z::Integer)
    if provider.variant == "standard"
        "http://tile.openstreetmap.org/$z/$x/$y.png"
    elseif provider.variant == "blackwhite"
        "http://tiles.wmflabs.org/bw-mapnik/$z/$x/$y.png"
    elseif provider.variant == "nolabels"
        "https://tiles.wmflabs.org/osm-no-labels/$z/$x/$y.png"
    elseif provider.variant == "deutschland"
        "http://tile.openstreetmap.de/tiles/osmde/$z/$x/$y.png"
    elseif provider.variant == "france"
        "http://tile.openstreetmap.fr/osmfr/$z/$x/$y.png"
    elseif provider.variant == "humanitarian"
        "http://tile.openstreetmap.fr/hot/$z/$x/$y.png"
    else
        warn("Unknown provider: $(provider.variant), defaulting to standard")
        "http://tile.openstreetmap.org/$z/$x/$y.png"
    end
end
usagewarning(provider::OpenStreetMapProvider) =
    string("You are requesting a very large map, please see ",
           "OpenStreetMap tile usage policy ",
           "(https://operations.osmfoundation.org/policies/tiles/).")

"""
```
struct WikimediaMapsProvider <: AbstractProvider
    maxtiles::Int = typemax(Int)
end
```

## Terms of Use
Static images of maps can be used under a Creative Commons Attribution-ShareAlike
4.0 license, with attribution to https://wikimediafoundation.org/w/index.php?title=Maps_Terms_of_Use.

## Disclaimers
While we aim to provide a useful service for the Wikimedia community and beyond,
no software is perfect.

Wikimedia Maps service may undergo future development, so all your use is at
your sole risk. We provide Wikimedia Maps on an “as is” and “as available”
basis, and we expressly disclaim all warranties of all kinds, including implied
warranties of fitness for a particular purpose, merchantability, and
non-infringement. We make no warranty that Wikimedia Maps will meet your
requirements, be safe, secure, or uninterrupted.

## Where does the map data come from
The maps shown on Wikipedia, Wikivoyage and other Wikimedia projects use data
from OpenStreetMap. OpenStreetMap is open data, created by OpenStreetMap contributors,
and available under the Open Data Commons Open Database License (ODbL).

The map designs are based on the style OSM Bright for Mapbox Studio, available
under a Creative Commons Attribution 3.0 license.

## How do I fix an error on the map
https://www.openstreetmap.org/fixthemap

## References
See https://www.mediawiki.org/wiki/Maps for details.
"""
@kwdef struct WikimediaMapsProvider <: AbstractProvider
    maxtiles::Int = typemax(Int)
end
geturl(provider::WikimediaMapsProvider, x::Integer, y::Integer, z::Integer) =
    "https://maps.wikimedia.org/osm-intl/$z/$x/$y.png"

"""
```
struct OpenCycleMapProvider <: AbstractProvider
    variant::String = "cycle"
    maxtiles::Int = typemax(Int)
end
```

The OpenCycleMap global cycling map is based on data from the OpenStreetMap
project. At low zoom levels it is intended for overviews of national cycling
networks; at higher zoom levels it should help with planning which streets to
cycle on, where you can park your bike and so on.

The map is updated every few days with the latest data from OpenStreetMap. News
about OpenCycleMap can be found in the OpenStreetMap archives on my blog.

## Possible variants
    * `cycle`
    * `transport`

## Credits
* Height Data is from NASA’s SRTM and is available in the public domain.
* Terrain Imagery is provided by True Marble by Unearthed Outdoors, LLC and is
    licensed under a Creative Commons Attribution 3.0 United States License.
* All other map data, including all cycling-related data, is from
    OpenStreetMap.org contributors and is licensed under the Open Data Commons
    Open Database License (ODbL).
* The map tiles are available for re-use under the Creative Commons Attribution
    Share-Alike 2.0 License. For full details see the full terms and conditions
    at http://thunderforest.com/terms/.

## References
See https://www.opencyclemap.org/docs/ for further details.
"""
@kwdef struct OpenCycleMapProvider <: AbstractProvider
    variant::String = "cycle"
    maxtiles::Int = typemax(Int)
end
function geturl(provider::OpenCycleMapProvider, x::Integer, y::Integer, z::Integer)
    if provider.variant == "cycle"
        "http://tile.opencyclemap.org/cycle/$z/$x/$y.png"
    elseif provider.variant == "transport"
        "http://tile2.opencyclemap.org/transport/$z/$x/$y.png"
    else
        warn("Unknown provider: $(provider.variant), defaulting to cycle")
        "http://tile.opencyclemap.org/cycle/$z/$x/$y.png"
    end
end

"""
OpenSeaMap was created in 2009 in response to a great need for freely-accessible
seafaring maps. OpenSeaMap's goal is to add nautical and tourism information
that would interest sailors OSM, and to present it in a pleasing way. This
includes beacons, buoys and other seamarks, port information, repair shops, ship
supplies and much more, but also shops, restaurants and places of interest.
OpenSeaMap is part of OpenStreetMap and uses its database.

The basemap is rendered using the OpenStreetMap-data. This map is extended with
nautical data that is saved in the OSM-Database as well.

Visit http://openseamap.org/index.php and http://wiki.openseamap.org/wiki/Main_Page
for details.
"""
@kwdef struct OpenSeaMapProvider <: AbstractProvider
    maxtiles::Int = typemax(Int)
end
geturl(provider::OpenSeaMapProvider, x::Integer, y::Integer, z::Integer) =
    "http://tiles.openseamap.org/seamark/$z/$x/$y.png"


"""
```
struct OpenTopoMapProvider <: AbstractProvider
    maxtiles::Int = typemax(Int)
end
```

OpenTopoMap is a project aiming at rendering topographic maps from OSM and SRTM
data. The map style should look familiar to Germans.

## Terms of Use
Please make sure to stick to the licence CC-BY-SA and always name opentopomap.org.
If you plan to use the tiles for bigger projects, please contact either

* http://www.openstreetmap.org/user/derstefan, or
* http://www.openstreetmap.org/user/mogstar

for more information.

## References
Visit http://wiki.openstreetmap.org/wiki/OpenTopoMap for further details.
"""
@kwdef struct OpenTopoMapProvider <: AbstractProvider
    maxtiles::Int = typemax(Int)
end
geturl(provider::OpenTopoMapProvider, x::Integer, y::Integer, z::Integer) =
    "http://tile.opentopomap.org/$z/$x/$y.png"

"""
```
struct OpenWeatherMapProvider <: AbstractProvider
    apikey::String
    variant::String = "clouds"
    maxtiles::Int = typemax(Int)
end
```

OpenWeatherMap is an online service that provides weather data, including
current weather data, forecasts, and historical data to the developers of web
services and mobile applications. For data sources, it utilizes meteorological
broadcast services, raw data from airport weather stations, raw data from radar
stations, and raw data from other official weather stations. All data is processed
by OpenWeatherMap in a way that it attempts to provide accurate online weather
forecast data and weather maps, such as those for clouds or precipitation.

## Possible variants
    * `clouds` (default)
    * `clouds_cls`
    * `precipitation`
    * `precipitation_cls`
    * `rain`
    * `rain_cls`
    * `pressure`
    * `pressure_cntr`
    * `wind`
    * `temp`
    * `snow`

## Terms of Use
All data that OpenWeatherMap provides is used under the terms of a Creative
Commons Attribution-ShareAlike license. However, any access beyond 60 requests
of basic data per minute, as well as bulk downloading of weather readings and
forecasts, require a paid subscription.

## References
For further details, visit https://openweathermap.org/.
"""
@kwdef struct OpenWeatherMapProvider <: AbstractProvider
    apikey::String
    variant::String = "clouds"
    maxtiles::Int = typemax(Int)
end
geturl(provider::OpenWeatherMapProvider, x::Integer, y::Integer, z::Integer) =
    "http://tile.openweathermap.org/map/$(provider.variant)/$z/$x/$y.png?appid=$(provider.apikey)"

"""
```
struct ThunderForestProvider <: AbstractProvider
    variant::String = "cycle"
    apikey::String
    maxtiles::Int = typemax(Int)
end
```
The Thunderforest Platform is the 4th major revision of the systems that powers
OpenCycleMap. With mapnik and postgis at its core, supported with mod_tile,
squid, and a host of other components, it provides robust, fast, reliable and
wonderful-looking maps.

## Possible variants
    * `"cycle"` (default)
    * `"transport"`
    * `"transport-dark"`
    * `"spinal-map"`
    * `"landscape"`
    * `"outdoors"`
    * `"pioneer"`
    * `"mobile-atlas"`
    * `"neighbourhood"`

## Attribution
Attribution must be given to both “Thunderforest” and “OpenStreetMap contributors”.
Users of your site/application must have a working links to www.thunderforest.com
and www.openstreetmap.org/copyright, for example:

    Maps © Thunderforest, Data © OpenStreetMap contributors

For media that doesn’t support links, such as posters, books and other printed
media, then you can provide attribution as follows:

    Maps © www.thunderforest.com, Data © www.osm.org/copyright

## References
For further details, visit https://www.thunderforest.com/docs/map-tiles-api/ and
https://www.thunderforest.com/terms/.
"""
@kwdef struct ThunderForestProvider <: AbstractProvider
    variant::String = "cycle"
    apikey::String
    maxtiles::Int = typemax(Int)
end
geturl(provider::ThunderForestProvider, x::Integer, y::Integer, z::Integer) =
    "http://tile.thunderforest.com/$(provider.variant)/$z/$x/$y.png?apikey=$(provider.apikey)"

"""
```
struct OpenMapSurferProvider <: AbstractProvider
    variant::String = "roads"
    maxtiles::Int = typemax(Int)
end
```
OpenMapSurfer (http://korona.geog.uni-heidelberg.de/) - is a web map service
with a couple of maps rendered with MapSurfer.NET. This web map service is
developed by Maxim Rylov User:Runge and hosted by the GIScience (Geoinformatics)
Research Group, Heidelberg University.

## Possible variants
    * `"roads"` (default)
    * `"adminb"`
    * `"roadsg"`

## Terms of Use
Tiles that were rendered by this service can be used freely and without charge
by any individuals through the website http://korona.geog.uni-heidelberg.de

If you intend to use tiles from OpenMapSurfer services in your own applications
please contact them.

Commercial usage of the services provided by OpenMapSurfer does need approval!

OpenStreetMap data is available under the Open Database License.

Relief shading derived from CIAT-CSI SRTM (zoom levels 0-7): Users are
prohibited from any commercial, non-free resale, or redistribution without
explicit written permission from CIAT.

Original data by Jarvis A., H.I. Reuter, A. Nelson, E. Guevara, 2008, Hole-filled
seamless SRTM data V4, International Centre for Tropical Agriculture (CIAT),
available from http://srtm.csi.cgiar.org.

Relief shading derived from ASTER GDEM (zoom levels 8-18): ASTER GDEM is a
product of METI and NASA'.

Relief shading derived from ETOPO1 (zoom levels 0-4). Amante, C. and B. W. Eakins,
ETOPO1 1 Arc-Minute Global Relief Model: Procedures, Data Sources and Analysis.
NOAA Technical Memorandum NESDIS NGDC-24, 19 pp, March 2009.

## License
Content is available under Creative Commons Attribution-ShareAlike 2.0 license.

## References
For further details, visit http://wiki.openstreetmap.org/wiki/OpenMapSurfer.
"""
@kwdef struct OpenMapSurferProvider <: AbstractProvider
    variant::String = "roads"
    maxtiles::Int = typemax(Int)
end
geturl(provider::OpenMapSurferProvider, x::Integer, y::Integer, z::Integer) =
    "http://korona.geog.uni-heidelberg.de/tiles/$(provider.variant)/x=$x&y=$y&z=$z"

"""
Hydda is a OpenStreetMap style, created for Swedish use, but usable in the rest
of the world too.

## Possible variants
    * `"full"` (default)
    * `"base"`
    * `"roads_and_labels"`

## Attribution
I don't know, maybe a reference to http://hydda.se or
https://github.com/karlwettin/tilemill-style-hydda?

I have to ask https://github.com/joakimfors and https://github.com/kodapan what they think.

Please visit http://openstreetmap.se/tjanster and
https://github.com/osmlab/editor-layer-index/issues/347 for further details.
"""
@kwdef struct HyddaProvider <: AbstractProvider
    variant::String = "full"
    maxtiles::Int = typemax(Int)
end
geturl(provider::HyddaProvider, x::Integer, y::Integer, z::Integer) =
    "http://tile.openstreetmap.se/hydda/$(provider.variant)/$z/$x/$y.png"

"""
```
struct MapBoxProvider <: AbstractProvider
    accesstoken::String
    id::String = "streets"
    maxtiles::Int = typemax(Int)
end
```
The Mapbox Maps API supports reading raster tilesets, vector tilesets, and
Mapbox Editor project features. Tilesets can be retrieved as images, TileJSON,
or HTML slippy maps for embedding. Mapbox Editor project features can be
retrieved as GeoJSON or KML.

## Map IDs
The following map IDs are accessible to all accounts using a valid access token:

    * `streets` (default)
    * `light`
    * `dark`
    * `satellite`
    * `streets-satellite`
    * `wheatpaste`
    * `streets-basic`
    * `comic`
    * `outdoors`
    * `run-bike-hike`
    * `pencil`
    * `pirates`
    * `emerald`
    * `high-contrast`

## Access Token
Access to Mapbox web services? requires an access token that connects API
requests to your account. The requests in this package don't include an access
token: you will need to supply one by specifying the token.

## References
For further details, visit https://www.mapbox.com/api-documentation/.
"""
@kwdef struct MapBoxProvider <: AbstractProvider
    accesstoken::String
    id::String = "streets"
    maxtiles::Int = typemax(Int)
end
geturl(provider::MapBoxProvider, x::Integer, y::Integer, z::Integer) =
    "https://api.tiles.mapbox.com/v4/mapbox.$(provider.id)/$z/$x/$y.png?access_token=$(provider.accesstoken)"

"""
```
StamenProvider <: AbstractProvider
    variant::String = "toner"
    maxtiles::Int = typemax(Int)
end
```

Stamen (stamen.com) is a San Francisco design and development studio focused on
data visualization and map-making. Stamen heavily uses OpenStreetMap data in
many of their map visualizations and it has provided three CC-BY OpenStreetMap
tilesets: Toner, Terrain, and Watercolor.

## Possible variants
    * `toner` (default)
    * `toner-background`
    * `toner-hybrid`
    * `toner-labels`
    * `toner-lite`
    * `watercolor`
    * `terrain`
    * `terrain-background`

## License
Except otherwise noted, each of these map tile sets are © Stamen Design, under a
Creative Commons Attribution (CC BY 3.0) license.

## Attribution
* For Toner and Terrain: Map tiles by Stamen Design, under CC BY 3.0.
    Data by OpenStreetMap, under ODbL.

* For Watercolor: Map tiles by Stamen Design, under CC BY 3.0.
    Data by OpenStreetMap, under CC BY SA.

* If you roll your own tiles from another source you will still need to credit
    “Map data by OpenStreetMap, under ODbL.”

## References
For further details, visit http://maps.stamen.com/.
"""
@kwdef struct StamenProvider <: AbstractProvider
    variant::String = "toner"
    maxtiles::Int = typemax(Int)
end
geturl(provider::StamenProvider, x::Integer, y::Integer, z::Integer) =
    "http://tile.stamen.com/$(provider.variant)/$z/$x/$y.png"

"""
```
struct CARTOProvider <: AbstractProvider
    variant::String = "light_all"
    maxtiles::Int = typemax(Int)
end
```

## Possible variants
    * `light_all` (default)
    * `light_nolabels
    * `light_only_labels`
    * `dark_all`
    * `dark_nolabels`
    * `dark_only_labels`

## Remarks
For raster basemaps you can make use of them directly without an API KEY. For
vector basemaps you will need to get an API Key from Mapzen to start using them.
Remember that to use the basemaps you need to ensure you provide proper credit
and that in some cases you will need a commercial API KEY to use them.

## Terms of Service
Are based on https://carto.com/legal/, and detailed here:
https://drive.google.com/file/d/0B3OBExqwT6KJNHp3U3VUamx6U1U/view.

## References
For further details, visit https://carto.com/location-data-services/basemaps/ and
https://carto.com/docs/faqs/basemaps/.
"""
@kwdef struct CARTOProvider <: AbstractProvider
    variant::String = "light_all"
    maxtiles::Int = typemax(Int)
end
geturl(provider::CARTOProvider, x::Integer, y::Integer, z::Integer) =
    "http://basemaps.cartocdn.com/$(provider.variant)/$z/$x/$y.png"

"""
```
GoogleMapsProvider <: AbstractProvider
    variant::String = ""
    maxtiles::Int = typemax(Int)
end
```

The Google Static Maps API lets you embed a Google Maps image on your web page
without requiring JavaScript or any dynamic page loading. The Google Static Maps
API service creates your map based on URL parameters sent through a standard
HTTP request and returns the map as an image you can display on your web page.

## Possible Variants
    * `roadmap` (default)
    * `terrain`
    * `satellite`
    * `hybrid`

For more details, visit https://developers.google.com/maps/documentation/static-maps/intro#MapTypes.

## Terms of Service
Please abide by the terms in https://developers.google.com/maps/terms?hl=en#section_10_5

## References
For further details, visit https://developers.google.com/maps/documentation/static-maps/
"""
@kwdef struct GoogleMapsProvider <: AbstractProvider
    variant::String = ""
    maxtiles::Int = typemax(Int)
end
function geturl(provider::GoogleMapsProvider, x::Integer, y::Integer, z::Integer)
    layer = if provider.variant == ""
        ""
    elseif provider.variant == "roads-only"
        "lyrs=h"
    elseif provider.variant == "roadmap"
        "lyrs=m"
    elseif provider.variant == "terrain"
        "lyrs=p"
    elseif provider.variant == "altered-roadmap"
        "lyrs=r"
    elseif provider.variant == "satellite"
        "lyrs=s"
    elseif provider.variant == "terrain-only"
        "lyrs=t"
    elseif provider.variant == "hybrid"
        "lyrs=y"
    else
        warn("unknown map type: $(provider.variant), defaulting to standard")
        ""
    end
    "http://mt1.google.com/vt/$layer&x=$x&y=$y&z=$z"
end

"""
```
struct NASAGIBSProvider <: AbstractProvider
    variant::String = "MODIS_Terra_CorrectedReflectance_TrueColor"
    maxtiles::Int = typemax(Int)
end
```

The Global Imagery Browse Services (GIBS) are designed to deliver global,
full-resolution satellite imagery to users in a highly responsive manner,
enabling interactive exploration of the Earth.

## Imagery Layers & Endpoints
GIBS imagery layers are named and made available through a set of defined
endpoints based on the following characteristics:

* **Projection & Resolution**: Imagery layers are available in one or more
    projected coordinate systems (e.g. EPSG:4326 - "Geographic Lat/Lon") at a
    specific resolution (e.g. 2km/pixel)
* **Near Real-Time vs Standard Latency**: Imagery layers are available in a near
    real-time (e.g. within 3 hours of observation) or standard (e.g. within X
    days of observation) latency.
* **Data Version**: Imagery layers may be available for more than one version
    (e.g. MODIS v5 and v6) of the same science parameter.

## Populating the fields

https://gibs.earthdata.nasa.gov/wmts/epsg{EPSG:Code}/best/{ProductName}/default/{Time}/{TileMatrixSet}/{ZoomLevel}/{TileRow}/{TileCol}.png

with the desired projection, product, time, etc (Terra/MODIS Aerosol Optical
depth from 2014/04/09, in this case), GIBS products can be used by clients such
as ESRI's ArcGIS Online to add a "Tile Layer" by leaving the row, column, and
zoom level as parameters:

https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/MODIS_Terra_Aerosol/default/2014-04-09/GoogleMapsCompatible_Level6/{level}/{row}/{col}.png

The time parameter supports a single day (YYYY-MM-DD) or repeating interval
(Rx/YYYY-MM-DD/PyYmMdD), as specified by the ISO 8601 specification, where:

    * x - number of repetitions (day frames)
    * YYYY - Year
    * MM - Month
    * DD - Day
    * y - Period years
    * m - period months
    * d - period days

## Possible variants
    * `MODIS_Terra_CorrectedReflectance_TrueColor` (default)
    * `VIIRS_CityLights_2012`
    * `MODIS_Terra_Land_Surface_Temp_Day`
    * `MODIS_Terra_Snow_Cover`
    * `MODIS_Terra_Aerosol`
    * `MODIS_Terra_Chlorophyll_A`

## References
Please visit https://wiki.earthdata.nasa.gov/display/GIBS/GIBS+API+for+Developers
for further details.
"""
@kwdef struct NASAGIBSProvider <: AbstractProvider
    variant::String = "MODIS_Terra_CorrectedReflectance_TrueColor"
    time::String = ""
    tilematrixset::String = "GoogleMapsCompatible_Level"
    maxtiles::Int = 150_000
end
function geturl(provider::NASAGIBSProvider, x::Integer, y::Integer, z::Integer)
    ext = if provider.variant in ("MODIS_Terra_Land_Surface_Temp_Day", "MODIS_Terra_Snow_Cover", "MODIS_Terra_Aerosol", "MODIS_Terra_Chlorophyll_A")
        "png"
    else
        "jpg"
    end
    maxzoom = if provider.variant == "MODIS_Terra_Aerosol"
        6
    elseif provider.variant in ("MODIS_Terra_Chlorophyll_A", "MODIS_Terra_Land_Surface_Temp_Day")
        7
    elseif provider.variant in ("VIIRS_CityLights_2012", "MODIS_Terra_Snow_Cover")
        8
    else
        9
    end
    "https://map1.vis.earthdata.nasa.gov/wmts-webmerc/$(provider.variant)/default/$(provider.time)/$(provider.tilematrixset)$maxzoom/$z/$y/$x.$ext"
end
usagewarning(provider::NASAGIBSProvider) =
    string("You are requesting a very large map, please see the Bulk Downloading section of ",
           "https://wiki.earthdata.nasa.gov/display/GIBS/GIBS+API+for+Developers",
           " for details. Prior to beginning your bulk downloading activities, please ",
           "contact the GIBS support team at support@earthdata.nasa.gov.")

"""
Possible variants:
    * `World_Street_Map` (default)
    * `Specialty/DeLorme_World_Base_Map`
    * `World_Topo_Map`
    * `World_Imagery`
    * `World_Terrain_Base`
    * `World_Shaded_Relief`
    * `World_Physical_Map`
    * `Ocean_Basemap`
    * `NatGeo_World_Map`
    * `Canvas/World_Light_Gray_Base`
"""
@kwdef struct ESRIProvider <: AbstractProvider
    variant::String = "World_Street_Map"
    maxtiles::Int = typemax(Int)
end
geturl(provider::ESRIProvider, x::Integer, y::Integer, z::Integer) =
    "http://server.arcgisonline.com/ArcGIS/rest/services/$(provider.variant)/MapServer/tile/$z/$x/$y"
