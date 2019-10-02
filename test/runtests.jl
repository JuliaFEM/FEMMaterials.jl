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
    @testset "test ideal plastic material model with shear strain" begin
        include("test_idealplastic_shear.jl")
    end
    @testset "test chaboche material model" begin
        include("test_chaboche.jl")
    end
    @testset "test chaboche material model with shear strain" begin
        include("test_chaboche_shear.jl")
    end
    """
    @testset "test viscoplastic" begin
        include("test_viscoplastic.jl")
    end
    """
end
