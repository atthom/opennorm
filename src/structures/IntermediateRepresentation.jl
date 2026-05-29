# Intermediate Representation (IR)
# Core data structures for representing OpenNorm documents

using AbstractTrees


# === OPERATIONAL LAYER ===
# Abstract type for operational/computational nodes (Layer 2)
abstract type OperationalNode <: IRNode end

# Expression nodes for computational procedures
abstract type ExprNode <: OperationalNode end

struct VariableRef <: ExprNode
    name::String
end

struct LiteralValue <: ExprNode
    value::Any
    unit::Union{Nothing, String}
end

struct BinaryOp <: ExprNode
    op::Symbol  # :+, :-, :*, :/
    left::ExprNode
    right::ExprNode
end

struct UnaryOp <: ExprNode
    op::Symbol  # :round, :ceil, :floor, :abs, :sqrt, etc.
    operand::ExprNode
end

struct FunctionCall <: ExprNode
    func::Symbol  # :min, :max, :sum, etc.
    args::Vector{ExprNode}
end

# Base type for case-like expressions
abstract type CaseExprNode <: ExprNode end

struct CaseExpression <: CaseExprNode
    branches::Vector{Tuple{Union{ExprNode, Nothing}, ExprNode}}  # (condition, result) pairs, Nothing for Default
end

struct CumulativeCaseExpression <: CaseExprNode
    branches::Vector{Tuple{Union{ExprNode, Nothing}, ExprNode}}  # (condition, result) pairs, Nothing for Default
end

# AbstractTrees support for ExprNode traversal
AbstractTrees.children(n::VariableRef) = ()
AbstractTrees.children(n::LiteralValue) = ()
AbstractTrees.children(n::BinaryOp) = (n.left, n.right)
AbstractTrees.children(n::UnaryOp) = (n.operand,)
AbstractTrees.children(n::FunctionCall) = n.args
AbstractTrees.children(n::CaseExpression) = [result for (_, result) in n.branches]
AbstractTrees.children(n::CumulativeCaseExpression) = [result for (_, result) in n.branches]

# Operational Layer: Procedure structure
# Represents a computational procedure from Layer 2 that calculates a ComputedVariable
struct Procedure <: OperationalNode
    name::String                           # Normalized variable name (e.g., "DéficitAgricoleImputable")
    display_name::String                   # Display name with spaces (e.g., "Déficit Agricole Imputable")
    description::Union{Nothing, String}    # Optional description from blockquote
    expression::ExprNode                   # Parsed expression tree for type checking
    expression_text::String                # Raw expression text for debugging/display
    location::String                       # Source location for error messages (e.g., "CGI.Art.156:line 531")
end

# Parameter/Constant definition
# Represents a fixed value or time-varying parameter from the Parameters section
struct Parameter <: OperationalNode
    name::String                           # Parameter name (e.g., "SeuilRevenuAgricole")
    value::Union{Float64, Int, String, Nothing}  # Literal value (Nothing if time-varying)
    unit::Union{Nothing, String}           # Unit (EUR, Années, Date, etc.)
    description::Union{Nothing, String}    # Optional description
    is_time_varying::Bool                  # true if references external parameter file
end

# Input Variable declaration
# Represents a variable that is referenced but not computed (external input)
struct InputVariable <: OperationalNode
    name::String                           # Variable name
    type::String                           # Type (EUR, Boolean, Date, etc.)
    description::Union{Nothing, String}    # Optional description
end

# === JURISDICTION SYSTEM ===
# Represents a legal jurisdiction (e.g., FR.Constitution, EU.Regulation)
struct Jurisdiction
    namespace::String    # e.g., "FR", "EU"
    name::String        # e.g., "Constitution", "Regulation"
end

# Convenience constructor from string "FR.Loi"
function Jurisdiction(s::String)
    parts = split(s, ".")
    if length(parts) != 2
        throw(ArgumentError("Invalid jurisdiction format: $s. Expected format: Namespace.Name"))
    end
    return Jurisdiction(String(parts[1]), String(parts[2]))
end

# String representation
Base.string(j::Jurisdiction) = "$(j.namespace).$(j.name)"
Base.show(io::IO, j::Jurisdiction) = print(io, string(j))

# Equality and hashing for use in dictionaries/sets
Base.:(==)(j1::Jurisdiction, j2::Jurisdiction) = j1.namespace == j2.namespace && j1.name == j2.name
Base.hash(j::Jurisdiction, h::UInt) = hash((j.namespace, j.name), h)

# Represents a hierarchical relationship between jurisdictions
struct LexSuperior
    superior::Jurisdiction    # Higher jurisdiction
    inferior::Jurisdiction    # Lower jurisdiction
    ambiguous::Bool          # true if relationship is contested (~)
end

# Container for all jurisdiction relationships
struct JurisdictionHierarchy
    relations::Vector{LexSuperior}    # All relations (direct + transitive)
    jurisdictions::Set{Jurisdiction}  # All known jurisdictions
