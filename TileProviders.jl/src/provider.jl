abstract type AbstractProvider end

const PROVIDER_DICT = Dict{Function,Vector{Symbol}}()

"""
    Provider

    Provider(url; name=nothing, max_zoom=18, attribution="")

Defines the parameters of a base layer tile provider, such as `OSM`, `Esri` etc.

`Provider` can also be defined manually for custom tile providers.

# Arguments

- `url`: URL tile path, e.g. "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"

# Keywords
- `name`: A `Symbol` name for the provider, or `nothing`

# Example

Manually define an OpenStreetMap provider.

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
min_zoom(provider::AbstractProvider)::Int = get(options(provider), :min_zoom, 1)
max_zoom(provider::AbstractProvider)::Int = get(options(provider), :max_zoom, 19)

_variant_list(variants::NamedTuple) = _variant_list(keys(variants))
_variant_list(variants) =
    string("Options for `variant` are: \n", join(string.(Ref("- `:"), variants, '`'), "\n"))

function _checkin(variant, variants)
    if !(variant in keys(variants))
        throw(ArgumentError("`variant` must be one of $(keys(variants)), got $(QuoteNode(variant))"))
    end
end

"""
    geturl(provider::Provider, x::Integer, y::Integer, z::Integer)

Replace `x`, `y` and `z` in the provider url.

If the provider options have keys other than `:max_zoom` and `:attribution`
they will also be replaced.

We follow the behaviour of Leaflet.js so their provider urls work without
modification in `Provider`.
"""
function geturl(provider::AbstractProvider, x::Integer, y::Integer, z::Integer)
    ops = options(provider)
    z > max_zoom(provider) && throw(ArgumentError("z is larger than max_zoom"))
    # Choose a random subdomain
    subdomain = haskey(ops, :subdomains) ? string(rand(ops[:subdomains]), ".") : ""
    replacements = [
        "{s}." => subdomain, # We replace the trailing . in case there is no subdomain
        "{x}" => string(Int(x)),
        "{y}" => string(Int(y)),
        "{z}" => string(Int(z)),
        "{r}" => "",
    ]
    foreach(keys(ops), values(ops)) do key, val
        if !(key in (:attributes, :html_attributes, :name))
            push!(replacements, string('{', key, '}') => string(val))
        end
    end
    return replace(url(provider), replacements...)
end

function _access(d)
    for key in (:apikey, :apiKey, :accessToken, :subscriptionKey, :app_code)
        if hasproperty(d, key)
            return key
        end
    end
    return nothing
end

function _variant_docs(variants)
    """
    # Arguments

    - `variant`: $(join(QuoteNode.(variants), ", ", " and ")), with a default of $(first(variants)).
    """
end

_keyword_docs(::Nothing, name) = ""
function _keyword_docs(keyword, name)
    """
    ## Keywords

    - `$(lowercase(string(keyword)))`: Your API key for the $name service.
    """
end

# Generate the documentation
function _docstring(typ, keyword, attribution, variant_docs, keyword_docs)
    """
    $typ($(variant_docs == "" ? "" : "variant")$(isnothing(keyword) ? "" : "; $(lowercase(string(keyword)))"))

    [`Provider`](@ref) for $typ tiles.

    $attribution

    $variant_docs

    $keyword_docs
    """
end

# Automate the definition of providers retrieved from
# https://raw.githubusercontent.com/geopandas/xyzservices/main/provider_sources/leaflet-providers-parsed.json
# by parsing them to Julia functions that generate a `Provider`
let
    provider_file = joinpath(dirname(@__FILE__), "leaflet-providers-parsed.json")
    provider_dict = JSON3.read(read(provider_file))
    for (name, v) in provider_dict
        name == :_meta && continue
        if first(values(v)) isa JSON3.Object
            keyword = _access(first(values(v)))
            keyword_docs = _keyword_docs(keyword, name)
            variants = keys(v)
            keyword_expr = isnothing(keyword) ? nothing : :(options[$(QuoteNode(keyword))] = $(Symbol(lowercase(string(keyword)))))
            contents = quote
                provider_name = $name
                options = Dict($v)
                variant in keys(options) || throw(ArgumentError("$provider_name variant must be from $(keys(options)), got $variant"))
                $keyword_expr
                Provider(options[variant][:url], options[variant])
            end

            variant_docs = _variant_docs(variants)
            docstring = _docstring(name, keyword, first(map(d -> d[:attribution], values(v))), variant_docs, keyword_docs)

            # Generate the function
            if isnothing(keyword)
                @eval begin
                    @doc $docstring
                    function $name(variant::Symbol=$(QuoteNode(first(variants))))
                        $contents
                    end
                end
            else
                clean_keyword = Symbol(lowercase(string(keyword))) 
                @eval begin
                    @doc $docstring
                    function $name(variant::Symbol; $clean_keyword)
                        $contents
                    end
                end
                @eval $name(; $clean_keyword) = $name($(QuoteNode(first(variants))); $clean_keyword=$clean_keyword)
            end

            @eval PROVIDER_DICT[$name] = collect($variants)
        else
            keyword = _access(v)
            keyword_docs = _keyword_docs(keyword, name)
            keyword_expr = isnothing(keyword) ? nothing : :(options[$(QuoteNode(keyword))] = $(Symbol(lowercase(string(keyword)))))
            contents = quote
                options = Dict($v)
                $keyword_expr
                Provider(options[:url], options)
            end
            docstring = _docstring(name, keyword, v[:attribution], "", keyword_docs)

            # Generate the function
            if isnothing(keyword)
                @eval begin
                    @doc $docstring
                    function $name()
                        $contents
                    end
                end
            else
                @eval begin
                    @doc $docstring
                    function $name(; $(Symbol(lowercase(string(keyword)))))
                        $contents
                    end
                end
            end
            @eval PROVIDER_DICT[$name] = Symbol[]
        end
        @eval export $name
    end
end


# Google is not included above

const _GOOGLE_VARIANTS = (satelite="s", roadmap="m", terrain="p", hybrid="y")

"""
    Google(variant)

[`Provider`](@ref) for base layers from Google maps.

# Arguments

- `variants`: $(keys(_GOOGLE_VARIANTS)...), with a default of $(first(keys(_GOOGLE_VARIANTS)))).
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

PROVIDER_DICT[Google] = collect(keys(_GOOGLE_VARIANTS))

list_providers() = PROVIDER_DICT
