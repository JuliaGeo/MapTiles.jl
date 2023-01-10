using TileProviders
using Test

@testset "TileProviders.jl run" begin
    providers = (
        TileProviders.OSM(),
        TileProviders.OSMFrance(),
        TileProviders.OSMDE(),
        TileProviders.OpenTopoMap(),
        TileProviders.CARTO(:dark_nolabels),
        TileProviders.Esri(),
        TileProviders.Stamen(),
        TileProviders.Stamen(:watercolor),
        TileProviders.CARTO(:dark_all),
        TileProviders.Google(:hybrid),
        TileProviders.MapBox(; tileset_id="username.id", access_token="sometoken"),
        TileProviders.Jawg(; access_token="sometoken"),
        TileProviders.Thunderforest(; apikey="someapikey"),
        TileProviders.OpenWeatherMap(:clouds; apikey="someapikey"),
        TileProviders.OpenWeatherMap(:clouds; apikey="someapikey"),
        TileProviders.NASAGIBS(:VIIRS_CityLights_2012),
        TileProviders.NASAGIBS(:AMSRE_Brightness_Temp_89H_Day; date=Date(2010, 05, 07)),
        TileProviders.Provider("http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"),
    )
end
