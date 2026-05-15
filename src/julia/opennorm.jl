using CommonMark    # markdown parsing (needed by parser module)
using AbstractTrees # needed by structures.jl
using Z3            # SMT solving (needed by SMT_solver.jl)
using Unitful       # dimensional analysis (needed by unit_system.jl)
using YAML          # YAML generation for OpenFisca parameters

# Include structures package (all structure definitions)
include(joinpath(@__DIR__, "structures/structures.jl"))

include(joinpath(@__DIR__, "unit_system.jl"))

# Include type checker (needs UNIT_REGISTRY from unit_system.jl)
include(joinpath(@__DIR__, "type_checker.jl"))

# Include parser package (all parsing functions)
include(joinpath(@__DIR__, "parser/parser.jl"))

# Include codegen package (unified code generation architecture)
include(joinpath(@__DIR__, "codegen/codegen.jl"))

# Include SMT solver (depends on CodeGen for translation)
include(joinpath(@__DIR__, "SMT_solver.jl"))

# Filter types for taxonomy counting operations
abstract type TaxonFilter end

struct AllNodes <: TaxonFilter end

struct AtDepth <: TaxonFilter
    depth::Int
end

struct UnderParent <: TaxonFilter
    parent_name::String
end

struct BySource <: TaxonFilter
    base_package::String
end

struct BySourceUnderParent <: TaxonFilter
    parent_name::String
    base_package::String
end

# Multiple dispatch implementations for counting taxons

# Count all nodes in the taxonomy tree
function count_taxons(taxon::Taxon{T}, filter::AllNodes) where {T<:TaxonomyEnum}
    if isempty(taxon.name)
        return 0
    end
    count = 1
    for child in taxon.children
        count += count_taxons(child, filter)
    end
    return count
end

# Count taxons at a specific depth (0 = root level children)
function count_taxons(taxon::Taxon{T}, filter::AtDepth, current_depth::Int=0) where {T<:TaxonomyEnum}
    if isempty(taxon.name)
        # Root node, count its children
        count = 0
        for child in taxon.children
            count += count_taxons(child, filter, 0)
        end
        return count
    end
    
    if current_depth == filter.depth
        return 1
    end
    
    count = 0
    for child in taxon.children
        count += count_taxons(child, filter, current_depth + 1)
    end
    return count
end

# Count taxons under a specific named parent
function count_taxons(taxon::Taxon{T}, filter::UnderParent) where {T<:TaxonomyEnum}
    if taxon.name == filter.parent_name
        # Found the parent, count its children recursively
        return count_taxons(taxon, AllNodes())
    end
    
    # Search in children
    count = 0
    for child in taxon.children
        count += count_taxons(child, filter)
    end
    return count
end

# Count taxons by source (local vs imported)
function count_taxons(taxon::Taxon{T}, filter::BySource) where {T<:TaxonomyEnum}
    local_count = 0
    imported_count = 0
    
    function count_recursive(node::Taxon{T})
        if !isempty(node.name)
            if node.source == filter.base_package
                local_count += 1
            else
                imported_count += 1
            end
        end
        for child in node.children
            count_recursive(child)
        end
    end
    
    count_recursive(taxon)
    return (local_count, imported_count)
end

# Count taxons by source under a specific named parent
function count_taxons(taxon::Taxon{T}, filter::BySourceUnderParent) where {T<:TaxonomyEnum}
    # Find the parent node first
    function find_parent(node::Taxon{T})
        if node.name == filter.parent_name
            return node
        end
        for child in node.children
            result = find_parent(child)
            if result !== nothing
                return result
            end
        end
        return nothing
    end
    
    parent_node = find_parent(taxon)
    if parent_node === nothing
        return (0, 0)  # Parent not found
    end
    
    # Count by source under this parent
    local_count = 0
    imported_count = 0
    
    function count_recursive(node::Taxon{T})
        if !isempty(node.name)
            if node.source == filter.base_package
                local_count += 1
            else
                imported_count += 1
            end
        end
        for child in node.children
            count_recursive(child)
        end
    end
    
    count_recursive(parent_node)
    return (local_count, imported_count)
end

