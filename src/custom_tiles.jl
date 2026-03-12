# Custom tile system for arbitrary tilesets

"""
    TileGridSpec{T<:CoordinateReferenceSystemFormat}

Specification for a custom tile grid system that defines how a bounding box
is divided into tiles. This allows for arbitrary tiling schemes beyond
standard web mercator tiles.

# Fields
- `bbox::Extent`: The bounding box covered by this tile grid
- `zoom::Int`: The zoom level (can be arbitrary for custom grids)
- `size::Tuple{Int,Int}`: Number of tiles in (x, y) directions
- `crs::T`: The coordinate reference system
"""
struct TileGridSpec{T<:CoordinateReferenceSystemFormat}
    bbox::Extent
    zoom::Int
    size::Tuple{Int,Int}
    crs::T
end

"""
    CustomTile{T<:CoordinateReferenceSystemFormat}

A tile that references a TileGridSpec, allowing for arbitrary tile systems
that may not follow web mercator conventions.

# Fields
- `x::Int`: X index of the tile (0-based)
- `y::Int`: Y index of the tile (0-based)
- `spec::TileGridSpec{T}`: Reference to the grid specification
"""
struct CustomTile{T<:CoordinateReferenceSystemFormat} <: AbstractTile
    x::Int
    y::Int
    spec::TileGridSpec{T}
end

# Implement the AbstractTile interface for CustomTile
GeoInterface.crs(tile::CustomTile) = tile.spec.crs
x(tile::CustomTile) = tile.x
y(tile::CustomTile) = tile.y
z(tile::CustomTile) = tile.spec.zoom
# No direct z field, but we can use the zoom from the spec

"""
    CustomTileGrid{T<:CoordinateReferenceSystemFormat}

A grid of custom tiles based on a TileGridSpec.

# Fields
- `indices::CartesianIndices{2}`: The range of tile indices
- `spec::TileGridSpec{T}`: The grid specification
"""
struct CustomTileGrid{T<:CoordinateReferenceSystemFormat} <: AbstractTileGrid
    indices::CartesianIndices{2, Tuple{UnitRange{Int}, UnitRange{Int}}}
    spec::TileGridSpec{T}
end

# Constructor for CustomTileGrid from TileGridSpec
function CustomTileGrid(spec::TileGridSpec)
    indices = CartesianIndices((0:spec.size[1]-1, 0:spec.size[2]-1))
    return CustomTileGrid(indices, spec)
end

# Implement the AbstractTileGrid interface
GeoInterface.crs(grid::CustomTileGrid) = grid.spec.crs
zoom(grid::CustomTileGrid) = grid.spec.zoom

# Implement iteration and indexing for CustomTileGrid
Base.length(grid::CustomTileGrid) = length(grid.indices)
Base.size(grid::CustomTileGrid, dims...) = size(grid.indices, dims...)
Base.getindex(grid::CustomTileGrid, i) = CustomTile(grid.indices[i][1], grid.indices[i][2], grid.spec)
Base.firstindex(grid::CustomTileGrid) = firstindex(grid.indices)
Base.lastindex(grid::CustomTileGrid) = lastindex(grid.indices)

function Base.iterate(grid::CustomTileGrid, state=1)
    if state > length(grid)
        nothing
    else
        (grid[state], state+1)
    end
end

"""
    extent(tile::CustomTile, crs::CoordinateReferenceSystemFormat)

Get the bounding box of a custom tile in the specified CRS.
"""
function Extents.extent(tile::CustomTile, crs::CoordinateReferenceSystemFormat)
    spec = tile.spec
    total_bbox = spec.bbox
    
    # Calculate the extent of this specific tile
    x_min, x_max = total_bbox.X
    y_min, y_max = total_bbox.Y
    
    # Calculate tile dimensions
    tile_width = (x_max - x_min) / spec.size[1]
    tile_height = (y_max - y_min) / spec.size[2]
    
    # Calculate this tile's extent
    tile_x_min = x_min + tile.x * tile_width
    tile_x_max = tile_x_min + tile_width
    tile_y_min = y_min + tile.y * tile_height
    tile_y_max = tile_y_min + tile_height
    
    tile_extent = Extent(X=(tile_x_min, tile_x_max), Y=(tile_y_min, tile_y_max))
    
    # Project if needed
    if crs == spec.crs
        return tile_extent
    else
        return project_extent(tile_extent, spec.crs, crs)
    end
