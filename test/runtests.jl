import MapTiles as MT
using GeoInterface: Extent, extent
using MapTiles
using Test
import Aqua
import HTTP, ImageMagick
using TileProviders

@testset "MapTiles" begin

@testset "Tile" begin
    point_wgs = (-105.0, 40.0)
    tile = Tile(point_wgs, 1, MT.wgs84)
    @test tile === Tile(0, 0, 1)
    bbox = extent(tile, MT.wgs84)
    bbox == Extent(X = (-180.0, 0.0), Y = (0.0, 85.0511287798066))
    @test bbox isa Extent
    @test bbox.X === (-180.0, 0.0)
    @test bbox.Y[1] === 0.0
    @test bbox.Y[2] ≈ 85.0511287798066
    bbox = extent(tile, MT.web_mercator)
    @test bbox isa Extent
    @test bbox.X[1] ≈ -2.0037508342789244e7
    @test bbox.X[2] === 0.0
    @test bbox.Y[1] === 0.0
    @test bbox.Y[2] ≈ 2.0037508342789244e7
end

@testset "TileGrid" begin
    point_wgs = (-105.0, 40.0)
    tile = Tile(point_wgs, 1, MT.wgs84)
    bbox = extent(tile, MT.web_mercator)
    @test TileGrid(tile) === TileGrid(CartesianIndices((0:0, 0:0)), 1)
    @test TileGrid(bbox, 0, MT.wgs84) === TileGrid(CartesianIndices((0:0, 0:0)), 0)
    tilegrid = TileGrid(bbox, 3, MT.wgs84)
    @test tilegrid === TileGrid(CartesianIndices((0:3, 0:4)), 3)

    bbox = Extent(X = (-1.23, 5.65), Y = (-5.68, 4.77))
    tilegrid = TileGrid(bbox, 8, MT.wgs84)
    @test size(tilegrid) === (6, 9)
    @test length(tilegrid) === 54
    # creating a TileGrid from a web mercator extent
    webbox = MT.project_extent(bbox, MT.wgs84, MT.web_mercator)
    @test tilegrid === TileGrid(webbox, 8, MT.web_mercator)
end

@testset "project" begin
    # point
    point_wgs = (-105.0, 40.0)
    point_web = MT.project(point_wgs, MT.wgs84, MT.web_mercator)
    @test point_web[1] ≈ -1.1688546533293726e7
    @test point_web[2] ≈ 4.865942279503176e6
    point_wgs2 = MT.project(point_web, MT.web_mercator, MT.wgs84)
    point_wgs[1] ≈ point_wgs2[1]
    point_wgs[2] ≈ point_wgs2[2]

    # extent
    bbox = Extent(X = (-180.0, 0.0), Y = (0.0, 85.0511287798066))
    webbox = MT.project_extent(bbox, MT.wgs84, MT.web_mercator)
    @test webbox.X[1] ≈ -2.0037508342789244e7
    @test webbox.X[2] == 0.0
    @test webbox.Y[1] ≈ -7.081154551613622e-10
    @test webbox.Y[2] ≈ 2.0037508342789244e7
end

Aqua.test_all(MapTiles)

end
