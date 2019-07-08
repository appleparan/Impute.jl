module Impute

using IterTools
using Statistics
using StatsBase
using Tables: Tables, materializer, istable

import Base.Iterators: drop

export impute, impute!, chain, chain!, drop, drop!, interp, interp!, ImputeError

function __init__()
    sym = join(["chain", "chain!", "drop", "drop!", "interp", "interp!"], ", ", " and ")

    @warn(
        """
        The following symbols will not be exported in future releases: $sym.
        Please qualify your calls with `Impute.<method>(...)` or explicitly import the symbol.
        """
    )

    @warn(
        """
        The default limit for all impute functions will be 1.0 going forward.
        If you depend on a specific threshold please pass in an appropriate `AbstractContext`.
        """
    )

    @warn(
        """
        All matrix imputation methods will be switching to the JuliaStats column-major convention
        (e.g., each column corresponds to an observation, and each row corresponds to a variable).
        """
    )
end

"""
    ImputeError{T} <: Exception

Is thrown by `impute` methods when the limit of imputable values has been exceeded.

# Fields
* msg::T - the message to print.
"""
struct ImputeError{T} <: Exception
    msg::T
end

Base.showerror(io::IO, err::ImputeError) = println(io, "ImputeError: $(err.msg)")

include("context.jl")
include("imputors.jl")

const global imputation_methods = Dict{Symbol, Type}(
    :drop => DropObs,
    :dropobs => DropObs,
    :dropvars => DropVars,
    :interp => Interpolate,
    :fill => Fill,
    :locf => LOCF,
    :nocb => NOCB,
)

include("deprecated.jl")

let
    for (k, v) in imputation_methods
        local typename = nameof(v)
        local f = k
        local f! = Symbol(k, :!)

        # NOTE: The
        @eval begin
            $f(data; kwargs...) = impute($typename(; _extract_context_kwargs(kwargs...)...), data)
            $f!(data; kwargs...) = impute!($typename(; _extract_context_kwargs(kwargs...)...), data)
            $f(; kwargs...) = data -> impute($typename(; _extract_context_kwargs(kwargs...)...), data)
            $f!(; kwargs...) = data -> impute!($typename(; _extract_context_kwargs(kwargs...)...), data)
        end
    end
end

end  # module
