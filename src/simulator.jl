# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/Materials.jl/blob/master/LICENSE

using Materials, Tensors

dummyel = Element(Hex8, (1, 2, 3, 4, 5, 6, 7, 8))
dummyip = first(get_integration_points(dummyel))
mutable struct Simulator
    stresses :: Vector{Vector{Float64}}
    strains :: Vector{Vector{Float64}}
    times :: Vector{Float64}
    material :: M where {M<:AbstractMaterial}
end

function Simulator(material)
    return Simulator([],[],[],material)
end

function initialize!(simulator, strains, times)
    simulator.strains = strains
    simulator.times = times
    return nothing
end

function run!(simulator)
    material = simulator.material
    times = simulator.times
    strains = simulator.strains
    t_n = times[1]
    strain_n = strains[1]
    push!(simulator.stresses, copy(tovoigt(material.variables.stress)))
    for i in 2:length(times)
        strain = strains[i]
        t = times[i]
        dstrain = strain - strain_n
        dt = t - t_n
        material.ddrivers.strain = fromvoigt(SymmetricTensor{2,3}, dstrain)
        material.ddrivers.time = dt
        integrate_material!(material)
        material_postprocess_increment!(material, dummyel, dummyip, t)
        push!(simulator.stresses, copy(tovoigt(material.variables.stress)))
        strain_n = strain
        t_n = t
    end
    return nothing
end