end

"""
    extent(grid::CustomTileGrid, crs::CoordinateReferenceSystemFormat)

Get the bounding box of the entire custom tile grid in the specified CRS.
"""
function Extents.extent(grid::CustomTileGrid, crs::CoordinateReferenceSystemFormat)
    if crs == grid.spec.crs
        return grid.spec.bbox
    else
        return project_extent(grid.spec.bbox, grid.spec.crs, crs)
    end
end

# Resolve method ambiguities with specific implementations
function Extents.extent(tile::CustomTile, crs::WGS84)
    spec = tile.spec
    total_bbox = spec.bbox
    
    # Calculate the extent of this specific tile
    x_min, x_max = total_bbox.X
    y_min, y_max = total_bbox.Y
    
    # Calculate tile dimensions
    tile_width = (x_max - x_min) / spec.size[1]
    tile_height = (y_max - y_min) / spec.size[2]
    
    # Calculate this tile's extent
    tile_x_min = x_min + tile.x * tile_width
    tile_x_max = tile_x_min + tile_width
    tile_y_min = y_min + tile.y * tile_height
    tile_y_max = tile_y_min + tile_height
    
    tile_extent = Extent(X=(tile_x_min, tile_x_max), Y=(tile_y_min, tile_y_max))
    
    # Project if needed
    if crs == spec.crs
        return tile_extent
    else
        return project_extent(tile_extent, spec.crs, crs)
    end
end

function Extents.extent(tile::CustomTile, crs::WebMercator)
    spec = tile.spec
    total_bbox = spec.bbox
    
    # Calculate the extent of this specific tile
    x_min, x_max = total_bbox.X
    y_min, y_max = total_bbox.Y
    
    # Calculate tile dimensions
    tile_width = (x_max - x_min) / spec.size[1]
    tile_height = (y_max - y_min) / spec.size[2]
    
    # Calculate this tile's extent
    tile_x_min = x_min + tile.x * tile_width
    tile_x_max = tile_x_min + tile_width
    tile_y_min = y_min + tile.y * tile_height
    tile_y_max = tile_y_min + tile_height
    
    tile_extent = Extent(X=(tile_x_min, tile_x_max), Y=(tile_y_min, tile_y_max))
    
    # Project if needed
    if crs == spec.crs
        return tile_extent
    else
        return project_extent(tile_extent, spec.crs, crs)
    end
end

function Extents.extent(grid::CustomTileGrid, crs::WGS84)
    if crs == grid.spec.crs
        return grid.spec.bbox
    else
        return project_extent(grid.spec.bbox, grid.spec.crs, crs)
    end
end

function Extents.extent(grid::CustomTileGrid, crs::WebMercator)
    if crs == grid.spec.crs
        return grid.spec.bbox
    else
        return project_extent(grid.spec.bbox, grid.spec.crs, crs)
    end
end

# GeoInterface compatibility
function GeoInterface.extent(tile::CustomTile, crs::Union{WGS84, WebMercator})
    return Extents.extent(tile, crs)
end

function GeoInterface.extent(grid::CustomTileGrid, crs::Union{WGS84, WebMercator})
    return Extents.extent(grid, crs)
end

"""
    create_raster_tiles(bbox::Extent, raster_size::Tuple{Int,Int}, tile_size::Tuple{Int,Int}, 
                       crs::CoordinateReferenceSystemFormat=wgs84, zoom::Int=0)

Create a TileGridSpec for tiling a raster dataset.

# Arguments
- `bbox`: The bounding box of the raster
- `raster_size`: The size of the raster in pixels (width, height)
- `tile_size`: The desired tile size in pixels (width, height)
- `crs`: The coordinate reference system (default: wgs84)
- `zoom`: The zoom level to assign (default: 0)

# Returns
A TileGridSpec that divides the raster into tiles of approximately tile_size pixels.
"""
function create_raster_tiles(bbox::Extent, raster_size::Tuple{Int,Int}, 
                           tile_size::Tuple{Int,Int}, 
                           crs::CoordinateReferenceSystemFormat=wgs84,
                           zoom::Int=0)
    # Calculate number of tiles needed
    n_tiles_x = ceil(Int, raster_size[1] / tile_size[1])
    n_tiles_y = ceil(Int, raster_size[2] / tile_size[2])
    
    return TileGridSpec(bbox, zoom, (n_tiles_x, n_tiles_y), crs)
end