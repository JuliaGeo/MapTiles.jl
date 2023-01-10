
"""
    OSM()

[`Provider`](@ref) for the [Open Street Map](https://wiki.openstreetmap.org/wiki/Standard_tile_layer)
base layer.
"""
OSM() = Provider(
    "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    Dict{Symbol,Any}(
        :maxZoom => 19,
        :attribution => """&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>"""
    )
)

"""
    OSMDE()

[`Provider`](@ref) for the [German](https://www.openstreetmap.de/) Open Street Map base layer.
"""
OSMDE() = Provider(
    "http://{s}.tile.openstreetmap.de/tiles/osmde/{z}/{x}/{y}.png",
    Dict{Symbol,Any}(
        :maxZoom => 19,
        :attribution => """&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>"""
    )
)

"""
    OSMFrance()

[`Provider`](@ref) for [French](https://wiki.openstreetmap.org/wiki/Standard_tile_layer)
Open Street Map base layer.
"""
OSMFrance() = Provider(
    "http://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png",
    Dict{Symbol,Any}(
        :maxZoom => 20,
        :attribution => """&copy; Openstreetmap France | {attribution.OpenStreetMap}"""
    )
)

"""
    OSMHumanitarian()

[`Provider`](@ref) for [Humanitarian](https://wiki.openstreetmap.org/wiki/Humanitarian_map_style) base layer.

Adapted OSM base layer focused on resources useful for humanitarian organizations and
citizens in general in emergency situations.
"""
OSMHumanitarian() = Provider(
    "http://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
    Dict(
        :maxZoom => 18,
        :attribution => """{attribution.OpenStreetMap}, Tiles courtesy of <a href="http://hot.openstreetmap.org/" target="_blank">Humanitarian OpenStreetMap Team</a>"""
    )
)


const _GOOGLE_VARIANTS = (roadmap="m", satelite="s", terrain="p", hybrid="y")

"""
    Google()

[`Provider`](@ref) for base layers from Google maps.

$(_variant_list(_GOOGLE_VARIANTS))
"""
function Google(variant=:satelite)
    _checkin(variant, _GOOGLE_VARIANTS)
    Provider(
        "https://mt1.google.com/vt/lyrs={variant}&x={x}&y={y}&z={z}",
        Dict(
            :maxZoom => 20,
            :attribution => "Google",
            :variant => _GOOGLE_VARIANTS[variant],
        )
    )
end

const _THUNDERFOREST_VARIANTS = (
    cycle = "cycle",
    transport = "transport",
    transport_dark = "transport-dark",
    spinal_map = "spinal-map",
    landscape = "landscape",
    outdoors = "outdoors",
    pioneer = "pioneer",
)

"""
    Thunderforest(variant::Symbol=:cycle; apikey)

[`Provider`](@ref) for Thunderforest base layers. A Thunderforest API key is required.

$(_variant_list(_THUNDERFOREST_VARIANTS))
"""
function Thunderforest(variant::Symbol=:cycle; apikey)
    _checkin(variant, _THUNDERFOREST_VARIANTS)
    Provider(
        "http://{s}.tile.thunderforest.com/{variant}/{z}/{x}/{y}.png?apikey={apikey}",
        Dict{Symbol,Any}(
            :maxZoom => 22,
            :variant => _THUNDERFOREST_VARIANTS[variant],
            :apikey => apikey,
            :attribution => """&copy; <a href="http://www.thunderforest.com/">Thunderforest</a>, {attribution.OpenStreetMap}',"""
        )
    )
end

"""
    Mapbox(variant::Symbol=:cycle; apikey)

[`Provider`](@ref) for the Mapbox base layer.
"""
MapBox(; tileset_id, access_token) = Provider(
    "http://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token={access_token}",
    Dict{Symbol,Any}(
        :subdomains => "abcd",
        :id => "streets",
        :access_token => access_token,
        :attribution => """Imagery from <a href="http://mapbox.com/about/maps/">MapBox</a> &mdash; Map data {attribution.OpenStreetMap}"""
    )
)

const _STAMEN_VARIANTS = (
    toner = "toner",
    toner_background ="toner-background",
    toner_hybrid ="toner-hybrid",
    toner_lines = "toner-lines",
    toner_labels ="toner-labels",
    toner_lite ="toner-lite",
    watercolor ="watercolor",
    terrain = "terrain",
    terrain_background ="terrain-background",
    toposm_color_relief = "toposm-color-relief",
    toposm_features = "toposm-features",
)

