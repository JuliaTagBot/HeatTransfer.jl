# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/HeatTransfer.jl/blob/master/LICENSE

"""
    Heat transfer problems for JuliaFEM.

# Problem types

- `PlaneHeat` for 2d problems

# Fields used in formulation

- `thermal conductivity`
- `heat source`
- `heat flux`

"""
module HeatTransfer

using FEMBase
import FEMBase: get_unknown_field_name, assemble_elements!

type PlaneHeat <: FieldProblem
end

function get_unknown_field_name(::Problem{PlaneHeat})
    return "temperature"
end

function assemble_elements!{B}(problem::Problem{PlaneHeat}, assembly::Assembly,
                               elements::Vector{Element{B}}, time::Float64)

    bi = BasisInfo(B)
    ndofs = length(bi)
    Ke = zeros(ndofs, ndofs)
    fe = zeros(ndofs)

    for element in elements
        fill!(Ke, 0.0)
        fill!(fe, 0.0)
        for ip in get_integration_points(element)
            J, detJ, N, dN = element_info!(bi, element, ip, time)
            s = ip.weight * detJ
            k = element("thermal conductivity", ip, time)
            Ke += s * k*dN'*dN
            if haskey(element, "heat source")
                f = element("heat source", ip, time)
                fe += s * N'*f
            end
        end
        gdofs = get_gdofs(problem, element)
        add!(assembly.K, gdofs, gdofs, Ke)
        add!(assembly.f, gdofs, fe)
    end

end

function assemble_elements!{B<:Union{Seg2,Seg3}}(problem::Problem{PlaneHeat},
                                                 assembly::Assembly,
                                                 elements::Vector{Element{B}},
                                                 time::Float64)

    bi = BasisInfo(B)
    ndofs = length(bi)
    fe = zeros(ndofs)

    for element in elements
        fill!(fe, 0.0)
        for ip in get_integration_points(element)
            J, detJ, N, dN = element_info!(bi, element, ip, time)
            s = ip.weight * detJ
            if haskey(element, "heat flux")
                g = element("heat flux", ip, time)
                fe += s * N'*g
            end
        end
        gdofs = get_gdofs(problem, element)
        add!(assembly.f, gdofs, fe)
    end

end

export PlaneHeat

end
