using SWCForecastBase
using Documenter

DocMeta.setdocmeta!(SWCForecastBase, :DocTestSetup, :(using SWCForecastBase); recursive=true)

makedocs(;
    modules=[SWCForecastBase],
    authors="okatsn <okatsn@gmail.com> and contributors",
    repo="https://github.com/okatsn/SWCForecastBase.jl/blob/{commit}{path}#{line}",
    sitename="SWCForecastBase.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://okatsn.github.io/SWCForecastBase.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/okatsn/SWCForecastBase.jl",
    devbranch="main",
)
