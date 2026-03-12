# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Running Tests
```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

### Running a Single Test
```bash
julia --project=. test/runtests.jl
```

### Building the Package
```bash
julia --project=. -e 'using Pkg; Pkg.build()'
```

### Installing Dependencies
```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## Architecture Overview

MapTiles.jl is a Julia package for working with tiled web maps (slippy maps). The codebase has a focused architecture:

1. **Core Module** (`src/MapTiles.jl`): The main module that exports `Tile` and `TileGrid` types and includes the tiles implementation.

2. **Tiles Implementation** (`src/tiles.jl`): Contains all the core functionality:
   - **Coordinate Reference Systems**: Defines `WGS84` and `WebMercator` types for coordinate system handling
   - **Projection Functions**: `project()` and `project_extent()` for converting between WGS84 (lon/lat) and Web Mercator coordinates
   - **Tile Type**: Represents a single map tile with x, y, and z (zoom) indices
   - **TileGrid Type**: Represents a collection of tiles covering a geographic area
   - **Extent Functions**: Methods to get bounding boxes of tiles in different coordinate systems

3. **Key Design Patterns**:
   - Uses Julia's multiple dispatch heavily for handling different coordinate systems
   - Integrates with GeoInterface.jl for standardized geospatial operations
   - Constants like `R2D`, `RE`, `CE` define Earth parameters for projection calculations
   - Epsilon values (`EPSILON`, `LL_EPSILON`) handle floating-point precision issues

4. **Dependencies**:
   - `GeoInterface`: For standard geospatial interfaces
   - `Extents`: For bounding box operations
   - `GeoFormatTypes`: For coordinate reference system formats

The package focuses on tile index calculations and coordinate transformations, leaving tile downloading and rendering to complementary packages like TileProviders.jl and Tyler.jl.