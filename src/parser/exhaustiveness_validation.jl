# Exhaustiveness Validation
# W023: Normative gap detection - identifies situations where no norm covers certain input combinations

using Z3

# Import condition encoding functions
include("condition_smt_encoder.jl")

"""
    ExhaustivenessResult

Result of an exhaustiveness check.
"""
struct ExhaustivenessResult
    passed::Bool
    warning_code::Union{Nothing, String}
    message::String
    gap_description::String
    uncovered_combinations::Vector{Dict{String, Any}}
end

"""
    NormativeTriple

Represents a (actor, action, object) triple that defines a normative relationship.
"""
struct NormativeTriple
    actor::String
    action::String
    object::String
    counterparty::String
end

"""
    extract_normative_triples(norms::Vector{Norm}) -> Set{NormativeTriple}

Extract all unique normative triples from a set of norms.
"""
function extract_normative_triples(norms::Vector{Norm})
    triples = Set{NormativeTriple}()
    
    for norm in norms
        if !norm.skipped
            triple = NormativeTriple(
                norm.actor.name,
                norm.action.name,
                norm.object.name,
                norm.counterparty.name
            )
            push!(triples, triple)
        end
    end
    
    return triples
end

"""
    get_all_taxon_leaves(taxon::Taxon{T}) -> Vector{Taxon{T}}

Get all leaf nodes (nodes with no children) in a taxonomy tree.
"""
function get_all_taxon_leaves(taxon::Taxon{T}) where {T}
    if isempty(taxon.children)
        return [taxon]
    end
    
    leaves = Taxon{T}[]
    for child in taxon.children
        append!(leaves, get_all_taxon_leaves(child))
    end
    
    return leaves
end

"""
    enumerate_possible_triples(actor_taxonomy::Taxon{Role}, action_taxonomy::Taxon{Action}, 
                               object_taxonomy::Taxon{Object}) -> Vector{NormativeTriple}

Enumerate all possible normative triples from taxonomy leaf nodes.
This represents the complete space of possible normative relationships.
"""
function enumerate_possible_triples(actor_taxonomy::Taxon{Role}, 
                                   action_taxonomy::Taxon{Action},
                                   object_taxonomy::Taxon{Object})
    # Get leaf nodes from each taxonomy
    actors = get_all_taxon_leaves(actor_taxonomy)
    actions = get_all_taxon_leaves(action_taxonomy)
    objects = get_all_taxon_leaves(object_taxonomy)
    
    # Generate all combinations
    triples = NormativeTriple[]
    
    for actor in actors
        for action in actions
            for object in objects
                # For simplicity, use same actor as counterparty
                # In a full implementation, we'd enumerate counterparties too
                triple = NormativeTriple(
                    actor.name,
                    action.name,
                    object.name,
                    actor.name  # Simplified
                )
                push!(triples, triple)
            end
        end
    end
    
    return triples
end

"""
    check_triple_coverage(triple::NormativeTriple, norms::Vector{Norm}) -> Bool

Check if a normative triple is covered by at least one norm (considering taxonomy hierarchy).
"""
function check_triple_coverage(triple::NormativeTriple, norms::Vector{Norm})
    for norm in norms
        if norm.skipped
            continue
        end
        
        # Check if norm covers this triple (exact match or subsumption via taxonomy)
        actor_matches = norm.actor.name == triple.actor || 
                       triple.actor in [d.name for d in get_all_descendants(norm.actor)]
        
        action_matches = norm.action.name == triple.action ||
                        triple.action in [d.name for d in get_all_descendants(norm.action)]
        
        object_matches = norm.object.name == triple.object ||
                        triple.object in [d.name for d in get_all_descendants(norm.object)]
        
        counterparty_matches = norm.counterparty.name == triple.counterparty ||
                              triple.counterparty in [d.name for d in get_all_descendants(norm.counterparty)]
        
        if actor_matches && action_matches && object_matches && counterparty_matches
            return true
        end
    end
    
    return false
end

