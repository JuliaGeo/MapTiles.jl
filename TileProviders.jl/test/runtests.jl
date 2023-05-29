using TileProviders
using Test
using Dates

@testset "TileProviders.jl run" begin
    providers = (
        # from leaflet-providers-parsed.json
        OpenStreetMap(),
        MapTilesAPI(; apikey="some_key"),
        OpenSeaMap(),
        OPNVKarte(),
        OpenTopoMap(),
        OpenRailwayMap(),
        OpenFireMap(),
        SafeCast(),
        Stadia(),
        Thunderforest(; apikey="some_apikey"),
        CyclOSM(),
        Jawg(; accesstoken="some_token"),
        MapBox(; accesstoken="some_token"),
        MapTiler(),
        Stamen(),
        TomTom(; apikey="some_apikey"),
        Esri(),
        OpenWeatherMap(; apikey="some_apikey"),
        HERE(; app_code="some_app_code"),
        HEREv3(; apikey="some_apikey"),
        FreeMapSK(),
        MtbMap(),
        CartoDB(),
        HikeBike(),
        BasemapAT(),
        nlmaps(),
        NASAGIBS(),
        NLS(),
        JusticeMap(),
        GeoportailFrance(; apikey="some_apikey"),
        OneMapSG(),
        USGS(),
        WaymarkedTrails(),
        OpenAIP(),
        OpenSnowMap(),
        AzureMaps(; subscriptionkey="some_subscriptionkey"),
        SwissFederalGeoportal(),

        # Google, NASAGIBSTimeseries, general Provider
        Google(),
        NASAGIBSTimeseries(:AMSRE_Brightness_Temp_89H_Day; date=Date(2010, 05, 07)),
        Provider("http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png") ,
    )

    for provider in providers
        url = TileProviders.geturl(provider, 1, 2, 3)
        # Make sure we removed all the { } braces
        @test !occursin("{", url)
        @test !occursin("}", url)
    end

    provider = OpenStreetMap()
    @test TileProviders.geturl(provider, 1, 2, 3) == "https://tile.openstreetmap.org/3/1/2.png"
    provider = NASAGIBSTimeseries(:AMSRE_Brightness_Temp_89H_Day; date=Date(2010, 05, 07))
    @test TileProviders.geturl(provider, 1, 2, 3) == "https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/AMSRE_Brightness_Temp_89H_Day/default/2010-05-07/GoogleMapsCompatible_Level6/3/2/1.png"
    provider = GeoportailFrance(;apikey = "cartes") # Default variant corresponds to Plan IGN service "https://geoservices.ign.fr/services-web-experts-cartes"
    @test TileProviders.geturl(provider, 1, 2, 3) == "https://wxs.ign.fr/cartes/geoportail/wmts?REQUEST=GetTile&SERVICE=WMTS&VERSION=1.0.0&STYLE=normal&TILEMATRIXSET=PM&FORMAT=image/png&LAYER=GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2&TILEMATRIX=3&TILEROW=2&TILECOL=1"

    @test_throws UndefKeywordError MapTilesAPI()
    @test_throws UndefKeywordError Thunderforest()
    @test_throws UndefKeywordError Jawg()
    @test_throws UndefKeywordError MapBox()
    @test_throws UndefKeywordError TomTom()
    @test_throws UndefKeywordError OpenWeatherMap()
    @test_throws UndefKeywordError HERE()
    @test_throws UndefKeywordError HEREv3()
    @test_throws UndefKeywordError GeoportailFrance()
    @test_throws UndefKeywordError AzureMaps()

    TileProviders.list_providers()
end
