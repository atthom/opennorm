# Structures Package Entry Point
# This file includes all structure definitions without module wrapping
# All types and functions are included directly into the parent scope

# Include structure definition files in dependency order
include("exceptions.jl")
include("Hohfeldian.jl")
include("Taxonomies.jl")
include("IntermediateRepresentation.jl")

# Taxonomy utility functions (previously in nested Taxonomies module)
"""Find a direct child of a taxon by name"""
function find_child_by_name(taxon::Taxon{T}, name::String) where {T<:TaxonomyEnum}
    for child in taxon.children
        if child.name == name
            return child
        end
    end
    return nothing
end