"""
    Stamen(variant::Symbol)

[`Provider`](@ref) for [Stamen](http://maps.stamen.com) base layers.

$(_variant_list(_STAMEN_VARIANTS))
"""
function Stamen(variant::Symbol = :toner)
    _checkin(variant, _STAMEN_VARIANTS)
    provider = Provider(
        "http://stamen-tiles-{s}.a.ssl.fastly.net/{variant}/{z}/{x}/{y}.{ext}",
        Dict{Symbol,Any}(
            :subdomains => "abcd",
            :minZoom => 0,
            :maxZoom => 20,
            :variant => _STAMEN_VARIANTS[variant],
            :ext => "png",
            :attribution => """Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>"""
        )
    )
    if variant == :watercolor
        provider.options[:minZoom] = 1
        provider.options[:maxZoom] = 16
    elseif variant == :terrain || variant == :terrain_background
        provider.options[:minZoom] = 0
        provider.options[:maxZoom] = 18
    elseif variant == :toposm_color_relief
        provider.options[:ext] = "jpg'"
        provider.options[:bounds] = [[22, -132], [51, -56]]
    elseif variant == :toposm_features
        provider.options[:opacity] = 0.9
        provider.options[:bounds] = [[22, -132], [51, -56]]
    end
    return provider
end

const _ESRI_VARIANTS = (
    street = "World_Street_Map",
    delorme = "Specialty/DeLorme_World_Base_Map",
    topo = "World_Topo_Map",
    imagery = "World_Imagery",
    terrain = "World_Terrain_Base",
    releif = "World_Shaded_Relief",
    physical = "World_Physical_Map",
    ocean = "Ocean_Basemap",
    natgeo = "NatGeo_World_Map",
    light_gray = "Canvas/World_Light_Gray_Base",
)

"""
    Esri(variant::Symbol)

[`Provider`](@ref) for [Esri basemaps](https://www.esri.com/en-us/arcgis/products/arcgis-platform/services/basemaps).

$(_variant_list(_ESRI_VARIANTS))
"""
function Esri(variant::Symbol = :street)
    _checkin(variant, _ESRI_VARIANTS)
    provider = Provider(
        "http://server.arcgisonline.com/ArcGIS/rest/services/{variant}/MapServer/tile/{z}/{y}/{x}",
        Dict{Symbol,Any}(
            :variant => _ESRI_VARIANTS[variant],
            :attribution => """{attribution.Esri} &mdash; Source: Esri, DeLorme, NAVTEQ, USGS, Intermap, iPC, NRCAN, Esri Japan, METI, Esri China (Hong Kong), Esri (Thailand), TomTom, 2012"""
        )
    )
    if variant == :delorme
        provider.options[:minZoom] = 1
        provider.options[:maxZoom] = 11
        provider.options[:attribution] = """{attribution.Esri} &mdash; Copyright: &copy;2012 DeLorme"""
    elseif variant == :topo
        provider.options[:attribution] = """{attribution.Esri} &mdash; Esri, DeLorme, NAVTEQ, TomTom, Intermap, iPC, USGS, FAO, NPS, NRCAN, GeoBase, Kadaster NL, Ordnance Survey, Esri Japan, METI, Esri China (Hong Kong), and the GIS User Community"""
    elseif variant == :imagery
        provider.options[:attribution] = """{attribution.Esri} &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community"""
    elseif variant == :terrain
        provider.options[:maxZoom] = 13
        provider.options[:attribution] = """{attribution.Esri} &mdash; Source: USGS, Esri, TANA, DeLorme, and NPS"""
    elseif variant == :releif
        provider.options[:maxZoom] = 13
        provider.options[:attribution] = """{attribution.Esri} &mdash; Source: Esri"""
    elseif variant == :physical
        provider.options[:maxZoom] = 8
        provider.options[:attribution] = """{attribution.Esri} &mdash; Source: US National Park Service"""
    elseif variant == :ocean
        provider.options[:maxZoom] = 13
        provider.options[:attribution] = """{attribution.Esri} &mdash; Sources: GEBCO, NOAA, CHS, OSU, UNH, CSUMB, National Geographic, DeLorme, NAVTEQ, and Esri"""
    elseif variant == :natgeo
        provider.options[:maxZoom] = 16
        provider.options[:attribution] = """{attribution.Esri} &mdash; National Geographic, Esri, DeLorme, NAVTEQ, UNEP-WCMC, USGS, NASA, ESA, METI, NRCAN, GEBCO, NOAA, iPC"""
    elseif variant == :light_gray
        provider.options[:maxZoom] = 16
        provider.options[:attribution] = """{attribution.Esri} &mdash; Esri, DeLorme, NAVTEQ"""
    end
    return provider
