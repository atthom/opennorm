# SMT2 Code Generation
# Translates OpenNorm IR to Z3 SMT constraints for satisfiability checking

using Z3
using ..Structures: Norm, Position, Taxon, ConcreteEntity, TaxonomyEnum, Binding
using ..Structures: position_name

# Backend type already declared in openfisca.jl as SMT2Backend

# ============================================================================
# NORM TO SMT TRANSLATION
# ============================================================================

"""
    generate(::SMT2Backend, ctx::Context, norm::Norm)

Generate a Z3 boolean variable representing whether a norm holds.
Creates a unique variable name based on the norm's package and reference ID.

# Arguments
- `backend::SMT2Backend`: The SMT2 backend instance
- `ctx::Context`: The Z3 context
- `norm::Norm`: The norm to translate

# Returns
- A Z3 boolean variable representing this norm
"""
function generate(::SMT2Backend, ctx::Context, norm::Norm)
    # Create a unique name for this holds variable
    var_name = "holds_$(norm.package)_$(norm.ref_id)"
    return BoolVar(var_name, ctx)
end

# ============================================================================
# POSITION AND TAXON ENCODING
# ============================================================================

"""
    encode_position(ctx::Context, pos::Position)

Encode a Hohfeldian Position to its string representation for SMT.

# Arguments
- `ctx::Context`: The Z3 context (for consistency with other encode functions)
- `pos::Position`: The Hohfeldian position to encode

# Returns
- `String`: The position name (e.g., "Right", "Duty", "Power")
"""
function encode_position(ctx::Context, pos::Position)::String
    return position_name(pos)
end

"""
    encode_taxon(ctx::Context, taxon::Taxon{T}) where {T<:TaxonomyEnum}

Encode a taxonomy node to its string representation for SMT.
Uses the taxon's name as the SMT representation.

# Arguments
- `ctx::Context`: The Z3 context
- `taxon::Taxon{T}`: The taxonomy node to encode

# Returns
- `String`: The taxon name
"""
function encode_taxon(ctx::Context, taxon::Taxon{T}) where {T<:TaxonomyEnum}
    return taxon.name
end

"""
    encode_taxon(ctx::Context, entity::ConcreteEntity)

Encode a concrete entity to an SMT constant.
Creates a Z3 constant with the entity's name.

# Arguments
- `ctx::Context`: The Z3 context
- `entity::ConcreteEntity`: The concrete entity to encode

# Returns
- Z3 constant representing the entity
"""
function encode_taxon(ctx::Context, entity::ConcreteEntity)
    return mk_const(ctx, Symbol(entity.name))
end

# ============================================================================
# BINDING SUPPORT
# ============================================================================

"""
    add_binding!(s::Solver, ctx::Context, backend::SMT2Backend, binding::Binding)

Add a concrete binding to the SMT solver.
Translates a binding (concrete instantiation of a norm) into SMT constraints.

# Arguments
- `s::Solver`: The Z3 solver
- `ctx::Context`: The Z3 context
- `backend::SMT2Backend`: The SMT2 backend instance
- `binding::Binding`: The concrete binding to add

# Details
A binding represents a specific instantiation of a norm with concrete entities.
This function encodes the Hohfeldian position and all concrete entities,
then asserts that the normative relationship holds for these specific entities.
"""
function add_binding!(s::Solver, ctx::Context, backend::SMT2Backend, binding::Binding)
    # Encode the Hohfeldian position from the norm
    pos = encode_position(ctx, binding.norm.Hohfeld)
    
    # Encode concrete entities using multiple dispatch
    actor = encode_taxon(ctx, binding.actor)
    counterparty = encode_taxon(ctx, binding.counterparty)
    obj = encode_taxon(ctx, binding.object)
    
    # Encode action from the norm
    action = encode_taxon(ctx, binding.norm.action)
    
    # Add the concrete binding to the solver
    # This asserts that the specific entities have this normative relationship
    add(s, holds(pos, actor, action, obj, counterparty))
end