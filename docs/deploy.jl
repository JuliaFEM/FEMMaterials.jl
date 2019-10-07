# This file is a part of project JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/Materials.jl/blob/master/LICENSE

using Documenter
using FEMMaterials

deploydocs(
    repo = "github.com/JuliaFEM/FEMMaterials.jl.git",
    target = "build",
    deps = nothing,
    make = nothing)
