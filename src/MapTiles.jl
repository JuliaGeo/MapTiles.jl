module MapTiles

    import Logging, Parameters, ProgressMeter
    import Requests, ImageMagick, ProtoBuf
    import RecipesBase, GeoInterface

    include("protobuf/2.1/vector_tile.jl")

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
    function fetchmap(
            minlon::Real, minlat::Real, maxlon::Real, maxlat::Real, z::Integer=18;
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
        Logging.info("Setting zoom to ", z)
        Logging.info("Converting bounding latlon to tiles: ",
            xmin, ",", ymin, ",", xmax, ",", ymax, " (xmin,ymin,xmax,ymax)"
        )
        fetchtiles(xmin, ymin, xmax, ymax, z, maxtiles=maxtiles, provider=provider)
    end

    function fetchtiles(
            xmin::Integer, ymin::Integer, xmax::Integer, ymax::Integer, z::Integer;
            maxtiles::Int = 16,
            provider::AbstractProvider = OpenStreetMapProvider(variant="standard")
        )
        sx, sy = boxsize(provider, xmin, ymin, xmax, ymax)
        tmptile = fetchrastertile(provider, xmin, ymin, z) # fetch a tile for metadata
        T = eltype(tmptile)
        tilesizey, tilesizex = size(tmptile)
        Logging.info("Tiles: Matrix{",T,"}(", tilesizey, ",", tilesizex, ")")
        img = Matrix{T}(sy*tilesizey, sx*tilesizex)
        Logging.info("Requesting ", sx, " x ", sy, " tiles")
        ProgressMeter.@showprogress for x in xmin:xmax, y in ymin:ymax
            px = tilesizex * (x - xmin); py = tilesizey * (y - ymin)
            img[1+(py:(py+tilesizey-1)), 1+(px:(px+tilesizex-1))] =
                fetchrastertile(provider, x, y, z)
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
