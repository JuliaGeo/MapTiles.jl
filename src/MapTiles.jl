module MapTiles

    import Parameters, Requests, ImageMagick

    include("providers.jl")
    include("utils.jl")

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
        for x in x0:x1, y in y0:y1
            px = tilesizex * (x - x0); py = tilesizey * (y - y0)
            img[1+(py:(py+tilesizey-1)),1+(px:(px+tilesizex-1))] =
                fetchtile(provider,x,y,z)
        end
        img
    end

end