end

# === DOCUMENT METADATA ===
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
    jurisdiction::Union{Nothing, Jurisdiction}
end

# === CONCRETE ENTITIES ===
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

# === CONDITION REPRESENTATION ===
# Represents a condition clause in a norm (e.g., "lorsque *TypePropriété* = *MonumentHistorique*")
# Note: ConditionExpr types are defined in parser/condition_parser.jl
struct NormCondition
    raw_text::String  # The original condition text for display and debugging
    expr::Union{Nothing, Any}  # Parsed condition expression tree (ConditionExpr from condition_parser.jl)
    
    # Constructor with just raw text (for backward compatibility)
    NormCondition(raw_text::String) = new(raw_text, nothing)
    
    # Constructor with parsed expression
    NormCondition(raw_text::String, expr) = new(raw_text, expr)
end

# === NORMS ===
# The core IR node - Abstract normative statement
Base.@kwdef struct Norm <: IRNode
    ref_id::String
    package::String
    Hohfeld::Position
    actor::Taxon{Role} = Taxon(Role, "")
    action::Taxon{Action} = Taxon(Action, "")
    object::Taxon{Object} = Taxon(Object, "")
    counterparty::Taxon{Role} = Taxon(Role, "")
    conditions::Vector{NormCondition} = NormCondition[]  # Conditions from "lorsque" clauses
    overrules::Vector{Norm}
    excepts::Union{Nothing, String} = nothing  # Parent rule ref_id for exceptions
    depth::Int = 0                              # Exception depth (0 = base rule, 1+ = exception)
    skipped::Bool
    text::String = ""  # The original norm text for display
    jurisdiction::Union{Nothing, Jurisdiction} = nothing  # Jurisdiction from document manifest
end

"""
    Norm(parent::Norm, ref_id::String; text::String="", conditions::Vector{NormCondition}=NormCondition[])

Constructor for creating an exception norm from a parent norm.
Automatically inherits actor, action, object, and counterparty from parent.
Auto-computes position as O(parent.position) - the Hohfeldian opposite.
Sets depth to parent.depth + 1 and links to parent via excepts field.

This constructor is used for minimal exception syntax where only the condition
and ref_id are specified, and everything else is inherited.

# Arguments
- `parent::Norm`: The parent norm this exception applies to
- `ref_id::String`: The unique identifier for this exception norm
- `text::String=""`: Optional text representation of the exception
- `conditions::Vector{NormCondition}=NormCondition[]`: Conditions for this exception

# Example
```julia
# Parent norm
parent = Norm(
    ref_id = "base-rule",
    Hohfeld = NoRight,
    actor = proprietaire_taxon,
    action = deduire_taxon,
    # ...
)

# Create exception - inherits everything, auto-computes position as O(NoRight) = Right
exception = Norm(parent, "exception-rule", text="exception de #base-rule")
```
"""
function Norm(parent::Norm, ref_id::String; text::String="", conditions::Vector{NormCondition}=NormCondition[])
    return Norm(
        ref_id = ref_id,
        package = parent.package,
        Hohfeld = O(parent.Hohfeld),  # Auto-compute opposite position
        actor = parent.actor,
        action = parent.action,
        object = parent.object,
        counterparty = parent.counterparty,
        conditions = conditions,  # Exception-specific conditions
        overrules = Norm[],
        excepts = parent.ref_id,  # Link to parent
        depth = parent.depth + 1,  # Increment depth
        skipped = false,
        text = text
    )
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

# Check if two norms have identical conditions
function same_conditions(norm1::Norm, norm2::Norm)
    if length(norm1.conditions) != length(norm2.conditions)
        return false
    end
    
    # Compare raw text of conditions (order-independent)
    cond1_texts = Set(c.raw_text for c in norm1.conditions)
    cond2_texts = Set(c.raw_text for c in norm2.conditions)
    
    return cond1_texts == cond2_texts
end

# Concrete instantiation of a norm
struct Binding
    actor::LegalEntity
    counterparty::LegalEntity
    object::ConcreteEntity
    norm::Norm
end

# === DOCUMENT IR ===
# The full document IR
Base.@kwdef struct DocumentIR
    manifest::Manifest
    entityTaxonomy::Taxon{Entity} = Taxon(Entity, "")
    actorTaxonomy::Taxon{Role} = Taxon(Role, "")
    actionTaxonomy::Taxon{Action} = Taxon(Action, "")
    objectTaxonomy::Taxon{Object} = Taxon(Object, "")
    norms::Vector{Norm}
    procedures::Vector{Procedure} = Procedure[]
    parameters::Vector{Parameter} = Parameter[]
    input_variables::Vector{InputVariable} = InputVariable[]
    jurisdiction_hierarchy::Union{Nothing, JurisdictionHierarchy} = nothing
end