"""
    check_exhaustiveness(ir::DocumentIR; max_gaps::Int=10) -> Vector{ExhaustivenessResult}

W023: Check for normative gaps - situations where no norm covers certain input combinations.
Returns a list of gaps found, limited to max_gaps to avoid overwhelming output.
"""
function check_exhaustiveness(ir::DocumentIR; max_gaps::Int=10)
    results = ExhaustivenessResult[]
    
    # Filter non-skipped norms
    active_norms = filter(n -> !n.skipped, ir.norms)
    
    if isempty(active_norms)
        return results
    end
    
    # Extract covered triples
    covered_triples = extract_normative_triples(active_norms)
    
    # Enumerate possible triples (limited to leaf nodes to keep it manageable)
    possible_triples = enumerate_possible_triples(
        ir.actorTaxonomy,
        ir.actionTaxonomy,
        ir.objectTaxonomy
    )
    
    # Find gaps
    gaps_found = 0
    uncovered = NormativeTriple[]
    
    for triple in possible_triples
        if gaps_found >= max_gaps
            break
        end
        
        # Check if this triple is covered by any norm
        if !check_triple_coverage(triple, active_norms)
            push!(uncovered, triple)
            gaps_found += 1
        end
    end
    
    # Report gaps
    if !isempty(uncovered)
        gap_descriptions = []
        uncovered_dicts = []
        
        for triple in uncovered
            desc = "$(triple.actor) → $(triple.action) → $(triple.object)"
            push!(gap_descriptions, desc)
            
            push!(uncovered_dicts, Dict(
                "actor" => triple.actor,
                "action" => triple.action,
                "object" => triple.object,
                "counterparty" => triple.counterparty
            ))
        end
        
        message = "Exhaustiveness check: Found $(length(uncovered)) normative gaps " *
                 "(showing first $max_gaps). These combinations of actor/action/object " *
                 "are not covered by any norm. This may indicate incomplete specification."
        
        push!(results, ExhaustivenessResult(
            false,
            "W023",
            message,
            join(gap_descriptions, "; "),
            uncovered_dicts
        ))
    end
    
    return results
end

"""
    check_conditions_mutually_exclusive(group_norms::Vector{Norm}, triple::NormativeTriple, ctx::Context) -> Vector{ExhaustivenessResult}

Check if conditions of norms in a group are mutually exclusive (no overlaps).
Returns results for any overlapping condition pairs found.
"""
function check_conditions_mutually_exclusive(group_norms::Vector{Norm}, triple::NormativeTriple, ctx::Context)
    results = ExhaustivenessResult[]
    
    # Check all pairs of norms
    for i in 1:length(group_norms)
        for j in (i+1):length(group_norms)
            norm1 = group_norms[i]
            norm2 = group_norms[j]
            
            # Skip if either has no conditions
            if isempty(norm1.conditions) || isempty(norm2.conditions)
                continue
            end
            
            # Check if conditions can be satisfied simultaneously
            (compatible, model) = check_conditions_compatible(norm1.conditions, norm2.conditions, ctx)
            
            if compatible
                # Conditions overlap - this is a problem
                model_str = isnothing(model) ? "" : "\n    Counterexample: $(model)"
                
                push!(results, ExhaustivenessResult(
                    false,
                    "W023-B-1",
                    "Mutual exclusivity violation: Norms $(norm1.ref_id) and $(norm2.ref_id) " *
                    "can both apply to $(triple.actor) → $(triple.action) → $(triple.object). " *
                    "Their conditions overlap, which may cause ambiguity.$model_str",
                    "$(triple.actor) → $(triple.action) → $(triple.object)",
                    [Dict(
                        "actor" => triple.actor,
                        "action" => triple.action,
                        "object" => triple.object,
                        "norm1" => norm1.ref_id,
                        "norm2" => norm2.ref_id,
                        "overlap_detected" => true,
                        "model" => isnothing(model) ? nothing : string(model)
                    )]
                ))
            end
        end
    end
    
    return results
end

"""
    check_conditions_cover_all_cases(group_norms::Vector{Norm}, triple::NormativeTriple, ctx::Context) -> Union{Nothing, ExhaustivenessResult}

Check if conditions of norms in a group cover all possible cases (exhaustiveness).
Returns a result if a gap is found, nothing if exhaustive.
"""
function check_conditions_cover_all_cases(group_norms::Vector{Norm}, triple::NormativeTriple, ctx::Context)
    # Create SMT context
    smt_ctx = SMTContext(ctx)
    s = Solver(ctx)
    
    # Encode all conditions as a disjunction (OR)
    condition_constraints = []
    for norm in group_norms
        if !isempty(norm.conditions)
            constraint = encode_norm_conditions(norm.conditions, smt_ctx)
            push!(condition_constraints, constraint)
        else
            # If any norm has no conditions, it covers everything
            return nothing
        end
    end
    
    if isempty(condition_constraints)
        return nothing
    end
    
    # Create disjunction: C1 OR C2 OR ... OR Ck
    all_conditions = or(condition_constraints...)
    
    # Check if NOT(C1 OR C2 OR ... OR Ck) is satisfiable
    # If SAT, there's a gap (some case not covered)
    add(s, !all_conditions)
    
    result = check(s)
    
    if result == sat
        # Gap found - get model showing uncovered case
        model = get_model(s)
        model_str = string(model)
        
        return ExhaustivenessResult(
            false,
            "W023-B-2",
            "Exhaustiveness gap: Norms for $(triple.actor) → $(triple.action) → $(triple.object) " *
            "do not cover all possible cases. Some input combinations are not handled by any norm.\n" *
            "    Uncovered case: $model_str",
            "$(triple.actor) → $(triple.action) → $(triple.object)",
            [Dict(
                "actor" => triple.actor,
                "action" => triple.action,
                "object" => triple.object,
                "norm_refs" => [n.ref_id for n in group_norms],
                "gap_detected" => true,
                "uncovered_case" => model_str
            )]
        )
    end
    
    # Conditions are exhaustive
    return nothing
