using AbstractTrees


# Position as three booleans — your binary matrix
struct Position
    perspective::Bool  # true = Holder, false = Counterparty
    polarity::Bool     # true = Positive, false = Negative
    order::Bool        # true = First, false = Second
end

# The 8 positions as constants
# (Holder, Positive, First) = (true, true, true)
const Right      = Position(true,  true,  true)   # Holder, Positive, First
const Duty       = Position(false, true,  true)   # Counterparty, Positive, First
const NoRight    = Position(true,  false, true)   # Holder, Negative, First
const Privilege  = Position(false, false, true)   # Counterparty, Negative, First
const Power      = Position(true,  true,  false)  # Holder, Positive, Second
const Liability  = Position(false, true,  false)  # Counterparty, Positive, Second
const Disability = Position(true,  false, false)  # Holder, Negative, Second
const Immunity   = Position(false, false, false)  # Counterparty, Negative, Second

# Operators on position
O(p::Position) = Position(p.perspective, !p.polarity, p.order)
C(p::Position) = Position(!p.perspective, p.polarity, p.order)
E(p::Position) = Position(p.perspective, p.polarity, !p.order)

# Positional helper functions
is_holder_view(p::Position) = p.perspective
is_positive(p::Position) = p.polarity
is_first_order(p::Position) = p.order

# Complementary helpers for readability
is_counterparty_view(p::Position) = !p.perspective
is_negative(p::Position) = !p.polarity
is_second_order(p::Position) = !p.order

# Position relationship functions
are_opposites(pos1::Position, pos2::Position) = pos1 == O(pos2)
are_correlatives(pos1::Position, pos2::Position) = pos1 == C(pos2)
are_order_transforms(pos1::Position, pos2::Position) = pos1 == E(pos2)

# Position to name mapping for encoding/display
const POSITION_NAMES = Dict{Position, String}(
    Right      => "Right",
    Duty       => "Duty",
    NoRight    => "NoRight",
    Privilege  => "Privilege",
    Power      => "Power",
    Liability  => "Liability",
    Disability => "Disability",
    Immunity   => "Immunity"
)

# Helper function to get position name
position_name(p::Position) = get(POSITION_NAMES, p, "Unknown")

# Reverse mapping: name to position (for parsing/debugging)
const NAME_TO_POSITION = Dict{String, Position}(
    "Right"      => Right,
    "Duty"       => Duty,
    "NoRight"    => NoRight,
    "Privilege"  => Privilege,
    "Power"      => Power,
    "Liability"  => Liability,
    "Disability" => Disability,
    "Immunity"   => Immunity
)

# Position classification sets
const PROCEDURABLE_POSITIONS = Set([Right, Duty, Power])
const NEGATIVE_POSITIONS = Set([NoRight, Privilege, Disability, Immunity])
const FIRST_ORDER_POSITIONS = Set([Right, Duty, NoRight, Privilege])
const SECOND_ORDER_POSITIONS = Set([Power, Liability, Disability, Immunity])

# Hohfeldian keyword to Position mapping
const HOHFELD_KEYWORDS = Dict{String, Position}(
    # English keywords
    "must" => Duty,
    "has privilege to" => Privilege,
    "may" => Privilege,
    "has right to" => Right,
    "has no right to" => NoRight,
    "has power to" => Power,
    "can" => Power,
    "has no power to" => Disability,
    "cannot" => Disability,
    "is subject to" => Liability,
    "has immunity from" => Immunity,
    "is protected from" => Immunity,
    # French keywords (from translation table)
    "doit" => Duty,
    "peut" => Privilege,
    "a le droit de" => Right,
    "n'a pas le droit de" => NoRight,
    "a le pouvoir de" => Power,
    "ne peut pas" => Disability,
    "est soumis à" => Liability,
    "est protégé de" => Immunity
)

# Get Position from Hohfeldian keyword
function get_position(keyword::Union{String, SubString{String}})
    key = lowercase(strip(String(keyword)))
    get(HOHFELD_KEYWORDS, key, nothing)
end


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


@enum Lang EN FR
@enum DocumentStatus Review Final
@enum NormLevel Contract Constitutional

const STATUSMAP = Dict(
    "review" => Review,
    "final" => Final
) 
const LANGMAP = Dict(
    "EN" => EN,
    "FR" => FR
) 
const NORMMAP = Dict(
    "Contract" => Contract,
    "Constitutional" => Constitutional
) 

