# Taxonomy-Based Validation
# W020-W022: Action complementarity, cross-action contradictions, role hierarchy consistency

using AbstractTrees

"""
    TaxonomyValidationResult

Result of a taxonomy-based validation check.
"""
struct TaxonomyValidationResult
    passed::Bool
    warning_code::Union{Nothing, String}
    message::String
    norm_refs::Vector{String}
    taxon_names::Vector{String}
end

"""
    get_sibling_taxons(taxon::Taxon{T}) -> Vector{Taxon{T}}

Get all sibling taxons (children of the same parent).
"""
function get_sibling_taxons(taxon::Taxon{T}) where {T}
    if isnothing(taxon.parent)
        return Taxon{T}[]
    end
    
    # Return all children of parent except this taxon
    return filter(t -> t.name != taxon.name, taxon.parent.children)
end

"""
    get_all_descendants(taxon::Taxon{T}) -> Vector{Taxon{T}}

Get all descendant taxons recursively.
"""
function get_all_descendants(taxon::Taxon{T}) where {T}
    descendants = Taxon{T}[]
    
    for child in taxon.children
        push!(descendants, child)
        append!(descendants, get_all_descendants(child))
    end
    
    return descendants
end

"""
    get_ancestor_chain(taxon::Taxon{T}) -> Vector{Taxon{T}}

Get the chain of ancestors from taxon to root.
"""
function get_ancestor_chain(taxon::Taxon{T}) where {T}
    ancestors = Taxon{T}[]
    current = taxon.parent
    
    while !isnothing(current)
        push!(ancestors, current)
        current = current.parent
    end
    
    return ancestors
end

"""
    check_action_complementarity(norms::Vector{Norm}, action_taxonomy::Taxon{Action}) -> Vector{TaxonomyValidationResult}

W020: Check if related actions (siblings in taxonomy) are all covered by norms.
Warns if some sibling actions have norms but others don't, suggesting incomplete coverage.
"""
function check_action_complementarity(norms::Vector{Norm}, action_taxonomy::Taxon{Action})
    results = TaxonomyValidationResult[]
    
    # Get all action taxons that appear in norms
    actions_in_norms = Set(norm.action.name for norm in norms if !norm.skipped)
    
    # For each action in norms, check if its siblings are also covered
    for norm in norms
        if norm.skipped
            continue
        end
        
        action = norm.action
        siblings = get_sibling_taxons(action)
        
        if isempty(siblings)
            continue
        end
        
        # Check which siblings are not covered
        uncovered_siblings = filter(s -> !(s.name in actions_in_norms), siblings)
        
        # Warn if there are uncovered siblings (meaning this action is covered but not all siblings are)
        if !isempty(uncovered_siblings)
            # Some but not all siblings are covered - potential incompleteness
            sibling_names = [s.name for s in uncovered_siblings]
            
            push!(results, TaxonomyValidationResult(
                false,
                "W020",
                "Action complementarity: Norm $(norm.ref_id) uses action '$(action.name)', " *
                "but related sibling actions are not covered: $(join(sibling_names, ", ")). " *
                "Consider adding norms for these actions or documenting why they're excluded.",
                [norm.ref_id],
                sibling_names
            ))
        end
    end
    
    return results
end

"""
    check_cross_action_contradictions(norms::Vector{Norm}) -> Vector{TaxonomyValidationResult}

W021: Check for semantic conflicts across related actions with identical conditions.
Warns if two norms with related actions (siblings or parent-child) have opposite positions
and identical conditions, suggesting a potential semantic conflict.
"""
function check_cross_action_contradictions(norms::Vector{Norm})
    results = TaxonomyValidationResult[]
    
    # Check all pairs of norms
    for i in 1:length(norms)
        for j in (i+1):length(norms)
            norm1 = norms[i]
            norm2 = norms[j]
            
            # Skip if either is skipped
            if norm1.skipped || norm2.skipped
                continue
            end
            
            # Skip if one is an exception of the other
            if (!isnothing(norm1.excepts) && norm1.excepts == norm2.ref_id) ||
               (!isnothing(norm2.excepts) && norm2.excepts == norm1.ref_id)
                continue
            end
            
            # Check if actions are siblings (share same parent)
            actions_are_siblings = false
            if !isnothing(norm1.action.parent) && !isnothing(norm2.action.parent)
                actions_are_siblings = norm1.action.parent.name == norm2.action.parent.name &&
                                      norm1.action.name != norm2.action.name
            end
            
            if !actions_are_siblings
                continue
            end
            
            # Check if they have the same actor/object/counterparty
            same_relationship = norm1.actor.name == norm2.actor.name &&
                              norm1.object.name == norm2.object.name &&
                              norm1.counterparty.name == norm2.counterparty.name
            
            if !same_relationship
                continue
            end
            
            # Check if positions are opposites
            if !are_opposites(norm1.Hohfeld, norm2.Hohfeld)
                continue
            end
            
            # Check if conditions are identical or very similar
            if same_conditions(norm1, norm2)
                push!(results, TaxonomyValidationResult(
                    false,
                    "W021",
                    "Cross-action contradiction: Norms $(norm1.ref_id) and $(norm2.ref_id) " *
                    "have opposite positions ($(position_name(norm1.Hohfeld)) vs $(position_name(norm2.Hohfeld))) " *
                    "on related actions ('$(norm1.action.name)' and '$(norm2.action.name)') " *
                    "with identical conditions. This may indicate a semantic conflict.",
                    [norm1.ref_id, norm2.ref_id],
                    [norm1.action.name, norm2.action.name]
                ))
            end
        end
    end
    
    return results
