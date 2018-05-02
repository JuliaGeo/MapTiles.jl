using MapTiles
using Base.Test

@testset "Raster Base Maps" begin
    basemap = MapTiles.fetchmap(
        -1, # minlon
        48, # minlat
        3, # maxlon
        52, # maxlat
        4, # zoom
    )
    @test size(basemap.img) == (256,512)
    @test basemap.tilesize == (256,256)
    @test basemap.xmin == 7
    @test basemap.xmax == 8
    @test basemap.ymin == 5
    @test basemap.ymax == 5
    @test basemap.zoom == 4
end