get_lang(s::Union{String, SubString{String}}) = LANGMAP[String(s)]
get_status(s::Union{String, SubString{String}}) = STATUSMAP[String(s)]
get_norm_level(s::Union{String, SubString{String}}) = NORMMAP[String(s)]

struct Manifest
    title::String
    description::String
    package::String
    package_type::String
    version::String
    strict::Bool
    normLevel::NormLevel
    status::DocumentStatus
    imports::Vector{String}
    language::Lang
end

# Concrete entity hierarchy
abstract type ConcreteEntity end

struct LegalEntity <: ConcreteEntity
    name::String
    type::Taxon{Entity}
end

struct NonLegalEntity <: ConcreteEntity
    name::String
    type::Taxon{Object}
    version::Union{String, Nothing}
    metadata::Dict{String, Any}
end


# The core IR node - Abstract normative statement
Base.@kwdef struct Norm <: IRNode
    ref_id::String
    package::String
    Hohfeld::Position
    actor::Taxon{Role} = Taxon(Role, "")
    action::Taxon{Action} = Taxon(Action, "")
    object::Taxon{Object} = Taxon(Object, "")
    counterparty::Taxon{Role} = Taxon(Role, "")
    overrules::Vector{Norm}
    skipped::Bool
    text::String = ""  # The original norm text for display
end

# Norm relationship functions

# Check if two norms have the same relationship (ignoring Hohfeldian position)
# Useful for detecting when two norms apply to the same actors/action/object
# but with different positions (e.g., one is a Right, the other is NoRight)
function same_norm_relationship(norm1::Norm, norm2::Norm)
    return norm1.actor.name == norm2.actor.name &&
           norm1.action.name == norm2.action.name &&
           norm1.object.name == norm2.object.name &&
           norm1.counterparty.name == norm2.counterparty.name
end
# Check if two norms have an equality relationship (same normative content)
function are_equal_norms(norm1::Norm, norm2::Norm)
    # Two norms are equal if they have:
    # - Same Hohfeldian position
    # - Same actor
    # - Same action
    # - Same object
    # - Same counterparty
    return norm1.Hohfeld == norm2.Hohfeld &&
           same_norm_relationship(norm1, norm2)
end

# Check if two norms have a correlative relationship
function are_correlative_norms(norm1::Norm, norm2::Norm)
    # Two norms are correlative if:
    # - Their positions are Hohfeldian correlatives
    # - Actor and counterparty are swapped
    # - Same action and object
    return are_correlatives(norm1.Hohfeld, norm2.Hohfeld) &&
           norm1.actor.name == norm2.counterparty.name &&
           norm1.counterparty.name == norm2.actor.name &&
           norm1.action.name == norm2.action.name &&
           norm1.object.name == norm2.object.name
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

# Check if two norms are related considering taxonomy hierarchy
# Two norms are related if all their components (actor, action, object, counterparty)
# are related in the taxonomy (one subsumes the other)
function norms_are_related(norm1::Norm, norm2::Norm)
    actor_related = taxons_are_related(norm1.actor, norm2.actor)
    action_related = taxons_are_related(norm1.action, norm2.action)
    object_related = taxons_are_related(norm1.object, norm2.object)
    counterparty_related = taxons_are_related(norm1.counterparty, norm2.counterparty)
    
    return actor_related && action_related && object_related && counterparty_related
end


# Concrete instantiation of a norm
struct Binding
    actor::LegalEntity
    counterparty::LegalEntity
    object::ConcreteEntity
    norm::Norm
end

# The full document IR
Base.@kwdef struct DocumentIR
    manifest::Manifest
    entityTaxonomy::Taxon{Entity} = Taxon(Entity, "")
    actorTaxonomy::Taxon{Role} = Taxon(Role, "")
    actionTaxonomy::Taxon{Action} = Taxon(Action, "")
    objectTaxonomy::Taxon{Object} = Taxon(Object, "")
    norms::Vector{Norm}
end

# Operational Layer: Procedure structure
# Represents a computational procedure from Layer 2 that calculates a ComputedVariable
# The expression is stored as raw text; type resolution happens in a separate phase
struct Procedure
    name::String                           # Output variable name (e.g., "DéficitAgricoleImputable")
    description::Union{Nothing, String}    # Optional description from blockquote
    expression_text::String                # Raw expression text (e.g., "Case(...)" or "Variable = Expression")
    location::String                       # Source location for error messages (e.g., "CGI.Art.156:line 531")
end
