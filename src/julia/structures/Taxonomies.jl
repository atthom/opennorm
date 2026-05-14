# Taxonomy System
# Hierarchical classification system for entities, roles, actions, and objects

using AbstractTrees

# Base IR node type
abstract type IRNode end
abstract type TaxonomyEnum end

struct Entity <: TaxonomyEnum end
struct Role <: TaxonomyEnum end
struct Action <: TaxonomyEnum end
struct Object <: TaxonomyEnum end

Base.@kwdef mutable struct Taxon{T<:TaxonomyEnum} <: IRNode
    name::String
    parent::Union{Nothing, Taxon{T}} = nothing
    children::Vector{Taxon{T}} = Vector{Taxon{T}}()
    source::String = ""  # Package name that defined this taxon
end

AbstractTrees.children(n::Taxon{T}) where T = n.children
AbstractTrees.parent(n::Taxon{T}) where T = n.parent

Taxon(::Type{T}, name::String, source::String="") where {T<:TaxonomyEnum} = Taxon{T}(name, nothing, Vector{Taxon{T}}(), source)

function Taxon(parent::Taxon{T}, name::String, source::String="") where {T<:TaxonomyEnum} 
    t = Taxon{T}(name, parent, Taxon{T}[], source)
    push!(parent.children, t)
    return t
end

get_taxonomy(::TaxonomyEnum) = TAXONOMYMAP[s]

# Taxonomy symbol to type mapping
const TAXONOMY_SYMBOL_MAP = Dict{Symbol, Type}(
    :legalentities => Entity,
    :role => Role,
    :action => Action,
    :object => Object,
    :hohfeldian => Entity  # or define a separate type if needed
)

# Get taxonomy type from symbol
function get_taxonomy_type(sym::Symbol)
    haskey(TAXONOMY_SYMBOL_MAP, sym) || error("Unknown taxonomy: $sym")
    return TAXONOMY_SYMBOL_MAP[sym]
end

# Check if two taxons are related (one subsumes the other or they're equal)
# Uses AbstractTrees.isdescendant to check hierarchy
function taxons_are_related(taxon1::Taxon{T}, taxon2::Taxon{T}) where {T<:TaxonomyEnum}
    # They're related if:
    # 1. They're the same taxon (by name, since we compare across documents)
    # 2. taxon1 is a descendant of taxon2 (taxon2 subsumes taxon1)
    # 3. taxon2 is a descendant of taxon1 (taxon1 subsumes taxon2)
    
    # First check by name equality (handles cross-document comparisons)
    if taxon1.name == taxon2.name
        return true
    end
    
    # Then check hierarchy using AbstractTrees
    return isdescendant(taxon1, taxon2) || isdescendant(taxon2, taxon1)
end



# Get taxonomy name string for a given type
get_taxonomy(::Type{Entity}) = "Entity"
get_taxonomy(::Type{Role}) = "Role"
get_taxonomy(::Type{Action}) = "Action"
get_taxonomy(::Type{Object}) = "Object"

# Get default taxonomy for a given type
get_default_taxonomy(::Type{Entity}) = Taxon(Entity, "")
get_default_taxonomy(::Type{Role}) = Taxon(Role, "")
get_default_taxonomy(::Type{Action}) = Taxon(Action, "")
get_default_taxonomy(::Type{Object}) = Taxon(Object, "")
