# CodeGen Module
# Provides code generation functionality for OpenNorm
# Includes OpenFisca Python generation, YAML parameter generation, and SMT translation

module CodeGen

# Re-export Structures module components needed by submodules
using ..Structures
using ..Structures: DocumentIR, Procedure, Parameter, InputVariable, Norm
using ..Structures: ExprNode, VariableRef, LiteralValue, BinaryOp, UnaryOp, FunctionCall
using ..Structures: CaseExpression, CumulativeCaseExpression
using ..Structures: Taxon, Object, TaxonomyEnum
using ..Structures.Taxonomies

# Include submodules
include("utils.jl")
include("openfisca.jl")
include("yaml.jl")
include("smt.jl")

# Export main functions from openfisca.jl
export compile_to_openfisca
export generate_openfisca_file
export extract_parameters_from_taxonomy

# Export main functions from yaml.jl
export generate_yaml_parameters
export generate_yaml_file
export extract_constants_from_taxonomy

# Export main functions from smt.jl
export encode_position
export encode_taxon
export add_binding!

# Export shared utilities
export to_snake_case
export remove_accents

end # module CodeGen
