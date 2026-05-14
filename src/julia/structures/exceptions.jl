
# Base exception type for OpenNorm
abstract type OpenNormException <: Exception end

# Error types for import system
struct ImportPathError <: OpenNormException
    path::String
    reason::String
end

struct DocumentParseError <: OpenNormException
    path::String
    reason::String
end

struct TaxonomyMergeConflict <: OpenNormException
    term::String
    taxonomy_type::String
    locations::Vector{String}   # chain strings, one per document
    documents::Vector{String}   # document paths/packages, parallel to locations
end

# Render a chain string like "AnyRole -> FoyerFiscal" as a visual tree
function render_chain(chain::String)
    parts = split(chain, " -> ")
    if length(parts) == 1
        return "    $(parts[1])  ← root (no parent)"
    else
        lines = String[]
        for (i, part) in enumerate(parts)
            if i < length(parts)
                push!(lines, "    " * "    " ^ (i - 1) * String(part))
            else
                push!(lines, "    " * "    " ^ (i - 1) * "└── " * String(part) * "  ← child of $(parts[i-1])")
            end
        end
        return join(lines, "\n")
    end
end

# Custom error display for TaxonomyMergeConflict
function Base.showerror(io::IO, e::TaxonomyMergeConflict)
    println(io, "\n═══════════════════════════════════════════════════════════════")
    println(io, "❌ TAXONOMY CONFLICT — Misplaced Taxon in $(e.taxonomy_type) Taxonomy")
    println(io, "═══════════════════════════════════════════════════════════════\n")

    println(io, "  Taxon:    \"$(e.term)\"")
    println(io, "  Taxonomy: $(e.taxonomy_type)")
    println(io)
    println(io, "This taxon appears at conflicting positions across documents:")
    println(io)

    for (i, loc) in enumerate(e.locations)
        doc = i <= length(e.documents) ? e.documents[i] : "unknown"
        println(io, "  In \"$doc\":")
        println(io, render_chain(loc))
        println(io)
    end

    println(io, "Fix: Ensure \"$(e.term)\" is placed at the same position in all")
    println(io, "     documents that define or import this taxonomy.")
    println(io, "     Check that every module uses the same parent for \"$(e.term)\".")
    println(io, "\n═══════════════════════════════════════════════════════════════")
end

struct CircularDependencyError <: OpenNormException
    path::String
    chain::Vector{String}
end

struct UndefinedTermError <: OpenNormException
    term::String
    taxonomy_type::String
    norm_id::String
    position::String  # "actor", "action", "object", or "counterparty"
    norm_text::String  # Full text of the norm for context
end

# Exception for dimensional mismatch errors in type checking
struct DimensionalMismatchError <: OpenNormException
    variable::String
    declared_type::Any  # Unitful.FreeUnits
    inferred_type::Any  # Unitful.FreeUnits
    expression::String
    location::String  # Procedure name or location
end

# Custom error display for DimensionalMismatchError
function Base.showerror(io::IO, e::DimensionalMismatchError)
    println(io, "\n═══════════════════════════════════════════════════════════════")
    println(io, "❌ DIMENSIONAL ANALYSIS ERROR")
    println(io, "═══════════════════════════════════════════════════════════════\n")
    println(io, "  Variable:      $(e.variable)")
    println(io, "  Location:      $(e.location)")
    println(io, "  Declared type: $(e.declared_type)")
    println(io, "  Inferred type: $(e.inferred_type)")
    println(io, "\n  Expression: $(e.expression)")
    println(io, "\n  Problem:")
    
    # Import Unitful for dimension checking (will be available when this is used)
    # Note: We use try-catch to handle the case where Unitful might not be loaded yet
    try
        # Access dimension function from Unitful
        declared_dim = Main.Unitful.dimension(e.declared_type)
        inferred_dim = Main.Unitful.dimension(e.inferred_type)
        
        println(io, "    The expression produces $(inferred_dim),")
        println(io, "    but the variable is declared as $(declared_dim).")
        println(io, "\n  Suggestion:")
        
        # Provide specific suggestions based on the mismatch
        if inferred_dim == declared_dim^2
            println(io, "    You are multiplying two quantities with the same dimension.")
            println(io, "    Either:")
            println(io, "      1. Use division instead of multiplication")
            println(io, "      2. Declare $(e.variable) as $(e.inferred_type)")
        elseif inferred_dim == Main.Unitful.NoDims && declared_dim != Main.Unitful.NoDims
            println(io, "    The expression is dimensionless (no units).")
            println(io, "    Either:")
            println(io, "      1. Multiply by a quantity with dimension $(declared_dim)")
            println(io, "      2. Declare $(e.variable) as dimensionless")
        elseif inferred_dim != Main.Unitful.NoDims && declared_dim == Main.Unitful.NoDims
            println(io, "    The expression has dimension $(inferred_dim).")
            println(io, "    Either:")
            println(io, "      1. Divide by a quantity to make it dimensionless")
            println(io, "      2. Declare $(e.variable) with the correct dimension")
        else
            println(io, "    Check the arithmetic operations in your expression.")
            println(io, "    Ensure the result dimension matches the declared type.")
        end
    catch
        # Fallback if Unitful is not available
        println(io, "    The expression produces $(e.inferred_type),")
        println(io, "    but the variable is declared as $(e.declared_type).")
        println(io, "\n  Suggestion:")
        println(io, "    Check the arithmetic operations in your expression.")
        println(io, "    Ensure the result dimension matches the declared type.")
    end
    
    println(io, "\n═══════════════════════════════════════════════════════════════")
