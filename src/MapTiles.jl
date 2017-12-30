module MapTiles

    import Parameters, Requests, ImageMagick, ProgressMeter

    include("providers.jl")
    include("utils.jl")

    mutable struct Map{T}
        img::Matrix{T}
        zoom::Int
        xmin::Int
        ymin::Int
        tilesize::Tuple{Int,Int}
    end

    """
    Fetch map tiles composing a box at a given zoom level, and
    return the assembled image.
    """
    function fetchmap(minlat, minlon, maxlat, maxlon, z;
            provider::AbstractProvider = OpenStreetMapProvider(variant="standard")
        )
        x0, y0, x1, y1 = tilebox(minlat, minlon, maxlat, maxlon, z)
        x0, y0, x1, y1 = correctbox(x0, y0, x1, y1,z)
        sx, sy = boxsize(provider, x0, y0, x1, y1)
        tmptile = fetchtile(provider,x0,y0,z)
        tilesizey, tilesizex = size(tmptile)
        img = Matrix{eltype(tmptile)}(sy*tilesizey,sx*tilesizex)
        ProgressMeter.@showprogress for x in x0:x1, y in y0:y1
            px = tilesizex * (x - x0); py = tilesizey * (y - y0)
            img[1+(py:(py+tilesizey-1)),1+(px:(px+tilesizex-1))] =
                fetchtile(provider,x,y,z)
        end
        xmin = min(x0, x1); ymin = min(y0, y1)
        Map(img, z, xmin, ymin, (tilesizey, tilesizex))
    end

end
