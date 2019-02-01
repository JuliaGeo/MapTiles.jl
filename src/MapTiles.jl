module MapTiles

    import Logging, Parameters, ProgressMeter
    import HTTP, ImageMagick, ProtoBuf
    import RecipesBase, GeoInterface

    # include("protobuf/2.1/vector_tile.jl")

    mutable struct BaseMap{T}
        img::Matrix{T}
        zoom::Int
        xmin::Int
        xmax::Int
        ymin::Int
        ymax::Int
        tilesize::Tuple{Int,Int}
    end

    RecipesBase.@recipe function f(basemap::BaseMap)
        szx, szy = basemap.tilesize
        xlim --> (0, szx * (1 + basemap.xmax - basemap.xmin))
        ylim --> (0, szy * (1 + basemap.ymax - basemap.ymin))
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
        Logging.@info(string("Setting zoom to ", z))
        Logging.@info(string("Converting bounding latlon to tiles: ",
            xmin, ",", ymin, ",", xmax, ",", ymax, " (xmin,ymin,xmax,ymax)"
        ))
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
        Logging.@info(string("Tiles: Matrix{",T,"}(", tilesizey, ",", tilesizex, ")"))
        img = Matrix{T}(sy*tilesizey, sx*tilesizex)
        Logging.@info(string("Requesting ", sx, " x ", sy, " tiles"))
        ProgressMeter.@showprogress for x in xmin:xmax, y in ymin:ymax
            px = tilesizex * (x - xmin); py = tilesizey * (y - ymin)
            img[py+(1:tilesizey), px+(1:tilesizex)] =
                fetchrastertile(provider, x, y, z)
        end
        BaseMap(img, z,
            min(xmin, xmax), max(xmin, xmax),
            min(ymin, ymax), max(ymin, ymax),
            (tilesizey, tilesizex)
        )
    end

    function project(
            ::Type{GeoInterface.Point},
            basemap::BaseMap,
            geom::GeoInterface.AbstractGeometry
        )
        lon,lat = GeoInterface.coordinates(geom)
        GeoInterface.Point(collect(lonlat2tile(basemap,lon,lat)))
    end

    function project(
            ::Type{GeoInterface.MultiPoint},
            basemap::BaseMap,
            geom::GeoInterface.AbstractGeometry
        )
        GeoInterface.MultiPoint([
            collect(lonlat2tile(basemap,lon,lat))
            for (lon,lat) in GeoInterface.coordinates(geom)
        ])
    end

    function project(
            ::Type{GeoInterface.LineString},
            basemap::BaseMap,
            geom::GeoInterface.AbstractGeometry
        )
        GeoInterface.LineString([
            collect(lonlat2tile(basemap,lon,lat))
            for (lon,lat) in GeoInterface.coordinates(geom)
        ])
    end

    function project(
            ::Type{GeoInterface.MultiLineString},
            basemap::BaseMap,
            geom::GeoInterface.AbstractGeometry
        )
        GeoInterface.MultiLineString([
            [collect(lonlat2tile(basemap,lon,lat)) for (lon,lat) in line]
            for line in GeoInterface.coordinates(geom)
        ])
    end

    function project(
            ::Type{GeoInterface.Polygon},
            basemap::BaseMap,
            geom::GeoInterface.AbstractGeometry
        )
        GeoInterface.Polygon([
            [collect(lonlat2tile(basemap,lon,lat)) for (lon,lat) in ring]
            for ring in GeoInterface.coordinates(geom)
        ])
    end

    function project(
            ::Type{GeoInterface.MultiPolygon},
            basemap::BaseMap,
            geom::GeoInterface.AbstractGeometry
        )
        GeoInterface.MultiPolygon([[
                [collect(lonlat2tile(basemap,lon,lat)) for (lon,lat) in ring]
                for ring in poly
            ]
            for poly in GeoInterface.coordinates(geom)
        ])
    end

    project(basemap::BaseMap, geom::GeoInterface.AbstractPoint) = 
        project(GeoInterface.Point, basemap, geom)
    project(basemap::BaseMap, geom::GeoInterface.AbstractMultiPoint) = 
        project(GeoInterface.MultiPoint, basemap, geom)
    project(basemap::BaseMap, geom::GeoInterface.AbstractLineString) = 
        project(GeoInterface.LineString, basemap, geom)
    project(basemap::BaseMap, geom::GeoInterface.AbstractMultiLineString) = 
        project(GeoInterface.MultiLineString, basemap, geom)
    project(basemap::BaseMap, geom::GeoInterface.AbstractPolygon) = 
        project(GeoInterface.Polygon, basemap, geom)
    project(basemap::BaseMap, geom::GeoInterface.AbstractMultiPolygon) = 
        project(GeoInterface.MultiPolygon, basemap, geom)

    function project(basemap::BaseMap, geom::GeoInterface.AbstractGeometry)
        gtype = GeoInterface.geotype(geom)
        if gtype == :Point
            return project(GeoInterface.Point, basemap, geom)
        elseif gtype == :MultiPoint
            return project(GeoInterface.MultiPoint, basemap, geom)
        elseif gtype == :LineString
            return project(GeoInterface.LineString, basemap, geom)
        elseif gtype == :MultiLineString
            return project(GeoInterface.MultiLineString, basemap, geom)
        elseif gtype == :Polygon
            return project(GeoInterface.Polygon, basemap, geom)
        else
            @assert gtype == :MultiPolygon
            return project(GeoInterface.MultiPolygon, basemap, geom)
        end
    end

end
