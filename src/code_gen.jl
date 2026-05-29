# Backward Compatibility Wrapper for code_gen.jl
# This file maintains backward compatibility with existing code
# All functionality has been moved to src/julia/codegen/

# Import from the new CodeGen package
include(joinpath(@__DIR__, "codegen/CodeGen.jl"))
using .CodeGen

# Re-export all functions for backward compatibility
export compile_to_openfisca
export generate_openfisca_file
export extract_parameters_from_taxonomy
export to_snake_case
export OpenFiscaBackend, SMT2Backend, ReportBackend

# Note: The actual implementation is now in:
# - src/julia/codegen/utils.jl (shared utilities)
# - src/julia/codegen/openfisca.jl (OpenFisca Python generation)
# - src/julia/codegen/CodeGen.jl (main module)