# Backward compatibility wrappers (delegate to new filter-based implementations)
count_taxons(taxon::Taxon{T}) where {T<:TaxonomyEnum} = count_taxons(taxon, AllNodes())
count_taxons_at_depth(taxon::Taxon{T}, target_depth::Int, current_depth::Int=0) where {T<:TaxonomyEnum} = count_taxons(taxon, AtDepth(target_depth), current_depth)
count_taxons_under(taxon::Taxon{T}, parent_name::String) where {T<:TaxonomyEnum} = count_taxons(taxon, UnderParent(parent_name))
count_taxons_by_source(taxon::Taxon{T}, base_package::String) where {T<:TaxonomyEnum} = count_taxons(taxon, BySource(base_package))
count_taxons_by_source_under(taxon::Taxon{T}, parent_name::String, base_package::String) where {T<:TaxonomyEnum} = count_taxons(taxon, BySourceUnderParent(parent_name, base_package))

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
    println("Imports: ", length(document.manifest.imports), " document(s)")

    # Count norms from this document vs imported
    local_norms  = filter(n -> n.package == document.manifest.package, document.norms)
    imported_norms = filter(n -> n.package != document.manifest.package, document.norms)

    # Count taxonomy entities
    println("\n=== Taxonomy Info ===")
    println("Norms: ", length(document.norms), " (", length(imported_norms), " imported, ", length(local_norms), " local)")
    total_entities = count_taxons(document.entityTaxonomy)
    total_roles    = count_taxons(document.actorTaxonomy)
    total_actions  = count_taxons(document.actionTaxonomy)
    total_objects  = count_taxons(document.objectTaxonomy)
    
    # Count by source (local vs imported)
    local_entities, imported_entities = count_taxons_by_source(document.entityTaxonomy, document.manifest.package)
    local_roles, imported_roles = count_taxons_by_source(document.actorTaxonomy, document.manifest.package)
    local_actions, imported_actions = count_taxons_by_source(document.actionTaxonomy, document.manifest.package)
    local_objects, imported_objects = count_taxons_by_source(document.objectTaxonomy, document.manifest.package)

    println("Entity taxonomy: ", total_entities, " entities (", imported_entities, " imported, ", local_entities, " local)")
    println("Role taxonomy:   ", total_roles,    " roles (", imported_roles, " imported, ", local_roles, " local)")
    println("Action taxonomy: ", total_actions,  " actions (", imported_actions, " imported, ", local_actions, " local)")
    println("Object taxonomy: ", total_objects,  " objects (", imported_objects, " imported, ", local_objects, " local)")
    
    # Count OpenNormVariables breakdown with source tracking
    if total_objects > 0
        # Count Constants
        local_constants, imported_constants = count_taxons_by_source_under(document.objectTaxonomy, "Constants", document.manifest.package)
        total_constants = local_constants + imported_constants
        
        # Count Parameters
        local_parameters, imported_parameters = count_taxons_by_source_under(document.objectTaxonomy, "Parameters", document.manifest.package)
        total_parameters = local_parameters + imported_parameters
        
        # Count ComputedVariables
        local_computed, imported_computed = count_taxons_by_source_under(document.objectTaxonomy, "ComputedVariables", document.manifest.package)
        total_computed = local_computed + imported_computed
        
        if total_constants > 0 || total_parameters > 0 || total_computed > 0
            println("  - Constants:        ", total_constants, " (", imported_constants, " imported, ", local_constants, " local)")
            println("  - Parameters:       ", total_parameters, " (", imported_parameters, " imported, ", local_parameters, " local)")
            println("  - ComputedVariables:", total_computed, " (", imported_computed, " imported, ", local_computed, " local)")
        end
    end

    # Perform dimensional analysis once on the merged document
    try
        println("\n=== Dimensional Analysis ===")
        unit_defs = extract_units_from_taxonomy(document.objectTaxonomy)
        if !isempty(unit_defs)
            println("Registering $(length(unit_defs)) units from taxonomy...")
            register_units!(unit_defs)
            
            # Build type environment from taxonomy
            println("Building type environment...")
            type_env = build_type_environment(document.objectTaxonomy)
            println("Type environment contains $(length(type_env)) typed variables")
            
            # Parse procedures from the main document and all imports
            println("Parsing procedures...")
            all_procedures = Procedure[]
            
            # Parse from main document
            parser = CommonMark.Parser()
            CommonMark.enable!(parser, CommonMark.FootnoteRule())
            ast = parser(read(path, String))
            main_procedures = parse_procedures(ast, path)
            append!(all_procedures, main_procedures)
            
            # Parse from each imported document
            if !isempty(document.manifest.imports)
                base_dir = dirname(path)
                for import_spec in document.manifest.imports
                    try
                        import_path, _ = resolve_import_path(import_spec, base_dir, pwd())
                        import_ast = parser(read(import_path, String))
                        import_procedures = parse_procedures(import_ast, import_path)
                        append!(all_procedures, import_procedures)
                    catch e
                        # Skip imports that can't be resolved (e.g., stdlib)
                        continue
                    end
                end
            end
            
            procedures = all_procedures
            
            # Update the document with all procedures (main + imported)
            document = DocumentIR(
                manifest=document.manifest,
                entityTaxonomy=document.entityTaxonomy,
                actorTaxonomy=document.actorTaxonomy,
                actionTaxonomy=document.actionTaxonomy,
                objectTaxonomy=document.objectTaxonomy,
                norms=document.norms,
                procedures=procedures,
                parameters=document.parameters,
                input_variables=document.input_variables
            )
            
            if !isempty(procedures)
                println("Performing type resolution and validation for $(length(procedures)) procedures...")
                valid_count = 0
                error_count = 0
                
                for proc in procedures
                    # Validate the pre-parsed expression (parsing now happens in parser.jl)
                    try
                        # Use the pre-parsed expression tree from the Procedure struct
                        validate_computed_variable(proc.name, proc.expression, type_env, proc.location)
                        println("  ✓ *$(proc.name)* (validated)")
                        valid_count += 1
                    catch e
                        if e isa DimensionalMismatchError
                            showerror(stderr, e)
                            println(stderr)
                            error_count += 1
                        else
                            # For other errors (e.g., parsing issues), show warning with details
                            println("  ⚠ *$(proc.name)* ($(typeof(e)): $(e))")
                            error_count += 1
                        end
                    end
                end
                
                if error_count > 0
                    println("⚠️  Dimensional analysis complete: $(valid_count) valid, $(error_count) errors")
                else
                    println("✓ Dimensional analysis complete: all $(valid_count) procedures validated successfully")
                end
            else
                println("No procedures found in operational layer")
                println("✓ Dimensional analysis setup complete (ready for procedure validation)")
            end
        else
            println("No units found in taxonomy, skipping dimensional analysis")
        end
    catch e
        if e isa DimensionalMismatchError
            showerror(stderr, e)
            println(stderr)
            println(stderr, "⚠️  Dimensional analysis failed.\n")
        else
            @warn "Error during dimensional analysis setup" exception=(e, catch_backtrace())
        end
    end
    
    # Check satisfiability
    println("\n=== Checking Satisfiability ===")
    println("Translating OpenNorm to SMT...")
    solver, contradictions = to_smt(document)
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

