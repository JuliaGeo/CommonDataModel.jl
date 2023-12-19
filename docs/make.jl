using Documenter: Documenter, makedocs, deploydocs
using CommonDataModel
using Literate

Literate.markdown(
    "docs/src/tutorial1.jl","docs/src",
    execute = true,
    documenter = true,
    # page already credits julia and Documenter; having an additional credit
    # does not look nice
    credit = false,
)
# remove datafile
rm("docs/src/sst.day.mean.2023.nc")

makedocs(;
    modules=[CommonDataModel],
    repo="https://github.com/JuliaGeo/CommonDataModel.jl/blob/{commit}{path}#{line}",
    sitename="CommonDataModel.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://juliageo.github.io/CommonDataModel.jl",
        assets=String[],
        footer = "Powered by [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl), [Literate.jl](https://github.com/fredrikekre/Literate.jl) and the [Julia Programming Language](https://julialang.org/)"

    ),
    pages=[
        "Home" => "index.md",
        "Tutorials" => "tutorial1.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaGeo/CommonDataModel.jl",
)