end

# Custom error display for UndefinedTermError
function Base.showerror(io::IO, e::UndefinedTermError)
    # TODO: Get language from document context - for now default to English
    lang = :en  # Could be :fr for French
    
    if lang == :fr
        println(io, "\n═══════════════════════════════════════════════════════════════")
        println(io, "❌ ERREUR DE VALIDATION - Terme Non Défini dans la Taxonomie")
        println(io, "═══════════════════════════════════════════════════════════════\n")
        
        println(io, "Norme: ", e.norm_id)
        if !isempty(e.norm_text)
            println(io, "Texte: ", e.norm_text)
        end
        println(io)
        
        println(io, "Problème:")
        println(io, "  Terme: \"", e.term, "\"")
        println(io, "  Position: ", e.position)
        println(io, "  Taxonomie attendue: ", e.taxonomy_type)
        println(io)
        
        println(io, "Explication:")
        position_desc = if e.position == "actor"
            "première position (acteur)"
        elseif e.position == "action"
            "deuxième position (action/verbe)"
        elseif e.position == "object"
            "troisième position (objet)"
        elseif e.position == "counterparty"
            "quatrième position (après préposition to/from/by/à/de/etc.)"
        else
            e.position
        end
        
        println(io, "  Le terme \"", e.term, "\" est utilisé en position \"", position_desc, "\",")
        println(io, "  ce qui nécessite un terme de la taxonomie \"", e.taxonomy_type, "\".")
        println(io, "  Cependant, ce terme n'est pas défini dans cette taxonomie.")
        println(io)
        
        println(io, "Solutions possibles:")
        if e.position == "counterparty"
            println(io, "  1. Vérifier si cette norme a vraiment besoin d'un counterparty")
            println(io, "  2. Supprimer la préposition et le dernier terme si pas de counterparty")
            println(io, "  3. Ajouter \"", e.term, "\" à la taxonomie ", e.taxonomy_type)
            println(io, "  4. Remplacer \"", e.term, "\" par un terme existant de la taxonomie ", e.taxonomy_type)
        else
            println(io, "  1. Ajouter \"", e.term, "\" à la taxonomie ", e.taxonomy_type)
            println(io, "  2. Vérifier l'orthographe du terme")
            println(io, "  3. Remplacer par un terme existant de la taxonomie ", e.taxonomy_type)
        end
        
        println(io, "\n═══════════════════════════════════════════════════════════════")
    else  # English
        println(io, "\n═══════════════════════════════════════════════════════════════")
        println(io, "❌ VALIDATION ERROR - Undefined Term in Taxonomy")
        println(io, "═══════════════════════════════════════════════════════════════\n")
        
        println(io, "Norm: ", e.norm_id)
        if !isempty(e.norm_text)
            println(io, "Text: ", e.norm_text)
        end
        println(io)
        
        println(io, "Problem:")
        println(io, "  Term: \"", e.term, "\"")
        println(io, "  Position: ", e.position)
        println(io, "  Expected taxonomy: ", e.taxonomy_type)
        println(io)
        
        println(io, "Explanation:")
        position_desc = if e.position == "actor"
            "first position (actor)"
        elseif e.position == "action"
            "second position (action/verb)"
        elseif e.position == "object"
            "third position (object)"
        elseif e.position == "counterparty"
            "fourth position (after preposition to/from/by)"
        else
            e.position
        end
        
        println(io, "  The term \"", e.term, "\" is used in \"", position_desc, "\",")
        println(io, "  which requires a term from the \"", e.taxonomy_type, "\" taxonomy.")
        println(io, "  However, this term is not defined in that taxonomy.")
        println(io)
        
        println(io, "Possible solutions:")
        if e.position == "counterparty"
            println(io, "  1. Check if this norm really needs a counterparty")
            println(io, "  2. Remove the preposition and last term if no counterparty needed")
            println(io, "  3. Add \"", e.term, "\" to the ", e.taxonomy_type, " taxonomy")
            println(io, "  4. Replace \"", e.term, "\" with an existing term from the ", e.taxonomy_type, " taxonomy")
        else
            println(io, "  1. Add \"", e.term, "\" to the ", e.taxonomy_type, " taxonomy")
            println(io, "  2. Check the spelling of the term")
            println(io, "  3. Replace with an existing term from the ", e.taxonomy_type, " taxonomy")
        end
        
        println(io, "\n═══════════════════════════════════════════════════════════════")
    end
end