function opennorm(path::String; openfisca_output::Union{String, Nothing}=nothing)
    """
    Main entry point for OpenNorm validation.
    Returns true if the document is satisfiable, false otherwise.
    
    Arguments:
    - path: Path to the OpenNorm document
    - openfisca_output: Optional path to write generated OpenFisca Python code
    """
    result = validate_document(path)
    result === nothing && return false
    doc, solver, check_result = result
    
    # Generate OpenFisca code if requested
    if openfisca_output !== nothing
        println("\n=== Generating OpenFisca Code ===")
        try
            python_code = compile_to_openfisca(doc)
            open(openfisca_output, "w") do f
                write(f, python_code)
            end
            
            # Extract constants from taxonomy to get accurate parameter count
            constants = extract_constants_from_taxonomy(doc.objectTaxonomy)
            
            println("✓ OpenFisca code generated successfully")
            println("  Output file: $openfisca_output")
            println("  Procedures: $(length(doc.procedures))")
            println("  Parameters: $(length(constants))")
            println("  Input Variables: $(length(doc.input_variables))")
        catch e
            println("✗ Error generating OpenFisca code:")
            showerror(stdout, e, catch_backtrace())
            println()
        end
    end
    
    return string(check_result) == "sat"
end

# CLI argument parsing
function main()
    args = ARGS
    
    if isempty(args)
        println("Usage: julia opennorm.jl <document_path> [--openfisca <output_path>]")
        println()
        println("Arguments:")
        println("  document_path        Path to the OpenNorm document to validate")
        println("  --openfisca PATH     Generate OpenFisca Python code to the specified path")
        println()
        println("Example:")
        println("  julia opennorm.jl ./documents/articles/CGI.Art.156.md")
        println("  julia opennorm.jl ./documents/articles/CGI.Art.156.opennorm.md --openfisca output.py")
        return
    end
    
    doc_path = args[1]
    openfisca_output = nothing
    
    # Parse optional --openfisca argument
    i = 2
    while i <= length(args)
        if args[i] == "--openfisca" && i < length(args)
            openfisca_output = args[i + 1]
            i += 2
        else
            println("Warning: Unknown argument '$(args[i])'")
            i += 1
        end
    end
    
    # Validate the document
    is_valid = opennorm(doc_path; openfisca_output=openfisca_output)
    
    println("\n=== Final Result ===")
    println(is_valid ? "✓ Document is valid" : "✗ Document has issues")
end

# Run main if this file is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
