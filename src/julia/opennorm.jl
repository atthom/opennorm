using CommonMark    # markdown parsing (needed by parser.jl)
using AbstractTrees # needed by structures.jl
using Z3            # SMT solving (needed by SMT_solver.jl)

include(joinpath(@__DIR__, "exceptions.jl"))
include(joinpath(@__DIR__, "structures.jl"))
include(joinpath(@__DIR__, "parser.jl"))
include(joinpath(@__DIR__, "SMT_solver.jl"))

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
    Returns (document, solver, result) or nothing on error.
    """
    # Parse the document
    println("Parsing document: $path")

    local document
    try
        document = parse_document(path)
    catch e
        if e isa OpenNormException
            showerror(stdout, e)
            println()
            return nothing
        else
            rethrow(e)
        end
    end

    # Display document info
    println("\n=== Document Info ===")
    println("Title: ", document.manifest.title)
    println("Package: ", document.manifest.package)
    println("Version: ", document.manifest.version)

    # Count norms from this document vs imported
    local_norms  = filter(n -> n.package == document.manifest.package, document.norms)
    imported_norms = filter(n -> n.package != document.manifest.package, document.norms)

    println("Norms in this document: ", length(local_norms))
    println("Norms from imports:     ", length(imported_norms))
    println("Total norms:            ", length(document.norms))

    # Count taxonomy entities
    println("\n=== Taxonomy Info ===")
    total_entities = count_taxons(document.entityTaxonomy)
    total_roles    = count_taxons(document.actorTaxonomy)
    total_actions  = count_taxons(document.actionTaxonomy)
    total_objects  = count_taxons(document.objectTaxonomy)

    println("Entity taxonomy: ", total_entities, " entities")
    println("Role taxonomy:   ", total_roles,    " roles")
    println("Action taxonomy: ", total_actions,  " actions")
    println("Object taxonomy: ", total_objects,  " objects")

    # Translate to SMT
    println("\n=== Translating to SMT ===")
    solver, contradictions = to_smt(document)

    # Show norm list when there are no contradictions
    if isempty(contradictions)
        active_local = filter(n -> !n.skipped, local_norms)
        println("\n--- Norms from this document (", document.manifest.package, ") ---")
        for (i, norm) in enumerate(active_local)
            pos_name = position_name(norm.Hohfeld)
            println("  $i. $(norm.package)_$(norm.ref_id)")
            println("     Hohfeldian Position: ", pos_name)
            println("     Relationship: ", norm.actor.name,
                    " → ", norm.action.name,
                    " → ", norm.object.name,
                    " → ", norm.counterparty.name)
        end
    end

    # Check satisfiability
    println("\n=== Checking Satisfiability ===")
    println("Running Z3 SMT solver...")
    result = check(solver)

    result_str = string(result)
    if result_str == "sat"
        println("✓ Document is SATISFIABLE")
        println("  The ", length(document.norms), " norms are logically consistent — no contradictions found")
        println("  Z3 verified all norms can hold simultaneously")
    elseif result_str == "unsat"
        println("✗ Document is UNSATISFIABLE")

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
    Returns true if the document is satisfiable, false otherwise.
    """
    result = validate_document(path)
    result === nothing && return false
    doc, solver, check_result = result
    return string(check_result) == "sat"
end

# Run on the CGI Article 156 document
is_valid = opennorm("./documents/articles/CGI.Art.156.opennorm.md")
println("\n=== Final Result ===")
println(is_valid ? "✓ Document is valid" : "✗ Document has issues")