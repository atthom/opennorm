module Parser

import CommonMark
using CommonMark: Heading, Paragraph, BlockQuote, List, FootnoteRule, Strong, Text, enable!

# Import structures from parent modules
using ..Structures: Manifest, DocumentIR, Norm, Taxon, Procedure, Parameter, InputVariable
using ..Structures: Entity, Role, Action, Object, TaxonomyEnum
using ..Structures: get_norm_level, get_status, get_lang, get_position, NORMMAP
using ..Structures: ImportPathError, CircularDependencyError, DocumentParseError
using ..Structures: TaxonomyMergeConflict, UndefinedTermError
using ..TypeChecker: parse_case_expression, parse_expression_for_type_checking

# Include all submodules
include("utils.jl")
include("core.jl")
include("manifest.jl")
include("taxonomy.jl")
include("norms.jl")
include("procedures.jl")
include("validation.jl")

# Export main parsing functions
export parse_document, parse_manifest, parse_taxonomy, parse_norms, parse_procedures
export validate_norms_terms, print_validation_report

end # module Parser