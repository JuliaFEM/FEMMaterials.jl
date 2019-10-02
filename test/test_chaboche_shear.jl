# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/Materials.jl/blob/master/LICENSE

using FEMMaterials, Tensors, Test

analysis, problem, element, bc_elements, ip = get_one_element_material_analysis(:Chaboche)
update!(element, "E", 200.0e3)
update!(element, "nu", 0.3)
update!(element, "R0", 100.0)
update!(element, "Kn", 10.0)
update!(element, "nn", 20.0)
update!(element, "C1", 0.0)
update!(element, "D1", 100.0)
update!(element, "C2", 0.0)
update!(element, "D2", 1000.0)
update!(element, "Q", 0.0)
update!(element, "b", 0.1)

times = [0.0]
loads = [0.0]
dt = 0.5
E = 200.0e3
nu = 0.3
G = 0.5*E/(1+nu)
syield = 100.0
# vm = sqrt(3)*G*ga | ea = ga
ea = 2*syield/(sqrt(3)*G)
# Go to elastic border
push!(times, times[end]+dt)
push!(loads, loads[end] + ea*dt)
 # Proceed to plastic flow
push!(times, times[end]+dt)
push!(loads, loads[end] + ea*dt)
 # Reverse direction
push!(times, times[end]+dt)
push!(loads, loads[end] - ea*dt)
 # Continue and pass yield criterion
push!(times, times[end]+dt)
push!(loads, loads[end] - 2*ea*dt)
loading = ShearStrainLoading(times, loads)
update_bc_elements!(bc_elements, loading)

analysis.properties.t1 = maximum(times)
run!(analysis)
stresses = zeros(length(times), 6)
for (i,t) in zip(1:length(times), times)
    stresses[i,:] = tovoigt(ip("stress", t))
    @test isapprox(stresses[i,[1,2,3,4,6]], zeros(5); atol=1e-6)
end
s31 = stresses[:,5]
eeqs = [ip("cumeq", t) for t in times]

@test isapprox(s31[2], syield/sqrt(3.0))
@test isapprox(s31[3]*sqrt(3.0), syield + 10.0*((eeqs[3]-eeqs[2])/dt)^(1.0/20.0); rtol=1e-2)
@test isapprox(s31[4], s31[3]-G*ea*dt)
@test isapprox(s31[5]*sqrt(3.0), -(syield + 10.0*((eeqs[5]-eeqs[4])/dt)^(1.0/20.0)); rtol=1e-2)
