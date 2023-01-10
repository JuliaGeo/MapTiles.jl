
# Adapted from https://github.com/leaflet-extras/leaflet-providers/blob/cc8a10c9aa0ae19c84ccafd1f6b85caca1c68e19/leaflet-providers.js
# Visit `http://leaflet-extras.github.io/leaflet-providers/preview/` to preview different choices.

"""
    Provider

    Provider(url; maxzoom=18, attribution="")
    Provider(url, options)

Defines the parameters of a base layer tile provider, such as `OSM`, `Esri` etc.

`Provider` can also be defined manually for custome tile providers.

# Arguments

- `url`: URL tile path, e.g. "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
- `options`: Dictionary of key/value pairs where the key is a `Symbol`.

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
function Provider(url::String; maxzoom=18, attribution="")
    options = Dict{Symbol,Any}(:maxZoom => maxzoom, :attribution => attribution)
    Provider(url, options)
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
    interpolate_url(provider::Provider, x::Integer, y::Integer, z::Integer)

Replace `x`, `y` and `z` in the provider url.

If the provider options have keys other than `:maxZoom` and `:attribution`
they will also be replaced.

We follow the behaviour of Leaflet.js so their provider urls work without
modification in `Provider`.
"""
function interpolate_url(provider::Provider, x::Integer, y::Integer, z::Integer)
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
             push!(replacements, string('{', key, '}') => val)
        end
    end
    return replace(url(provider), replacements...)
end
