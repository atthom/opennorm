using CommonMark    # markdown parsing
using Z3            # SMT solving
using HTTP          # OpenFisca API
using JSON3         # JSON serialization
using Test          # scenario assertion testing
# PyCall if needed for direct OpenFisca Python integration


include("exceptions.jl")
include("structures.jl")
include("parser.jl")
include("SMT_solver.jl")

# Helper function to count taxons in a taxonomy tree
function count_taxons(taxon::Taxon{T}) where {T<:TaxonomyEnum}
    if isempty(taxon.name)
        return 0
    end
    count = 1
    for child in taxon.children
        count += count_taxons(child)
    end
    return count
end

function validate_document(path::String)
    """
    Parse and validate an OpenNorm document using SMT solver.
    Returns (document, solver, is_satisfiable)
    """
    # Parse the document
    println("Parsing document: $path")
    
    local document
    try
        document = parse_document(path)
    catch e
        if e isa OpenNormException
            # Display the error message without stacktrace for all OpenNorm errors
            showerror(stdout, e)
            println()
            exit(1)
        else
            # Re-throw unexpected exceptions
            rethrow(e)
        end
    end
    
    # Display document info
    println("\n=== Document Info ===")
    println("Title: ", document.manifest.title)
    println("Package: ", document.manifest.package)
    println("Version: ", document.manifest.version)
    
    # Count norms from this document vs imported
    local_norms = filter(n -> n.package == document.manifest.package, document.norms)
    imported_norms = filter(n -> n.package != document.manifest.package, document.norms)
    
    println("Norms in this document: ", length(local_norms))
    println("Norms from imports: ", length(imported_norms))
    println("Total norms: ", length(document.norms))
    
    # Count taxonomy entities
    println("\n=== Taxonomy Info ===")
    total_entities = count_taxons(document.entityTaxonomy)
    total_roles = count_taxons(document.actorTaxonomy)
    total_actions = count_taxons(document.actionTaxonomy)
    total_objects = count_taxons(document.objectTaxonomy)
    
    println("Entity taxonomy: ", total_entities, " entities (from imports)")
    println("Role taxonomy: ", total_roles, " roles (from imports)")
    println("Action taxonomy: ", total_actions, " actions (from imports)")
    println("Object taxonomy: ", total_objects, " objects (from imports)")
    
    if total_entities + total_roles + total_actions + total_objects > 0
        println("\nNote: This document defines no local taxonomies.")
        println("      All taxonomies are inherited from imported frameworks.")
    end
    
    # Translate to SMT
    println("\n=== Translating to SMT ===")
    solver, contradictions = to_smt(document)
    
    # Show SMT assertions
    assertions = Z3.assertions(solver)
    println("Total Z3 assertions: ", length(assertions))
    println("  (includes ", length(document.norms), " norm variables + internal constraints)")
    
    # Only show norm list if there are no contradictions
    if isempty(contradictions)
        println("\n--- Norms from this document (", document.manifest.package, ") ---")
        for (i, norm) in enumerate(local_norms)
            # Get position name
            pos_name = if norm.Hohfeld == Right
                "Right"
            elseif norm.Hohfeld == Duty
                "Duty"
            elseif norm.Hohfeld == NoRight
                "No-Right"
            elseif norm.Hohfeld == Privilege
                "Privilege"
            elseif norm.Hohfeld == Power
                "Power"
            elseif norm.Hohfeld == Liability
                "Liability"
            elseif norm.Hohfeld == Disability
                "Disability"
            elseif norm.Hohfeld == Immunity
                "Immunity"
            else
                "Unknown"
            end
            
            println("  $i. holds_$(norm.package)_$(norm.ref_id)")
            println("     Hohfeldian Position: ", pos_name)
            println("     Relationship: ", norm.actor.name, " → ", norm.action.name, " → ", norm.object.name, " → ", norm.counterparty.name)
        end
    end
    
    # Check satisfiability
    println("\n=== Checking Satisfiability ===")
    println("Running Z3 SMT solver...")
    result = check(solver)
    
    # Z3 returns CheckResult enum (sat, unsat, or unknown)
    result_str = string(result)
    if result_str == "sat"
        println("✓ Document is SATISFIABLE")
        println("  The ", length(document.norms), " norms are logically consistent - no contradictions found")
        println("  Z3 solver verified all norms can be true simultaneously")
        println("\n  Explanation:")
        println("  - Each of the ", length(document.norms), " norms is represented as a Z3 boolean variable")
        println("  - Z3 created ", length(assertions), " total assertions (norms + internal constraints)")
        println("  - Z3 found a satisfying assignment where all norms hold")
        println("  - This means the legal document is internally consistent")
    elseif result_str == "unsat"
        println("✗ Document is UNSATISFIABLE")
        
        # Display detected contradictions
        if !isempty(contradictions)
            for contr in contradictions
                println("\n  ⚠️  CONTRADICTION DETECTED (Jural Opposites)")
                println("  ═══════════════════════════════════════════")
                println("  Norm 1: #$(contr.norm1_ref)")
                println("    $(contr.norm1_text)")
                println("    Position: $(contr.norm1_pos)")
                println()
                println("  Norm 2: #$(contr.norm2_ref)")
                println("    $(contr.norm2_text)")
                println("    Position: $(contr.norm2_pos)")
                println()
                println("  Explanation:")
                println("    $(contr.norm1_pos) and $(contr.norm2_pos) are Hohfeldian opposites.")
                println("    The norms are related through taxonomy subsumption:")
                println("      - $(contr.norm1_actor) ⊇ $(contr.norm2_actor)")
                println("      - $(contr.norm1_action) ⊇ $(contr.norm2_action)")
                println("      - $(contr.norm1_object) ⊇ $(contr.norm2_object)")
                println("    This creates a logical contradiction.")
            end
        end
    else
        println("? Satisfiability is UNKNOWN")
        println("  Z3 could not determine satisfiability")
        println("  (This may happen with complex constraints or timeouts)")
    end
    
    return (document, solver, result)
end

function opennorm(path::String)
    """
    Main entry point for OpenNorm validation.
    """
    doc, solver, result = validate_document(path)
    
    # Return validation result
    return string(result) == "sat"
end

# Example usage
#if abspath(PROGRAM_FILE) == @__FILE__
#    println("=== OpenNorm Validator ===\n")
#    is_valid = opennorm("./licences/mit.strict.md")
#    println("\n=== Final Result ===")
#    println(is_valid ? "✓ Document is valid" : "✗ Document has issues")
#end

#is_valid = opennorm("./documents/licences/mit.strict.md")
#is_valid = opennorm("./documents/tests/test_subsumption.md")
#is_valid = opennorm("./test_contradiction.md")
#is_valid = opennorm("./french_tax_code.md")
is_valid = opennorm("./documents/articles/CGI.Art.156.opennorm.md")
