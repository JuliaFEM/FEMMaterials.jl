# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMMaterials.jl/blob/master/LICENSE

# # 3D Beam with ideal plastic material model from Materials.jl

using JuliaFEM, FEMMaterials, Materials, FEMBase, LinearAlgebra, Plots
import FEMMaterials: Continuum3D, MecaMatSo
pkg_dir = dirname(dirname(pathof(FEMMaterials)))

# ## Let's read the discretized geometry and create boundary conditions
#
# File `plactic_beam.inp` is created with 3rd party meshing tool.
# File contains surface sets `BC1`, `BC2` and `PRESSURE` as well
# element set `Body1`
mesh = abaqus_read_mesh(joinpath(pkg_dir,"examples","data_3dbeam","plastic_beam.inp"))
beam_elements = create_elements(mesh, "Body1")
bc_elements_1 = create_nodal_elements(mesh, "BC1")
bc_elements_2 = create_nodal_elements(mesh, "BC2")
trac_elements = create_surface_elements(mesh, "PRESSURE")

for j in 1:3
    update!(bc_elements_1, "displacement $j", 0.0)
end
update!(bc_elements_2, "displacement 1", 0.0)
update!(bc_elements_2, "displacement 2", 0.0)
update!(trac_elements, "surface pressure", 0.0 => 0.00)
update!(trac_elements, "surface pressure", 1.0 => 2.70)
trac = Problem(Continuum3D, "traction", 3)
bc = Problem(Dirichlet, "fix displacement", 3, "displacement")
add_elements!(trac, trac_elements)
add_elements!(bc, bc_elements_1)
add_elements!(bc, bc_elements_2)

# ## Next, we set the material properties for each element set
#
# In this example we only have the one element set `Body1` in variable `beam_elements`

update!(beam_elements, "youngs_modulus", 200.0e3)
update!(beam_elements, "poissons_ratio", 0.3)
update!(beam_elements, "yield_stress", 100.0)

beam = Problem(Continuum3D, "plastic beam", 3)
beam.properties.material_model = :IdealPlastic
add_elements!(beam, beam_elements)


# ## And next, we setup the analysis
#
# `t0`, `t1`, and `dt` are the start time, end time, and time step respectively.

analysis = Analysis(MecaMatSo, "solve problem")
analysis.properties.max_iterations = 50
analysis.properties.t0 = 0.0
analysis.properties.t1 = 1.0
analysis.properties.dt = 0.05

# ## Writing the results needs to be setup as well

xdmf = Xdmf("3dbeam_results_output"; overwrite=true)
add_results_writer!(analysis, xdmf)

# ## Finally, adding the problems together and running the analysis
#
# All earlier defined problems are added together. Also result file need to be
# closed to flush everything from the writing buffer to the file.
add_problems!(analysis, beam, trac, bc)
run!(analysis)
close(xdmf)


# ## The first post-processing step is to calculate maximum von Mises stresses
#
# `vmis` contains all integration points stresses and `vmis_` just the maximum.
# Let's plot the maximum von Mises stress as a function of time

tim = 0.0:0.05:1.0
vmis_ = []
for t in tim
    vmis = []
    for element in beam_elements
        for ip in get_integration_points(element)
            s11, s22, s33, s12, s23, s31 = ip("stress", t)
            push!(vmis, sqrt(1/2*((s11-s22)^2 + (s22-s33)^2 + (s33-s11)^2 + 6*(s12^2+s23^2+s31^2))))
        end
    end
    push!(vmis_, maximum(vmis))
end
plot(tim,vmis_)
#-
png("max_vonmises_stress_as_a_function_of_time")

# ![max_vonmises_stress_as_a_function_of_time][vonmises]
# [vonmises]: https://raw.githubusercontent.com/JuliaFEM/FEMMaterials.jl/master/notebooks/max_vonmises_stress_as_a_function_of_time.png


# ## The second post-processing step is to collect displacements
#
# Here as an example node number 96 second degree of freedom displacement is
# extracted.

u2_96 = []
for t in tim
    push!(u2_96, beam("displacement", t)[96][2])
end
plot(tim,u2_96)
#-
png("node_96_displacement_as_a_function_of_time")

# ![node_96_displacement_as_a_function_of_time][displacement]
# [displacement]: https://raw.githubusercontent.com/JuliaFEM/FEMMaterials.jl/master/notebooks/node_96_displacement_as_a_function_of_time.png
