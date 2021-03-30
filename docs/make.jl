push!(LOAD_PATH, "../src/")

using Documenter, AddToField

makedocs(
	sitename = "AddToField.jl",
	pages = Any[
		"Introduction" => "index.md",
		"API" => "api/api.md"],
	format = Documenter.HTML(
		canonical = "https://pdeffebach.github.io/AddToField.jl/stable/"
	))

deploydocs(
    repo = "github.com/pdeffebach/AddToField.jl.git",
    target = "build",
    deps = nothing,
    make = nothing)