end

"""
    check_condition_exhaustiveness(norms::Vector{Norm}, ctx::Context) -> Vector{ExhaustivenessResult}

W023-B: Check if conditions on norms with the same triple cover all possible cases.
Uses SMT to detect:
1. Overlapping conditions (mutual exclusivity violations)
2. Gaps in condition coverage (exhaustiveness violations)
"""
function check_condition_exhaustiveness(norms::Vector{Norm}, ctx::Context)
    results = ExhaustivenessResult[]
    
    # Group norms by their normative triple
    triple_groups = Dict{NormativeTriple, Vector{Norm}}()
    
    for norm in norms
        if norm.skipped
            continue
        end
        
        triple = NormativeTriple(
            norm.actor.name,
            norm.action.name,
            norm.object.name,
            norm.counterparty.name
        )
        
        if !haskey(triple_groups, triple)
            triple_groups[triple] = Norm[]
        end
        push!(triple_groups[triple], norm)
    end
    
    # For each group with multiple norms, check conditions
    for (triple, group_norms) in triple_groups
        if length(group_norms) <= 1
            continue
        end
        
        # Check if all norms have conditions
        all_have_conditions = all(n -> !isempty(n.conditions), group_norms)
        
        if !all_have_conditions
            # If some norms have no conditions, they cover everything
            # No need to check exhaustiveness, but still check for overlaps
            norms_with_conditions = filter(n -> !isempty(n.conditions), group_norms)
            if length(norms_with_conditions) > 1
                # Check mutual exclusivity among norms with conditions
                append!(results, check_conditions_mutually_exclusive(norms_with_conditions, triple, ctx))
            end
            continue
        end
        
        # All norms have conditions - perform full SMT checks
        
        # 1. Check mutual exclusivity (no overlaps)
        append!(results, check_conditions_mutually_exclusive(group_norms, triple, ctx))
        
        # 2. Check exhaustiveness (no gaps)
        exhaustiveness_result = check_conditions_cover_all_cases(group_norms, triple, ctx)
        if !isnothing(exhaustiveness_result)
            push!(results, exhaustiveness_result)
        end
    end
    
    return results
end

"""
    run_exhaustiveness_validation(ir::DocumentIR; max_gaps::Int=10) -> (triple_gaps, condition_gaps)

Run all exhaustiveness validation checks (W023).
Returns two vectors of ExhaustivenessResults.
"""
function run_exhaustiveness_validation(ir::DocumentIR; max_gaps::Int=10)
    ctx = Context()
    
    # W023: Triple coverage gaps
    triple_gaps = check_exhaustiveness(ir, max_gaps=max_gaps)
    
    # W023-B: Condition exhaustiveness
    condition_gaps = check_condition_exhaustiveness(ir.norms, ctx)
    
    return (triple_gaps, condition_gaps)
end

"""
    report_exhaustiveness_results(triple_gaps, condition_gaps)

Print a formatted report of exhaustiveness validation results.
"""
function report_exhaustiveness_results(triple_gaps, condition_gaps)
    total_issues = length(triple_gaps) + length(condition_gaps)
    
    if total_issues == 0
        println("✓ All exhaustiveness checks passed")
        return
    end
    
    if !isempty(triple_gaps)
        println("\n⚠ Normative Coverage Gaps (W023):")
        for result in triple_gaps
            println("  [$(result.warning_code)] $(result.message)")
            println("    Uncovered combinations:")
            for (i, combo) in enumerate(result.uncovered_combinations)
                if i > 5  # Limit display
                    println("    ... and $(length(result.uncovered_combinations) - 5) more")
                    break
                end
                println("      - $(combo["actor"]) → $(combo["action"]) → $(combo["object"])")
            end
        end
    end
    
    if !isempty(condition_gaps)
        println("\n⚠ Condition Exhaustiveness Issues (W023-B):")
        for result in condition_gaps
            println("  [$(result.warning_code)] $(result.message)")
            println("    Triple: $(result.gap_description)")
            if !isempty(result.uncovered_combinations)
                combo = result.uncovered_combinations[1]
                if haskey(combo, "norm_refs")
                    println("    Affected norms: $(join(combo["norm_refs"], ", "))")
                end
            end
        end
    end
    
    println("\nTotal exhaustiveness warnings: $total_issues")
end