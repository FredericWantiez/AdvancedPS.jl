using Documenter

# Print `@debug` statements (https://github.com/JuliaDocs/Documenter.jl/issues/955)
if haskey(ENV, "GITHUB_ACTIONS")
    ENV["JULIA_DEBUG"] = "Documenter"
end

using AdvancedPS

DocMeta.setdocmeta!(AdvancedPS, :DocTestSetup, :(using AdvancedPS); recursive=true)

makedocs(;
    sitename="AdvancedPS",
    format=Documenter.HTML(),
    modules=[AdvancedPS],
    pages=["Home" => "index.md", "api.md", "example.md"],
    strict=true,
    checkdocs=:exports,
    doctestfilters=[
        # Older versions will show "0 element Array" instead of "Type[]".
        r"(Any\[\]|0-element Array{.+,[0-9]+})",
        # Older versions will show "Array{...,1}" instead of "Vector{...}".
        r"(Array{.+,\s?1}|Vector{.+})",
        # Older versions will show "Array{...,2}" instead of "Matrix{...}".
        r"(Array{.+,\s?2}|Matrix{.+})",
    ],
)

deploydocs(; repo="github.com/FredericWantiez/AdvancedPS.jl.git", push_preview=true)
