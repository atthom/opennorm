# Backward Compatibility Wrapper for yaml_gen.jl
# This file maintains backward compatibility with existing code
# All functionality has been moved to src/julia/codegen/

# Import from the new CodeGen package
include(joinpath(@__DIR__, "codegen/CodeGen.jl"))
using .CodeGen

# Re-export all functions for backward compatibility
export generate_yaml_parameters
export generate_yaml_file
export extract_constants_from_taxonomy
export to_snake_case

# Note: The actual implementation is now in:
# - src/julia/codegen/utils.jl (shared utilities)
# - src/julia/codegen/yaml.jl (YAML parameter generation)
# - src/julia/codegen/CodeGen.jl (main module)