
"""
    Provider

    Provider(url; name=nothing, maxzoom=18, attribution="")

Defines the parameters of a base layer tile provider, such as `OSM`, `Esri` etc.

`Provider` can also be defined manually for custome tile providers.

# Arguments

- `url`: URL tile path, e.g. "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"

# Keywords
- `name`: A `Symbol` name for the provider, or `nothing`

# Example

Manually define an Open Street Map provider.

```julia
using Blink, Leaflet

```julia
url = "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
provider = Leaflet.Provider(url)

w = Blink.Window()
body!(w, Leaflet.Map(; provider, zoom=3, height=1000))
"""
struct Provider
    url::String
    options::Dict{Symbol,Any}
end
function Provider(url::String;
    name::Union{Symbol,Nothing}=nothing, maxzoom=18, attribution="",
)
    options = Dict{Symbol,Any}(:maxZoom => maxzoom, :attribution => attribution)
    Provider{name}(url, options)
end

url(provider::Provider) = provider.url
options(provider::Provider) = provider.options

_variant_list(variants::NamedTuple) = _variant_list(keys(variants))
_variant_list(variants) =
    string("Options for `variant` are: \n", join(string.(Ref("- `:"), variants, '`'), "\n"))

function _checkin(variant, variants)
    if !(variant in keys(variants))
        throw(ArgumentError("`variant` must be one of $(keys(variants)), got $variant"))
    end
end

"""
    geturl(provider::Provider, x::Integer, y::Integer, z::Integer)

Replace `x`, `y` and `z` in the provider url.

If the provider options have keys other than `:maxZoom` and `:attribution`
they will also be replaced.

We follow the behaviour of Leaflet.js so their provider urls work without
modification in `Provider`.
"""
function geturl(provider::Provider, x::Integer, y::Integer, z::Integer)
    ops = options(provider)
    z > ops[:maxZoom] && throw(ArgumentError("z is larger than maxZoom"))
    replacements = [
        "{s}" => string(""), # TODO handle subdomains
        "{x}" => string(Int(x)), 
        "{y}" => string(Int(y)), 
        "{z}" => string(Int(z)), 
    ]
    foreach(keys(ops), values(ops)) do key, val
        if !(key in (:attributes, :maxZoom))
            push!(replacements, string('{', key, '}') => string(val))
        end
    end
    return replace(url(provider), replacements...)
end

function _handle_apikey(k, v) 
    hasapikey = map(values(v)) do d
        _hasapikey!(d)
    end |> any
    return hasapikey, _keyword_docs(hasapikey, k)
end

function _hasapikey!(d)
    if haskey(d, :apikey)
        delete!(d, :apikey)
        true
    else
        false
    end
end

function _keyword_docs(hasapikey, k)
    if hasapikey
        """
        ## Keywords
        
        - `apikey`: Your API key for the $k service.
        """
    else
        ""
    end
end

# Automate the definition of providers retrieved from 
# https://raw.githubusercontent.com/geopandas/xyzservices/main/provider_sources/leaflet-providers-parsed.json
# by parsing them to Julia functions that generate a `Provider`
let
    provider_file = joinpath(dirname(@__FILE__), "leaflet-providers-parsed.json")
    provider_dict = copy(JSON3.read(read(provider_file)))
    for (k, v) in provider_dict
        @show k
        k == :_meta && continue
        if first(values(v)) isa Dict 
            hasapikey, keyword_docs = _handle_apikey(k, v)
            variants = keys(v)
            @eval begin
                docstring = let
                    typ = $(QuoteNode(k))
                    options = $v
                    attribution = map(d -> d[:attribution], values(options)) |> first
                    keyword_docs = $keyword_docs
                    variants = $variants
                    """
                        $typ(variant)

                    [`Provider`](@ref) for $typ tiles.

                    $attribution

                    Arguments

                    - `variant`: $variants, with a default of $(first(variants)).

                    $keyword_docs
                    """
                end
                @doc docstring
                function $k(variant::Symbol=$(QuoteNode(first(variants))))#; $(hasapikey ? :apikey : Symbol("")))
                    options = $v
                    variant in keys(options) || throw(ArgumentError("variant must be from $(keys(options)), got $variant"))
                    Provider(options[variant][:url], options[variant])
                end

                export $k
            end
        else
            # hasapikey, keyword_docs = _keyword_docs(_hasapikey!(v), k)
            @eval begin
                typ = $(QuoteNode(k))
                attribution = $(v[:attribution])
                # keyword_docs = $keyword_docs
                """
                    $typ()

                [`Provider`](@ref) for $typ tiles.

                $attribution

                """
                function $k() 
                    options = $v
                    Provider(options[:url], options)
                end

                export $k
            end
        end
    end
end
