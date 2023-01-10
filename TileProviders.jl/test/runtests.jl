using TileProviders
using Test

@testset "TileProviders.jl" begin
    providers = (
        Leaflet.OSM(),
        Leaflet.OSMFrance(),
        Leaflet.OSMDE(),
        Leaflet.OpenTopoMap(),
        Leaflet.CARTO(:dark_nolabels),
        Leaflet.Esri(),
        Leaflet.Stamen(),
        Leaflet.Stamen(:watercolor),
        Leaflet.CARTO(:dark_all),
        Leaflet.Google(:hybrid),
        Leaflet.MapBox(; tileset_id="username.id", access_token="sometoken"),
        Leaflet.Jawg(; access_token="sometoken"),
        Leaflet.Thunderforest(; apikey="someapikey"),
        Leaflet.OpenWeatherMap(:clouds; apikey="someapikey"),
        Leaflet.OpenWeatherMap(:clouds; apikey="someapikey"),
        Leaflet.NASAGIBS(:VIIRS_CityLights_2012),
        Leaflet.NASAGIBS(:AMSRE_Brightness_Temp_89H_Day; date=Date(2010, 05, 07)),
        Leaflet.Provider("http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"),
    )
end
