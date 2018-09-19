# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/Materials.jl/blob/master/LICENSE

using FEMBase, Materials, FEMMaterials, Test

@testset "Test FEMMaterials.jl" begin
    @testset "test simulator" begin
        include("test_simulator.jl")
    end
    @testset "test mechanical material solver" begin
        include("test_mecamatso.jl")
    end
end
