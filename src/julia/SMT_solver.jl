using Z3
# CodeGen functions are now in the same scope, no need to import

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
    # Use codegen backend to create a boolean variable for this norm
    backend = SMT2Backend(ctx, s)
    smt_expr = code_gen(backend, norm)
    
    # Assert that this norm holds (is true)
    add(s, smt_expr.z3_expr)
    
    # TODO: Add constraints based on Hohfeldian position
    # For example, if this is a Duty, add constraints about the correlative Right
    # O_holds axiom — already in core, just reference
end

# Translate a document with bindings to SMT
function to_smt_with_bindings(ir::DocumentIR, bindings::Vector{Binding})::Solver
    ctx = Context()
    s = Solver(ctx)
    backend = SMT2Backend(ctx, s)
    
    # Filter non-skipped norms
    active_norms = filter(n -> !n.skipped, ir.norms)
    
    # Add core axioms
    add_core_axioms!(s, ctx, active_norms)
    
    # Add abstract norms from the document
    for norm in active_norms
        add_norm!(s, ctx, norm)
    end
    
    # Add concrete bindings using codegen backend helper
    for binding in bindings
        add_binding_to_solver!(backend, binding)
    end
    
    return s
end
