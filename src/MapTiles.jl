module MapTiles

    import Parameters, Requests, ImageMagick, ProgressMeter, RecipesBase, GeoInterface

    mutable struct BaseMap{T}
        img::Matrix{T}
        zoom::Int
        xmin::Int
        ymin::Int
        tilesize::Tuple{Int,Int}
    end

    RecipesBase.@recipe function f(basemap::BaseMap)
        ticks --> nothing
        grid --> false
        aspect_ratio --> 1
        framestyle --> :none
        basemap.img
    end

    include("providers.jl")
    include("utils.jl")

    """
    Fetch map tiles composing a box at a given zoom level, and
    return the assembled image.
    """
    function fetchmap(minlon::Real, minlat::Real, maxlon::Real, maxlat::Real, z::Integer=18;
            maxtiles::Int = 16,
            provider::AbstractProvider = OpenStreetMapProvider(variant="standard")
        )
        xmin, ymin, xmax, ymax = tilebox(minlon, minlat, maxlon, maxlat, z)
        xmin, ymin, xmax, ymax = correctbox(xmin, ymin, xmax, ymax, z)
        sx, sy = boxsize(provider, xmin, ymin, xmax, ymax)
        while sx * sy >= min(maxtiles, provider.maxtiles)
            z -= 1
            xmin, ymin, xmax, ymax = tilebox(minlon, minlat, maxlon, maxlat, z)
            xmin, ymin, xmax, ymax = correctbox(xmin, ymin, xmax, ymax, z)
            sx, sy = boxsize(provider, xmin, ymin, xmax, ymax)
        end
        tmptile = fetchtile(provider, xmin, ymin, z) # fetch a tile for metadata
        tilesizey, tilesizex = size(tmptile)
        img = Matrix{eltype(tmptile)}(sy*tilesizey, sx*tilesizex)
        xmin, xmax, ymin, ymax
        ProgressMeter.@showprogress for x in xmin:xmax, y in ymin:ymax
            px = tilesizex * (x - xmin); py = tilesizey * (y - ymin)
            img[1+(py:(py+tilesizey-1)), 1+(px:(px+tilesizex-1))] =
                fetchtile(provider, x, y, z)
        end
        BaseMap(img, z, min(xmin, xmax), min(ymin, ymax), (tilesizey, tilesizex))
    end

    function project(basemap::BaseMap, geom::GeoInterface.AbstractPoint)
        lon,lat = GeoInterface.coordinates(geom)
        GeoInterface.Point(collect(lonlat2tile(basemap,lon,lat)))
    end

    function project(basemap::BaseMap, geom::GeoInterface.AbstractMultiPoint)
        GeoInterface.MultiPoint([
            collect(lonlat2tile(basemap,lon,lat))
            for (lon,lat) in GeoInterface.coordinates(geom)
        ])
    end

    function project(basemap::BaseMap, geom::GeoInterface.AbstractLineString)
        GeoInterface.LineString([
            collect(lonlat2tile(basemap,lon,lat))
            for (lon,lat) in GeoInterface.coordinates(geom)
        ])
    end

    function project(basemap::BaseMap, geom::GeoInterface.AbstractMultiLineString)
        GeoInterface.MultiLineString([
            [collect(lonlat2tile(basemap,lon,lat)) for (lon,lat) in line]
            for line in GeoInterface.coordinates(geom)
        ])
    end

    function project(basemap::BaseMap, geom::GeoInterface.AbstractPolygon)
        GeoInterface.Polygon([
            [collect(lonlat2tile(basemap,lon,lat)) for (lon,lat) in ring]
            for ring in GeoInterface.coordinates(geom)
        ])
    end

    function project(basemap::BaseMap, geom::GeoInterface.AbstractMultiPolygon)
        GeoInterface.MultiPolygon([[
                [collect(lonlat2tile(basemap,lon,lat)) for (lon,lat) in ring]
                for ring in poly
            ]
            for poly in GeoInterface.coordinates(geom)
        ])
    end

end
