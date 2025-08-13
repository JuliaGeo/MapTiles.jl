using MapTiles
using Test
using GeoInterface: Extent, GeoInterface

@testset "Custom Tile System Tests" begin
    @testset "TileGridSpec" begin
        bbox = Extent(X=(0.0, 100.0), Y=(0.0, 50.0))
        spec = TileGridSpec(bbox, 3, (10, 5), MapTiles.wgs84)
        
        @test spec.bbox == bbox
        @test spec.zoom == 3
        @test spec.size == (10, 5)
        @test spec.crs === MapTiles.wgs84
    end
    
    @testset "CustomTile" begin
        bbox = Extent(X=(0.0, 100.0), Y=(0.0, 50.0))
        spec = TileGridSpec(bbox, 3, (10, 5), MapTiles.wgs84)
        tile = CustomTile(3, 2, spec)
        
        # Test interface functions
        @test MapTiles.x(tile) == 3
        @test MapTiles.y(tile) == 2
        @test MapTiles.z(tile) == 3
        @test MapTiles.zoom(tile) == 3
        @test GeoInterface.crs(tile) === MapTiles.wgs84
        
        # Test that it's an AbstractTile
        @test tile isa MapTiles.AbstractTile
        
        # Test extent calculation
        tile_extent = extent(tile, MapTiles.wgs84)
        @test tile_extent.X[1] ≈ 30.0  # 3 * (100/10)
        @test tile_extent.X[2] ≈ 40.0  # 30 + (100/10)
        @test tile_extent.Y[1] ≈ 20.0  # 2 * (50/5)
        @test tile_extent.Y[2] ≈ 30.0  # 20 + (50/5)
        
        # Test bounds function
        bounds_native = MapTiles.bounds(tile)
        @test bounds_native == tile_extent
    end
    
    @testset "CustomTileGrid" begin
        bbox = Extent(X=(0.0, 100.0), Y=(0.0, 50.0))
        spec = TileGridSpec(bbox, 3, (10, 5), MapTiles.wgs84)
        grid = CustomTileGrid(spec)
        
        # Test interface functions
        @test GeoInterface.crs(grid) === MapTiles.wgs84
        @test MapTiles.zoom(grid) == 3
        
        # Test that it's an AbstractTileGrid
        @test grid isa MapTiles.AbstractTileGrid
        
        # Test size and length
        @test size(grid) == (10, 5)
        @test length(grid) == 50
        
        # Test indexing
        first_tile = grid[1]
        @test first_tile isa CustomTile
        @test MapTiles.x(first_tile) == 0
        @test MapTiles.y(first_tile) == 0
        @test first_tile.spec === spec
        
        # Test specific tile
        tile_23 = grid[CartesianIndex(3, 2)]
        @test MapTiles.x(tile_23) == 2  # 0-based indexing
        @test MapTiles.y(tile_23) == 1  # 0-based indexing
        
        # Test iteration
        tiles = collect(grid)
        @test length(tiles) == 50
        @test all(t isa CustomTile for t in tiles)
        
        # Test extent
        grid_extent = extent(grid, MapTiles.wgs84)
        @test grid_extent == bbox
        
        # Test bounds
        bounds_native = MapTiles.bounds(grid)
        @test bounds_native == bbox
    end
    
    @testset "Raster tile creation" begin
        # Simulate a raster with specific dimensions
        raster_bbox = Extent(X=(-180.0, 180.0), Y=(-90.0, 90.0))
        raster_size = (3600, 1800)  # 0.1 degree resolution
        tile_size = (256, 256)
        
        spec = create_raster_tiles(raster_bbox, raster_size, tile_size, MapTiles.wgs84, 5)
        
        @test spec.bbox == raster_bbox
        @test spec.zoom == 5
        @test spec.size[1] == ceil(Int, 3600 / 256)  # 15
        @test spec.size[2] == ceil(Int, 1800 / 256)  # 8
        @test spec.crs === MapTiles.wgs84
        
        # Create grid and test a few tiles
        grid = CustomTileGrid(spec)
        @test size(grid) == (15, 8)
        
        # Test that tiles cover the right area
        first_tile = grid[1]
        first_extent = extent(first_tile, MapTiles.wgs84)
        expected_width = 360.0 / 15
        expected_height = 180.0 / 8
        @test first_extent.X[2] - first_extent.X[1] ≈ expected_width
        @test first_extent.Y[2] - first_extent.Y[1] ≈ expected_height
    end
    
    @testset "Custom CRS tiles" begin
        # Test with web mercator bounds
        bbox_web = Extent(X=(-2e7, 2e7), Y=(-2e7, 2e7))
        spec = TileGridSpec(bbox_web, 0, (4, 4), MapTiles.web_mercator)
        grid = CustomTileGrid(spec)
        
        @test GeoInterface.crs(grid) === MapTiles.web_mercator
        @test size(grid) == (4, 4)
        
        # Test projection to WGS84
        tile = grid[CartesianIndex(2, 2)]
        extent_web = extent(tile, MapTiles.web_mercator)
        extent_wgs = extent(tile, MapTiles.wgs84)
        
        # Verify projection happened
        @test extent_wgs != extent_web
        @test -180 <= extent_wgs.X[1] <= 180
        @test -90 <= extent_wgs.Y[1] <= 90
    end
    
    @testset "Edge cases" begin
        # Single tile grid
        bbox = Extent(X=(0.0, 1.0), Y=(0.0, 1.0))
        spec = TileGridSpec(bbox, 0, (1, 1), MapTiles.wgs84)
        grid = CustomTileGrid(spec)
        
        @test size(grid) == (1, 1)
        @test length(grid) == 1
        
        tile = grid[1]
        tile_extent = extent(tile, MapTiles.wgs84)
        @test tile_extent == bbox
    end
end