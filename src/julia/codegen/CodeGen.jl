# CodeGen Package Entry Point
# Unified code generation architecture for OpenNorm
# Provides multiple backends: OpenFisca (Python), YAML, SMT2, Report
# This file includes all codegen files without module wrapping

# External dependencies needed by codegen
using Z3
using YAML

# Include codegen subfiles in dependency order
include("core.jl")          # Backend types and code_gen interface
include("utils.jl")         # Shared helper functions
include("expressions.jl")   # Expression translation (OpenFisca)
include("procedures.jl")    # Procedure/variable generation (OpenFisca, Report)
include("smt.jl")          # SMT translation (SMT2)
include("yaml.jl")         # YAML generation (YAML)
include("compilation.jl")  # Top-level compilation (OpenFisca)
