using MapTiles
using Test
using GeoInterface: Extent, GeoInterface

@testset "CRS Interface Tests" begin
    @testset "Tile with CRS" begin
        # Test creating tiles with different CRS
        tile_wgs = Tile(10, 20, 5, MapTiles.wgs84)
        tile_web = Tile(10, 20, 5, MapTiles.web_mercator)
        
        # Test interface functions
        @test GeoInterface.crs(tile_wgs) === MapTiles.wgs84
        @test GeoInterface.crs(tile_web) === MapTiles.web_mercator
        @test MapTiles.x(tile_wgs) === 10
        @test MapTiles.y(tile_wgs) === 20
        @test MapTiles.z(tile_wgs) === 5
        @test MapTiles.zoom(tile_wgs) === 5
        
        # Test bounds in native CRS
        bounds_wgs = MapTiles.bounds(tile_wgs)
        @test bounds_wgs isa Extent
        @test bounds_wgs == extent(tile_wgs, MapTiles.wgs84)
        
        bounds_web = MapTiles.bounds(tile_web)
        @test bounds_web isa Extent
        @test bounds_web == extent(tile_web, MapTiles.web_mercator)
        
        # Test bounds with projection
        bounds_wgs_to_web = MapTiles.bounds(tile_wgs, MapTiles.web_mercator)
        @test bounds_wgs_to_web isa Extent
        @test bounds_wgs_to_web == extent(tile_wgs, MapTiles.web_mercator)
        
        # Test that tiles with same indices but different CRS are not equal
        @test tile_wgs != tile_web
    end
    
    @testset "TileGrid with CRS" begin
        bbox_wgs = Extent(X = (-1.23, 5.65), Y = (-5.68, 4.77))
        grid_wgs = TileGrid(bbox_wgs, 8, MapTiles.wgs84)
        
        bbox_web = MapTiles.project_extent(bbox_wgs, MapTiles.wgs84, MapTiles.web_mercator)
        grid_web = TileGrid(bbox_web, 8, MapTiles.web_mercator)
        
        # Test interface functions
        @test GeoInterface.crs(grid_wgs) === MapTiles.wgs84
        @test GeoInterface.crs(grid_web) === MapTiles.web_mercator
        @test MapTiles.zoom(grid_wgs) === 8
        
        # Test bounds in native CRS
        bounds_wgs = MapTiles.bounds(grid_wgs)
        @test bounds_wgs isa Extent
        @test bounds_wgs == extent(grid_wgs, MapTiles.wgs84)
        
        # Test bounds with projection
        bounds_wgs_to_web = MapTiles.bounds(grid_wgs, MapTiles.web_mercator)
        @test bounds_wgs_to_web isa Extent
        @test bounds_wgs_to_web == extent(grid_wgs, MapTiles.web_mercator)
        
        # Test that grids with same tiles but different CRS are not equal
        @test grid_wgs != grid_web
        
        # Test that tiles from grid have the same CRS as the grid
        first_tile = grid_wgs[1]
        @test GeoInterface.crs(first_tile) === MapTiles.wgs84
    end
    
    @testset "Backward compatibility" begin
        # Test that old constructors still work
        point_wgs = (-105.0, 40.0)
        old_tile = Tile(point_wgs, 8, MapTiles.wgs84)
        @test old_tile isa MapTiles.AbstractTile
        @test GeoInterface.crs(old_tile) === MapTiles.wgs84
        
        # Test old TileGrid constructor
        bbox = Extent(X = (-1.23, 5.65), Y = (-5.68, 4.77))
        old_grid = TileGrid(bbox, 8, MapTiles.wgs84)
        @test old_grid isa MapTiles.AbstractTileGrid
        @test GeoInterface.crs(old_grid) === MapTiles.wgs84
    end
    
    @testset "Type stability" begin
        tile_wgs = Tile(10, 20, 5, MapTiles.wgs84)
        tile_web = Tile(10, 20, 5, MapTiles.web_mercator)
        
        # Check that interface functions are type stable
        @test @inferred(GeoInterface.crs(tile_wgs)) === MapTiles.wgs84
        @test @inferred(MapTiles.x(tile_wgs)) === 10
        @test @inferred(MapTiles.y(tile_wgs)) === 20
        @test @inferred(MapTiles.z(tile_wgs)) === 5
        @test @inferred(MapTiles.zoom(tile_wgs)) === 5
        
        # Check bounds functions are type stable
        @test @inferred(MapTiles.bounds(tile_wgs)) isa Extent
        @test @inferred(MapTiles.bounds(tile_wgs, MapTiles.web_mercator)) isa Extent
    end
end