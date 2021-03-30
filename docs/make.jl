push!(LOAD_PATH, "../src/")

using Documenter, AddToField

makedocs(
	sitename = "AddToField.jl",
	pages = Any[
		"Introduction" => "index.md",
		"API" => "api/api.md"])

deploydocs(
    repo = "github.com/pdeffebach/AddToField.jl.git",
    target = "build",
    deps = nothing,
    make = nothing)
