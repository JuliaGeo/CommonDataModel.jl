using Documenter: Documenter, makedocs, deploydocs
using AbstractDatasets: AbstractDatasets

makedocs(;
    modules=[AbstractDatasets],
    repo="https://github.com/JuliaGeo/AbstractDatasets.jl/blob/{commit}{path}#{line}",
    sitename="AbstractDatasets.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://juliageo.github.io/AbstractDatasets.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaGeo/AbstractDatasets.jl",
)
