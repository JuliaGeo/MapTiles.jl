using TileProviders
using Test
using Dates

@testset "TileProviders.jl run" begin
    providers = (
        CyclOSM(),
        USGS(),
        Stadia(),
        OPNVKarte(),
        FreeMapSK(),
        HikeBike(),
        NLS(),
        OpenSeaMap(),
        WaymarkedTrails(),
        MtbMap(),
        CartoDB(),
        OpenRailwayMap(),
        NASAGIBS(),
        OneMapSG(),
        Stamen(),
        JusticeMap(),
        SafeCast(),
        MapTiler(),
        OpenFireMap(),
        OpenStreetMap(),
        Google(),
        nlmaps(),
        SwissFederalGeoportal(),
        OpenTopoMap(),
        OpenSnowMap(),
        OpenAIP(),
        Esri(),
        BasemapAT(),
        TomTom(; apikey="some_apikey"),
        Thunderforest(; apikey="some_apikey"),
        Jawg(; accesstoken="some_token"),
        GeoportailFrance(; apikey="some_apikey"),
        MapBox(; accesstoken="some_token"),
        Jawg(; accesstoken="some_token"),
        Thunderforest(; apikey="some_apikey"),
        HERE(; app_code="some_app_code"),
        HEREv3(; apikey="some_apikey"),
        TileProviders.NASAGIBSTimeseries(:AMSRE_Brightness_Temp_89H_Day; date=Date(2010, 05, 07)),
        TileProviders.Provider("http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png") ,
    )

    for provider in providers
        url = TileProviders.geturl(provider, 1, 2, 3)
        # Make sure we removed all the { } braces
        @test !occursin("{", url)
        @test !occursin("}", url)
    end

    provider = TileProviders.OpenStreetMap()
    @test TileProviders.geturl(provider, 1, 2, 3) == "https://tile.openstreetmap.org/3/1/2.png"
    provider = TileProviders.NASAGIBSTimeseries(:AMSRE_Brightness_Temp_89H_Day; date=Date(2010, 05, 07))
    @test TileProviders.geturl(provider, 1, 2, 3) == "https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/AMSRE_Brightness_Temp_89H_Day/default/2010-05-07/GoogleMapsCompatible_Level6/3/2/1.png"

    @test_throws UndefKeywordError MapBox()
    @test_throws UndefKeywordError MapTilesAPI()
    @test_throws UndefKeywordError HEREv3()
    @test_throws UndefKeywordError HERE()
    @test_throws UndefKeywordError OpenWeatherMap()
    @test_throws UndefKeywordError AzureMaps()
    @test_throws UndefKeywordError Thunderforest()
    @test_throws UndefKeywordError Jawg()
    @test_throws UndefKeywordError GeoportailFrance()

    TileProviders.list_providers()
end