end

const _OPENWEATHERMAP_VARIANTS = (
    clouds = "clouds",
    clouds_classic = "clouds_cls",
    precipitation = "precipitation",
    precipitation_classic = "precipitation_cls",
    rain = "rain",
    rain_classic = "rain_cls",
    pressure = "pressure",
    pressure_contour = "pressure_cntr",
    wind = "wind",
    temp = "temp",
    snow = "snow",
)

"""
    OpenWeatherMap(variant::Symbol; apikey)

O[`Provider`](@ref) for OpenWeatherMap base layers. An OpenWeatherMap api key is required.

$(_variant_list(_OPENWEATHERMAP_VARIANTS))
"""
OpenWeatherMap(variant=:temp; apikey) = Provider(
    "http://tile.openweathermap.org/map/clouds/{z}/{x}/{y}.png?appid={apikey}",
    Dict{Symbol,Any}(
        :maxZoom => 19,
        :variant => _OPENWEATHERMAP_VARIANTS[variant],
        :apikey => apikey,
        :opacity => 0.5,
        :attribution => """Map data &copy; <a href="http://openweathermap.org">OpenWeatherMap</a>""",
    )
)

const _CARTO_VARIANTS = (
    light_all = "light_all",
    light_nolabels = "light_nolabels",
    light_only_labels = "light_only_labels",
    dark_all = "dark_all",
    dark_nolabels = "dark_nolabels",
    dark_only_labels = "dark_only_labels",
)

"""
    CARTO(variant::Symbol)

[`Provider`](@ref) for [CARTO basemaps](https://carto.com/basemaps/).

$(_variant_list(_CARTO_VARIANTS))
"""
function CARTO(variant::Symbol = :light_all)
    _checkin(variant, _CARTO_VARIANTS)
    return Provider(
        "http://{s}.basemaps.cartocdn.com/{variant}/{z}/{x}/{y}.png",
        Dict{Symbol,Any}(
            :maxZoom => 19,
            :variant => _CARTO_VARIANTS[variant],
            :subdomains => "abcd",
            :attribution => """{attribution.OpenStreetMap} &copy; <a href="http://cartodb.com/attributions">CartoDB</a>"""
        )
    )
end

const _JAWG_VARIANTS = (
    streets = "streets",
    terrain = "terrain",
    sunny = "sunny",
    dark = "dark",
    light = "light",
    matrix = "matrix",
)

"""
    Jawg(variant::Symbol; access_token)

[`Provider`](@ref) for Jawg base layers. Must pass an `access_token` to use the API.

$(_variant_list(_JAWG_VARIANTS))
"""
function Jawg(variant::Symbol=:streets; access_token) 
    _checkin(variant, _JAWG_VARIANTS)
    return Provider("'https://{s}.tile.jawg.io/jawg-{variant}/{z}/{x}/{y}{r}.png?access-token={accessToken}'",
        Dict{Symbol,Any}(
            :minZoom => 0,
            :maxZoom => 22,
            :accessToken => access_token,
            :attribution => """<a href="http://jawg.io" title="Tiles Courtesy of Jawg Maps" target="_blank">&copy; <b>Jawg</b>Maps</a> &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors""",
        )
   )
end

"""
    OpenTopoMap()

[`Provider`](@ref) for the [Open Topo](https://wiki.openstreetmap.org/wiki/OpenTopoMap) base layer.
"""
OpenTopoMap() = Provider(
    "http://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
    Dict(
        :maxZoom => 17,
        :attribution => """Map data: {attribution.OpenStreetMap}, <a href="http://viewfinderpanoramas.org">SRTM</a> | Map style: &copy; <a href="https://opentopomap.org">OpenTopoMap</a> (<a href="https://creativecommons.org/licenses/by-sa/3.0/">CC-BY-SA</a>)"""
    )
)

