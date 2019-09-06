using FEMBase
using Tensors

# The following functions do nothing for 1 point elements (Dirichlet boundary conditions)
material_preprocess_analysis!(material::Nothing, element::Element{Poi1}, ip, time) = nothing
material_postprocess_analysis!(material::Nothing, element::Element{Poi1}, ip, time) = nothing
material_preprocess_increment!(material::Nothing, element::Element{Poi1}, ip, time) = nothing
material_postprocess_increment!(material::Nothing, element::Element{Poi1}, ip, time) = nothing
material_preprocess_iteration!(material::Nothing, element::Element{Poi1}, ip, time) = nothing
material_postprocess_iteration!(material::Nothing, element::Element{Poi1}, ip, time) = nothing

function update_ip!(material::MFrontMaterial, ip, time)
    variables = fieldnames(typeof(material.variables))
    for variable in variables
        FEMBase.update!(ip, String(variable), time => copy(getfield(material.variables, variable)))
    end

    drivers = fieldnames(typeof(material.drivers)) 
    for driver in drivers
        FEMBase.update!(ip, String(driver), time => copy(getfield(material.drivers, driver)))
    end 
end

"""
Initializes integration point `ip` for data storage of both `variables` and `drivers` at simulation start `time`.
"""
material_preprocess_analysis!(material::MFrontMaterial, element, ip, time) = update_ip!(material, ip, time)

"""
Initializes integration point `ip` for data storage of both `variables` and `drivers` at simulation start `time`.
Updates external variables, e.g. temperature, stored in `ip` to material
"""
function material_preprocess_increment!(material::MFrontMaterial, element, ip, time)
    values = element("external_variables", ip, time)
    material.external_variables = MFrontExternalVariableState(material.external_variables.names, values)
    return nothing
end

"""
Updates ddrivers that are iterated by the global solver over the increment
"""
function material_preprocess_iteration!(material::MFrontMaterial, element, ip, time)
    gradu = element("displacement", ip, time, Val{:Grad})
    strain = 0.5*(gradu + gradu')
    strainvec = [strain[1,1], strain[2,2], strain[3,3],
                 2.0*strain[1,2], 2.0*strain[2,3], 2.0*strain[1,3]]
    dstrain = strainvec - material.drivers.strain
    material.ddrivers = MFrontDriverState(strain = dstrain)
    return nothing
end

"""
Updates the converged state (variables += dvariables, parameters += dparameters, drivers += ddrivers)
and resets the increments to (dvariables = 0, dparameters = 0, [ddrivers = 0]).
"""
function material_postprocess_increment!(material::MFrontMaterial, element, ip, time)
    update_material!(material)
    update_ip!(material, ip, time)
    return nothing
end

material_postprocess_iteration!(material::MFrontMaterial, element, ip, time) = nothing
material_postprocess_analysis!(material::MFrontMaterial, element, ip, time) = nothing
