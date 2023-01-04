module MapTiles

    import Logging, Parameters, ProgressMeter
    import HTTP, ImageMagick, ProtoBuf
    import RecipesBase

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
        xlims --> (0, szx * (1 + basemap.xmax - basemap.xmin))
        ylims --> (0, szy * (1 + basemap.ymax - basemap.ymin))
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
        img = Matrix{T}(undef, sy*tilesizey, sx*tilesizex)
        Logging.@info(string("Requesting ", sx, " x ", sy, " tiles"))
        ProgressMeter.@showprogress for x in xmin:xmax, y in ymin:ymax
            px = tilesizex * (x - xmin); py = tilesizey * (y - ymin)
            img[py .+ (1:tilesizey), px .+ (1:tilesizex)] =
                fetchrastertile(provider, x, y, z)
        end
        BaseMap(img, z,
            min(xmin, xmax), max(xmin, xmax),
            min(ymin, ymax), max(ymin, ymax),
            (tilesizey, tilesizex)
        )
    end
end
