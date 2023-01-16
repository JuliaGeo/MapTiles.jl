using TileProviders
using Documenter

DocMeta.setdocmeta!(TileProviders, :DocTestSetup, :(using TileProviders); recursive=true)

makedocs(;
    modules=[TileProviders],
    authors="Rafael Schouten <rafaelschouten@gmail.com>",
    repo="https://github.com/JuliaGeo/TileProviders.jl/blob/{commit}{path}#{line}",
    sitename="TileProviders.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaGeo.github.io/TileProviders.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaGeo/TileProviders.jl",
    devbranch="main",
)
