# ============================================================================
# Validation Logic
# ============================================================================

"""
    ValidationError

Struct to hold validation error information.
"""
struct ValidationError
    term::String
    taxonomy_type::String
    norm_id::String
    position::String
    norm_text::String
end

"""
    validate_norms_terms(norms, roles, actions, objects)

Validate that all terms used in norms exist in the appropriate taxonomies.
Returns a vector of validation errors instead of throwing.
"""
function validate_norms_terms(norms::Vector{Norm}, roles::Taxon{Role}, actions::Taxon{Action}, objects::Taxon{Object})
    errors = ValidationError[]
    
    for norm in norms
        # Get the norm text from the global dictionary
        norm_text = get(NORM_TEXTS, norm.ref_id, "")
        
        # Validate actor (Role taxonomy)
        if !isempty(norm.actor.name) && !term_exists_in_taxonomy(roles, norm.actor.name)
            push!(errors, ValidationError(norm.actor.name, "Role", norm.ref_id, "actor", norm_text))
        end
        
        # Validate action (Action taxonomy)
        if !isempty(norm.action.name) && !term_exists_in_taxonomy(actions, norm.action.name)
            push!(errors, ValidationError(norm.action.name, "Action", norm.ref_id, "action", norm_text))
        end
        
        # Validate object (Object taxonomy)
        if !isempty(norm.object.name) && !term_exists_in_taxonomy(objects, norm.object.name)
            push!(errors, ValidationError(norm.object.name, "Object", norm.ref_id, "object", norm_text))
        end
        
        # Validate counterparty (Role taxonomy)
        if !isempty(norm.counterparty.name) && !term_exists_in_taxonomy(roles, norm.counterparty.name)
            push!(errors, ValidationError(norm.counterparty.name, "Role", norm.ref_id, "counterparty", norm_text))
        end
    end
    
    return errors
end

"""
    print_validation_report(errors::Vector{ValidationError})

Print a comprehensive validation report.
"""
function print_validation_report(errors::Vector{ValidationError})
    if isempty(errors)
        return
    end
    
    println(stderr, "\n═══════════════════════════════════════════════════════════════")
    println(stderr, "❌ VALIDATION REPORT - Missing Taxonomy Terms")
    println(stderr, "═══════════════════════════════════════════════════════════════\n")
    
    # Group errors by taxonomy
    by_taxonomy = Dict{String, Vector{ValidationError}}()
    for err in errors
        if !haskey(by_taxonomy, err.taxonomy_type)
            by_taxonomy[err.taxonomy_type] = ValidationError[]
        end
        push!(by_taxonomy[err.taxonomy_type], err)
    end
    
    # Print summary
    println(stderr, "Summary:")
    println(stderr, "  Total missing terms: ", length(errors))
    for taxonomy in sort(collect(keys(by_taxonomy)))
        tax_errors = by_taxonomy[taxonomy]
        unique_terms = length(unique(e.term for e in tax_errors))
        println(stderr, "  - $taxonomy: $unique_terms unique term(s) missing")
    end
    println(stderr)
    
    # Print detailed breakdown by taxonomy
    for taxonomy in sort(collect(keys(by_taxonomy)))
        tax_errors = by_taxonomy[taxonomy]
        println(stderr, "─────────────────────────────────────────────────────────────────")
        println(stderr, "Missing terms in $taxonomy taxonomy:")
        println(stderr, "─────────────────────────────────────────────────────────────────")
        
        # Group by term to show all norms using each term
        by_term = Dict{String, Vector{ValidationError}}()
        for err in tax_errors
            if !haskey(by_term, err.term)
                by_term[err.term] = ValidationError[]
            end
            push!(by_term[err.term], err)
        end
        
        for term in sort(collect(keys(by_term)))
            term_errors = by_term[term]
            println(stderr, "\n  Term: \"$term\"")
            println(stderr, "  Used in $(length(term_errors)) norm(s):")
            for err in term_errors
                println(stderr, "    - $(err.norm_id) ($(err.position))")
            end
        end
        println(stderr)
    end
    
    println(stderr, "═══════════════════════════════════════════════════════════════")
    println(stderr, "Suggested actions:")
    println(stderr, "  1. Add missing terms to the appropriate taxonomies")
    println(stderr, "  2. Check for typos in the norm definitions")
    println(stderr, "  3. Verify terms are in the correct taxonomy")
    println(stderr, "═══════════════════════════════════════════════════════════════\n")
end