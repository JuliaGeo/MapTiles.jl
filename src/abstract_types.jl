# Abstract types for tiles and tile grids
abstract type AbstractTile end
abstract type AbstractTileGrid end

# Interface functions for AbstractTile
"""
    GeoInterface.crs(tile::AbstractTile)

Get the coordinate reference system of a tile.
"""
GeoInterface.crs(tile::AbstractTile) = tile.crs

"""
    x(tile::AbstractTile)

Get the x index of a tile.
"""
x(tile::AbstractTile) = tile.x

"""
    y(tile::AbstractTile)

Get the y index of a tile.
"""
y(tile::AbstractTile) = tile.y

"""
    z(tile::AbstractTile)

Get the z (zoom) level of a tile.
"""
z(tile::AbstractTile) = tile.z

"""
    zoom(tile::AbstractTile)

Get the zoom level of a tile. Alias for `z(tile)`.
"""
zoom(tile::AbstractTile) = z(tile)

"""
    bounds(tile::AbstractTile)

Get the bounding box of a tile in its native CRS.
"""
bounds(tile::AbstractTile) = extent(tile, GeoInterface.crs(tile))

"""
    bounds(tile::AbstractTile, target_crs)

Get the bounding box of a tile projected to the target CRS.
"""
bounds(tile::AbstractTile, target_crs::CoordinateReferenceSystemFormat) = extent(tile, target_crs)

# Interface functions for AbstractTileGrid
"""
    GeoInterface.crs(tilegrid::AbstractTileGrid)

Get the coordinate reference system of a tile grid.
"""
GeoInterface.crs(tilegrid::AbstractTileGrid) = tilegrid.crs

"""
    zoom(tilegrid::AbstractTileGrid)

Get the zoom level of a tile grid.
"""
zoom(tilegrid::AbstractTileGrid) = tilegrid.z

"""
    bounds(tilegrid::AbstractTileGrid)

Get the bounding box of a tile grid in its native CRS.
"""
bounds(tilegrid::AbstractTileGrid) = extent(tilegrid, GeoInterface.crs(tilegrid))

"""
    bounds(tilegrid::AbstractTileGrid, target_crs)

Get the bounding box of a tile grid projected to the target CRS.
"""
bounds(tilegrid::AbstractTileGrid, target_crs::CoordinateReferenceSystemFormat) = extent(tilegrid, target_crs)