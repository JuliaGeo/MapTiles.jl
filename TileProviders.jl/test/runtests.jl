using TileProviders
using Test
using Dates

@testset "TileProviders.jl run" begin
    providers = (
        TileProviders.OpenStreetMap() ,
        TileProviders.OpenStreetMap(:France),
        TileProviders.OpenStreetMap(:DE),
        TileProviders.OpenTopoMap(),
        TileProviders.CartoDB(:DarkMatter),
        TileProviders.Esri(),
        TileProviders.Stamen(),
        TileProviders.Stamen(:Watercolor),
        TileProviders.Google(:hybrid),
        TileProviders.Google(:roadmap),
        TileProviders.MapBox(; accesstoken="sometoken"),
        TileProviders.Jawg(; accesstoken="sometoken"),
        TileProviders.Thunderforest(; apikey="someapikey"),
        TileProviders.OpenWeatherMap(:Clouds),
        TileProviders.NASAGIBS(:ViirsEarthAtNight2012),
        TileProviders.NASAGIBSTimeseries(:AMSRE_Brightness_Temp_89H_Day; date=Date(2010, 05, 07)),
        TileProviders.NASAGIBSTimeseries(:AMSRE_Brightness_Temp_89H_Day; date=Date(2010, 05, 07)),
        TileProviders.Provider("http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png") ,
    )
    map(providers) do provider
        TileProviders.geturl(provider, 1, 2, 3)
    end

    provider = TileProviders.OpenStreetMap()
    @test TileProviders.geturl(provider, 1, 2, 3) == "https://tile.openstreetmap.org/3/1/2.png"
    provider = TileProviders.NASAGIBSTimeseries(:AMSRE_Brightness_Temp_89H_Day; date=Date(2010, 05, 07))
    @test TileProviders.geturl(provider, 1, 2, 3) == "https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/AMSRE_Brightness_Temp_89H_Day/default/2010-05-07/GoogleMapsCompatible_Level6/3/2/1.png"
end
