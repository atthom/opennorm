# SMT2 Translation for SMT Backend
# Translates OpenNorm IR to Z3 SMT constraints

using Z3

# ============================================================================
# NORM TO SMT TRANSLATION
# ============================================================================

"""
    code_gen(::SMT2Backend, norm::Norm)::SMTExpr

Generate a Z3 boolean variable representing whether a norm holds.
Creates a unique variable name based on the norm's package and reference ID.

# Arguments
- `backend::SMT2Backend`: The SMT2 backend instance (contains Z3 context)
- `norm::Norm`: The norm to translate

# Returns
- `SMTExpr`: Wrapped Z3 boolean variable representing this norm
"""
function code_gen(backend::SMT2Backend, norm::Norm)::SMTExpr
    # Create a unique name for this holds variable
    var_name = "holds_$(norm.package)_$(norm.ref_id)"
    z3_var = BoolVar(var_name, backend.ctx)
    return SMTExpr(z3_var)
end

# ============================================================================
# POSITION AND TAXON ENCODING
# ============================================================================

"""
    code_gen(::SMT2Backend, pos::Position)::SMTExpr

Encode a Hohfeldian Position to its string representation for SMT.

# Arguments
- `backend::SMT2Backend`: The SMT2 backend instance
- `pos::Position`: The Hohfeldian position to encode

# Returns
- `SMTExpr`: Wrapped string representation (e.g., "Right", "Duty", "Power")
"""
function code_gen(backend::SMT2Backend, pos::Position)::SMTExpr
    # Return the position name as a string (wrapped in SMTExpr for consistency)
    return SMTExpr(position_name(pos))
end

"""
    code_gen(::SMT2Backend, taxon::Taxon{T}) where {T<:TaxonomyEnum}

Encode a taxonomy node to its string representation for SMT.
Uses the taxon's name as the SMT representation.

# Arguments
- `backend::SMT2Backend`: The SMT2 backend instance
- `taxon::Taxon{T}`: The taxonomy node to encode

# Returns
- `SMTExpr`: Wrapped taxon name
"""
function code_gen(backend::SMT2Backend, taxon::Taxon{T}) where {T<:TaxonomyEnum}
    return SMTExpr(taxon.name)
end

"""
    code_gen(::SMT2Backend, entity::ConcreteEntity)::SMTExpr

Encode a concrete entity to an SMT constant.
Creates a Z3 constant with the entity's name.

# Arguments
- `backend::SMT2Backend`: The SMT2 backend instance
- `entity::ConcreteEntity`: The concrete entity to encode

# Returns
- `SMTExpr`: Wrapped Z3 constant representing the entity
"""
function code_gen(backend::SMT2Backend, entity::ConcreteEntity)::SMTExpr
    z3_const = mk_const(backend.ctx, Symbol(entity.name))
    return SMTExpr(z3_const)
end

# ============================================================================
# BINDING SUPPORT
# ============================================================================

"""
    code_gen(::SMT2Backend, binding::Binding)::SMTExpr

Translate a concrete binding to SMT constraints.
A binding represents a specific instantiation of a norm with concrete entities.

# Arguments
- `backend::SMT2Backend`: The SMT2 backend instance
- `binding::Binding`: The concrete binding to translate

# Returns
- `SMTExpr`: Wrapped Z3 constraint representing the binding

# Details
This function encodes the Hohfeldian position and all concrete entities,
then creates a constraint that the normative relationship holds for these specific entities.
"""
function code_gen(backend::SMT2Backend, binding::Binding)::SMTExpr
    # Encode the Hohfeldian position from the norm
    pos_expr = code_gen(backend, binding.norm.Hohfeld)
    pos = pos_expr.z3_expr  # Extract the string
    
    # Encode concrete entities using multiple dispatch
    actor_expr = code_gen(backend, binding.actor)
    actor = actor_expr.z3_expr
    
    counterparty_expr = code_gen(backend, binding.counterparty)
    counterparty = counterparty_expr.z3_expr
    
    obj_expr = code_gen(backend, binding.object)
    obj = obj_expr.z3_expr
    
    # Encode action from the norm
    action_expr = code_gen(backend, binding.norm.action)
    action = action_expr.z3_expr
    
    # Create the holds constraint
    # This asserts that the specific entities have this normative relationship
    z3_constraint = holds(pos, actor, action, obj, counterparty)
    
    return SMTExpr(z3_constraint)
end

# ============================================================================
# HELPER FUNCTIONS FOR SMT SOLVER INTEGRATION
# ============================================================================

"""
Helper function to add a binding to the solver.
This bridges between the new code_gen interface and the old SMT_solver API.
"""
function add_binding_to_solver!(backend::SMT2Backend, binding::Binding)
    constraint_expr = code_gen(backend, binding)
    add(backend.solver, constraint_expr.z3_expr)
end

"""
Helper function to encode position (for backward compatibility).
"""
function encode_position(backend::SMT2Backend, pos::Position)::String
    expr = code_gen(backend, pos)
    return expr.z3_expr
end

"""
Helper function to encode taxon (for backward compatibility).
"""
function encode_taxon(backend::SMT2Backend, taxon::Union{Taxon, ConcreteEntity})
    expr = code_gen(backend, taxon)
    return expr.z3_expr
end