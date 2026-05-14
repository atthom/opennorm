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
    name::String                           # Output variable name (e.g., "DéficitAgricoleImputable")
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
end
