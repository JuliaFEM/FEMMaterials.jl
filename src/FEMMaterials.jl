module FEMMaterials

using Materials, FEMBase, LinearAlgebra, SparseArrays, Tensors

# Material simulator to solve global system and run standard one element tests
include("mecamatso.jl")
export get_one_element_material_analysis, AxialStrainLoading, ShearStrainLoading, update_bc_elements!

# Material point simulator to study material behavior in single integration point
include("simulator.jl")
export Simulator

# tovoigt method for arrays
Tensors.tovoigt(x::Array{T, 2}) where T = [x[1,1], x[2,2], x[3,3], x[2,3], x[1,3], x[1,2]]

material_preprocess_increment!(material::M, element, ip, time) where {M<:AbstractMaterial} = nothing
material_postprocess_analysis!(material::M, element, ip, time) where {M<:AbstractMaterial} = nothing
material_postprocess_increment!(material::M, element, ip, time) where {M<:AbstractMaterial} = nothing
material_postprocess_iteration!(material::M, element, ip, time) where {M<:AbstractMaterial} = nothing

function update_ip!(material::M, ip, time) where {M<:AbstractMaterial}
    variables = fieldnames(typeof(material.variables))
    for variable in variables
        update!(ip, String(variable), time => copy(getfield(material.variables, variable)))
    end

    drivers = fieldnames(typeof(material.drivers))
    for driver in drivers
        update!(ip, String(driver), time => copy(getfield(material.drivers, driver)))
    end
end

# Copying to ip's the duplicate data?
function material_preprocess_analysis!(material::M, element, ip, time) where {M<:AbstractMaterial}
    update_ip!(material, ip, time)
    # Read parameter values
    expr = [element(String(p), ip, time) for p in fieldnames(typeof(material.parameters))]
    material.parameters = typeof(material.parameters)(expr...)
end

function material_preprocess_iteration!(material::M, element, ip, time) where {M<:AbstractMaterial}
    gradu = element("displacement", ip, time, Val{:Grad})
    strain = SymmetricTensor{2,3, Float64}((i,j) -> 0.5*(gradu[i,j]+gradu[j,i]))
    # Check for vector or tensor form needs to be implemented later
    dstrain = strain - material.drivers.strain
    #@info("time = $time, dstrain = $dstrain")
    material.ddrivers.strain = dstrain
    return nothing
end

material_preprocess_analysis!(material::M, element::Element{Poi1}, ip, time) where {M<:AbstractMaterial} = nothing
material_postprocess_analysis!(material::M, element::Element{Poi1}, ip, time) where {M<:AbstractMaterial} = nothing
material_preprocess_increment!(material::M, element::Element{Poi1}, ip, time) where {M<:AbstractMaterial} = nothing
material_postprocess_increment!(material::M, element::Element{Poi1}, ip, time) where {M<:AbstractMaterial} = nothing
material_preprocess_iteration!(material::M, element::Element{Poi1}, ip, time) where {M<:AbstractMaterial} = nothing
material_postprocess_iteration!(material::M, element::Element{Poi1}, ip, time) where {M<:AbstractMaterial} = nothing

function material_preprocess_increment!(material::M, element, ip, time) where {M<:AbstractMaterial}
    # Update time increment
    dtime = time - material.drivers.time
    material.ddrivers.time = dtime
    # Update parameters
    expr = [element(String(p), ip, time) - getfield(material.parameters, p) for p in fieldnames(typeof(material.parameters))]
    material.dparameters = typeof(material.dparameters)(expr...)
    return nothing
end

function material_postprocess_increment!(material::M, element, ip, time) where {M<:AbstractMaterial}
    update_material!(material)
    # Store history data to integration points
    update_ip!(material, ip, time)
end

end
