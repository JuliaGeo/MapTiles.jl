using TileProviders
using Documenter

DocMeta.setdocmeta!(TileProviders, :DocTestSetup, :(using TileProviders); recursive=true)

makedocs(;
    modules=[TileProviders],
    authors="Rafael Schouten <rafaelschouten@gmail.com>",
    repo="https://github.com/rafaqz/TileProviders.jl/blob/{commit}{path}#{line}",
    sitename="TileProviders.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://rafaqz.github.io/TileProviders.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/rafaqz/TileProviders.jl",
    devbranch="main",
)
