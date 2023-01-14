abstract type AbstractProvider end

const PROVIDER_DICT = Dict{Function,Vector{Symbol}}()

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
struct Provider <: AbstractProvider
    url::String
    options::Dict{Symbol,Any}
end
function Provider(url::String;
    name::Union{Symbol,Nothing}=nothing, max_zoom=18, attribution="", html_attribution=attribution,
)
    options = Dict{Symbol,Any}(:max_zoom => max_zoom, :attribution => attribution, :html_attribution => html_attribution)
    Provider(url, options)
end

url(provider::AbstractProvider) = provider.url
options(provider::AbstractProvider) = provider.options
min_zoom(provider::Provider) = get(options(provider), :min_zoom, 1)
max_zoom(provider::Provider) = get(options(provider), :max_zoom, 19)

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
function geturl(provider::AbstractProvider, x::Integer, y::Integer, z::Integer)
    ops = options(provider)
    z > max_zoom(provider) && throw(ArgumentError("z is larger than max_zoom"))
    replacements = [
        "{s}" => string(""), # TODO handle subdomains
        "{x}" => string(Int(x)), 
        "{y}" => string(Int(y)), 
        "{z}" => string(Int(z)), 
    ]
    foreach(keys(ops), values(ops)) do key, val
        if !(key in (:attributes, :html_attributes, :name))
            push!(replacements, string('{', key, '}') => string(val))
        end
    end
    return replace(url(provider), replacements...)
end

function _handle_apikey(k, v) 
    hasapikey = map(values(v)) do d
        _hasapikey(d)
    end |> any
    hasaccesstoken = map(values(v)) do d
        _hasaccesstoken(d)
    end |> any
    return hasapikey, hasaccesstoken, _keyword_docs(hasapikey, hasaccesstoken, k)
end

_hasapikey(d) = haskey(d, :apikey)
_hasaccesstoken(d) = haskey(d, :accessToken)

function _keyword_docs(hasapikey, hasaccesstoken, k)
    if hasapikey || hasaccesstoken
        """
        ## Keywords
        
        - `$(hasapikey ? "apikey" : "accesstoken") `: Your API key for the $k service.
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
    provider_dict = JSON3.read(read(provider_file))
    for (k, v) in provider_dict
        k == :_meta && continue
        if first(values(v)) isa JSON3.Object 
            hasapikey, hasaccesstoken, keyword_docs = _handle_apikey(k, v)
            keyword = hasapikey ? :apikey : (hasaccesstoken ? :accesstoken : Symbol(""))
            variants = keys(v)
            contents = quote
                provider_name = $k
                options = $v
                variant in keys(options) || throw(ArgumentError("$provider_name variant must be from $(keys(options)), got $variant"))
                Provider(options[variant][:url], options[variant])
            end
            # Generate the documentation
            docstring = let
                typ = QuoteNode(k)
                options = v
                attribution = map(d -> d[:attribution], values(options)) |> first
                """
                    $typ(variant)

                [`Provider`](@ref) for $typ tiles.

                $attribution

                # Arguments

                - `variant`: $variants, with a default of $(first(variants)).

                $keyword_docs
                """
            end 

            # Generate the function
            if hasapikey || hasaccesstoken
                @eval begin
                    @doc $docstring
                    function $k(variant::Symbol=$(QuoteNode(first(variants))); $keyword)
                        $contents
                    end
                end
            else
                @eval begin
                    @doc $docstring
                    function $k(variant::Symbol=$(QuoteNode(first(variants))))
                        $contents
                    end
                end
            end

            @eval PROVIDER_DICT[$k] = collect($variants)
        else
            hasapikey = _hasapikey(v)
            hasaccesstoken = _hasaccesstoken(v)
            keyword_docs = _keyword_docs(hasapikey, hasaccesstoken, v)
            keyword = hasapikey ? :apikey : (hasaccesstoken ? :accesstoken : Symbol(""))
            contents = quote
                options = $v
                Provider(options[:url], options)
            end
            # Generate the documentation
            docstring = let
                typ = QuoteNode(k)
                attribution = v[:attribution]
                """
                    $typ(variant)

                [`Provider`](@ref) for $typ tiles.

                $attribution

                # Arguments

                $keyword_docs
                """
            end 

            # Generate the function
            if hasapikey || hasaccesstoken
                @eval begin
                    @doc $docstring
                    function $k(; $keyword)
                        $contents
                    end
                end
            else
                @eval begin
                    @doc $docstring
                    function $k()
                        $contents
                    end
                end
            end
            @eval PROVIDER_DICT[$k] = Symbol[]
        end
        @eval export $k
    end
end


# Google is not included above

const _GOOGLE_VARIANTS = (satelite="s", roadmap="m", terrain="p", hybrid="y")

"""
    Google()

[`Provider`](@ref) for base layers from Google maps.

# Arguments

- `variant`: $(keys(_GOOGLE_VARIANTS)), with a default of $first(keys(_GOOGLE_VARIANTS))).
"""
function Google(variant=:satelite)
    _checkin(variant, _GOOGLE_VARIANTS)
    Provider(
        "https://mt1.google.com/vt/lyrs={variant}&x={x}&y={y}&z={z}",
        Dict(
            :max_zoom => 20,
            :attribution => "Google",
            :variant => _GOOGLE_VARIANTS[variant],
        )
    )
end

list_providers() = PROVIDER_DICT
