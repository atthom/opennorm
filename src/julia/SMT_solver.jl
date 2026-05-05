using Z3

# Create a unique holds predicate for a norm
# Returns a Z3 boolean variable representing this normative relationship
function create_holds_var(ctx::Context, norm::Norm)
    # Create a unique name for this holds variable
    var_name = "holds_$(norm.package)_$(norm.ref_id)"
    return BoolVar(var_name, ctx)
end

# Add core Hohfeldian axioms to the solver
# Returns a list of detected contradictions
function add_core_axioms!(s::Solver, ctx::Context, norms::Vector{Norm})
    # Add Hohfeldian axioms: opposites and correlatives
    contradictions = []
    
    for i in 1:length(norms)
        for j in (i+1):length(norms)
            norm1 = norms[i]
            norm2 = norms[j]
            
            # Check if these norms are related (considering taxonomy hierarchy)
            if norms_are_related(norm1, norm2)
                # Check for contradictory positions (opposites)
                if are_opposites(norm1.Hohfeld, norm2.Hohfeld)
                    # Get position names using the helper function
                    pos1_name = position_name(norm1.Hohfeld)
                    pos2_name = position_name(norm2.Hohfeld)
                    
                    # Store contradiction info for later reporting
                    push!(contradictions, (
                        norm1_ref = norm1.ref_id,
                        norm1_pos = pos1_name,
                        norm1_actor = norm1.actor.name,
                        norm1_action = norm1.action.name,
                        norm1_object = norm1.object.name,
                        norm1_text = norm1.text,
                        norm2_ref = norm2.ref_id,
                        norm2_pos = pos2_name,
                        norm2_actor = norm2.actor.name,
                        norm2_action = norm2.action.name,
                        norm2_object = norm2.object.name,
                        norm2_text = norm2.text
                    ))
                    
                    # Add constraint: these cannot both be true
                    false_const = BoolVal(false, ctx)
                    add(s, false_const)
                end
            elseif are_correlative_norms(norm1, norm2)
                # Norms are correlatives (using helper function)
                println("  Detected CORRELATIVE positions:")
                println("    - $(norm1.ref_id) ($(norm1.Hohfeld)): $(norm1.actor.name) → $(norm1.counterparty.name)")
                println("    - $(norm2.ref_id) ($(norm2.Hohfeld)): $(norm2.actor.name) → $(norm2.counterparty.name)")
                println("  These positions are correlative (one implies the other)")
                
                # TODO: Add constraint: if one is true, the other must be true
                # For now, we just detect them
            end
        end
    end
    
    return contradictions
end

function to_smt(ir::DocumentIR)
    ctx = Context()
    s = Solver(ctx)
    
    # Filter non-skipped norms
    active_norms = filter(n -> !n.skipped, ir.norms)
    
    # Add core axioms with contradiction detection
    contradictions = add_core_axioms!(s, ctx, active_norms)
    
    # TODO: Add taxonomy constraints
    # for node in ir.nodes
    #     if node isa TaxonomySubtype && !node_skipped(node)
    #         add_subtype!(s, ctx, node)
    #     end
    # end
    
    # Add norms — skip excluded norms
    for norm in active_norms
        add_norm!(s, ctx, norm)
    end
    
    return (s, contradictions)
end

function add_norm!(s::Solver, ctx::Context, norm::Norm)
    # Create a boolean variable for this norm
    holds_var = create_holds_var(ctx, norm)
    
    # Assert that this norm holds (is true)
    add(s, holds_var)
    
    # TODO: Add constraints based on Hohfeldian position
    # For example, if this is a Duty, add constraints about the correlative Right
    # O_holds axiom — already in core, just reference
end

# Encode a Hohfeldian Position to SMT
encode_position(ctx::Context, pos::Position) = position_name(pos)

# Encode any Taxon to SMT using multiple dispatch
function encode_taxon(ctx::Context, taxon::Taxon{T}) where {T<:TaxonomyEnum}
    # Encode as the taxon name string
    return taxon.name
end

# Encode any ConcreteEntity to SMT using multiple dispatch
function encode_taxon(ctx::Context, entity::ConcreteEntity)
    # Encode as a constant with the entity's name
    return mk_const(ctx, Symbol(entity.name))
end

# Add a concrete binding to the solver
function add_binding!(s::Solver, ctx::Context, binding::Binding)
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

# Translate a document with bindings to SMT
function to_smt_with_bindings(ir::DocumentIR, bindings::Vector{Binding})::Solver
    ctx = Context()
    s = Solver(ctx)
    
    # Add core axioms
    add_core_axioms!(s, ctx)
    
    # Add abstract norms from the document
    for norm in ir.norms
        if !norm.skipped
            add_norm!(s, ctx, norm)
        end
    end
    
    # Add concrete bindings
    for binding in bindings
        add_binding!(s, ctx, binding)
    end
    
    return s
end