end

"""
    check_role_hierarchy_consistency(norms::Vector{Norm}, role_taxonomy::Taxon{Role}) -> Vector{TaxonomyValidationResult}

W022: Check if prohibitions on parent roles unintentionally apply to child roles.
Warns if a prohibition on a parent role might affect child roles without explicit exceptions.
"""
function check_role_hierarchy_consistency(norms::Vector{Norm}, role_taxonomy::Taxon{Role})
    results = TaxonomyValidationResult[]
    
    # Find all prohibitions (NoRight, Disability)
    prohibitions = filter(n -> !n.skipped && n.Hohfeld in [NoRight, Disability], norms)
    
    for prohibition in prohibitions
        actor = prohibition.actor
        
        # Get all descendant roles
        descendants = get_all_descendants(actor)
        
        if isempty(descendants)
            continue
        end
        
        # Check if there are any exceptions for descendant roles
        has_exceptions = false
        for norm in norms
            if !isnothing(norm.excepts) && norm.excepts == prohibition.ref_id
                # Check if this exception is for a descendant role
                if norm.actor.name in [d.name for d in descendants]
                    has_exceptions = true
                    break
                end
            end
        end
        
        if !has_exceptions
            descendant_names = [d.name for d in descendants]
            
            push!(results, TaxonomyValidationResult(
                false,
                "W022",
                "Role hierarchy: Prohibition $(prohibition.ref_id) applies to role '$(actor.name)', " *
                "which has child roles: $(join(descendant_names, ", ")). " *
                "The prohibition may unintentionally apply to these child roles. " *
                "Consider adding explicit exceptions if child roles should be allowed.",
                [prohibition.ref_id],
                descendant_names
            ))
        end
    end
    
    return results
end

"""
    run_taxonomy_validation(ir::DocumentIR) -> (action_issues, cross_action_issues, role_issues)

Run all taxonomy-based validation checks (W020-W022).
Returns three vectors of TaxonomyValidationResults.
"""
function run_taxonomy_validation(ir::DocumentIR)
    # Filter non-skipped norms
    active_norms = filter(n -> !n.skipped, ir.norms)
    
    # W020: Action complementarity
    action_issues = check_action_complementarity(active_norms, ir.actionTaxonomy)
    
    # W021: Cross-action contradictions
    cross_action_issues = check_cross_action_contradictions(active_norms)
    
    # W022: Role hierarchy consistency
    role_issues = check_role_hierarchy_consistency(active_norms, ir.actorTaxonomy)
    
    return (action_issues, cross_action_issues, role_issues)
end

"""
    report_taxonomy_validation_results(action_issues, cross_action_issues, role_issues)

Print a formatted report of taxonomy validation results.
"""
function report_taxonomy_validation_results(action_issues, cross_action_issues, role_issues)
    total_issues = length(action_issues) + length(cross_action_issues) + length(role_issues)
    
    if total_issues == 0
        println("✓ All taxonomy validation checks passed")
        return
    end
    
    if !isempty(action_issues)
        println("\n⚠ Action Complementarity Issues (W020):")
        for result in action_issues
            println("  [$(result.warning_code)] $(result.message)")
            println("    Norms: $(join(result.norm_refs, ", "))")
            println("    Uncovered actions: $(join(result.taxon_names, ", "))")
        end
    end
    
    if !isempty(cross_action_issues)
        println("\n⚠ Cross-Action Contradictions (W021):")
        for result in cross_action_issues
            println("  [$(result.warning_code)] $(result.message)")
            println("    Norms: $(join(result.norm_refs, ", "))")
            println("    Actions: $(join(result.taxon_names, ", "))")
        end
    end
    
    if !isempty(role_issues)
        println("\n⚠ Role Hierarchy Consistency Issues (W022):")
        for result in role_issues
            println("  [$(result.warning_code)] $(result.message)")
            println("    Norms: $(join(result.norm_refs, ", "))")
            println("    Affected child roles: $(join(result.taxon_names, ", "))")
        end
    end
    
    println("\nTotal taxonomy warnings: $total_issues")
end