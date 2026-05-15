# Core Architecture for Unified Code Generation
# Defines backend types and the unified code_gen dispatch interface

using Z3

# ============================================================================
# BACKEND TYPES
# ============================================================================

"""
Abstract base type for all code generation backends.
Each backend represents a different target output format.
"""
abstract type Backend end

"""
OpenFisca backend for generating Python code compatible with OpenFisca.
Returns: String (Python code)
"""
struct OpenFiscaBackend <: Backend
    # Future: could add configuration options (indentation style, etc.)
end

"""
SMT2 backend for generating Z3 SMT constraints.
Carries the Z3 context and solver for constraint generation.
Returns: SMTExpr (wrapped Z3 expressions)
"""
struct SMT2Backend <: Backend
    ctx::Context
    solver::Solver
end

"""
YAML backend for generating OpenFisca parameter files.
Returns: String (YAML text)
"""
struct YAMLBackend <: Backend
    # Future: could add configuration options (formatting, etc.)
end

"""
Report backend for generating debug/status reports.
Returns: String (report text)
"""
struct ReportBackend <: Backend
    # Future: could add configuration options (format, verbosity, etc.)
end

# ============================================================================
# SMT EXPRESSION WRAPPER
# ============================================================================

"""
Wrapper for Z3 expressions to provide a consistent Julia type.
This allows SMT backend to return a Julia struct rather than raw Z3 objects.
"""
struct SMTExpr
    z3_expr  # The actual Z3 expression (BoolVar, etc.)
end

# ============================================================================
# UNIFIED CODE GENERATION INTERFACE
# ============================================================================

"""
    code_gen(backend::Backend, node) -> String | SMTExpr

Unified code generation interface using multiple dispatch.
Each backend × node type combination can be specialized.

# Default Behavior
Unimplemented combinations return an empty string, allowing graceful degradation.

# Return Types by Backend
- OpenFiscaBackend: String (Python code)
- SMT2Backend: SMTExpr (wrapped Z3 expressions)
- YAMLBackend: String (YAML text)

# Arguments
- `backend`: The code generation backend (OpenFiscaBackend, SMT2Backend, YAMLBackend)
- `node`: The IR node to generate code for (Norm, Procedure, ExprNode, etc.)

# Examples
```julia
# OpenFisca: generate Python code for an expression
backend = OpenFiscaBackend()
python_code = code_gen(backend, expr)  # Returns String

# SMT: generate Z3 constraint for a norm
backend = SMT2Backend(ctx, solver)
smt_expr = code_gen(backend, norm)  # Returns SMTExpr

# YAML: generate parameter definition
backend = YAMLBackend()
yaml_text = code_gen(backend, param)  # Returns String
```
"""
code_gen(backend::Backend, node) = ""

# Export types and functions
export Backend, OpenFiscaBackend, SMT2Backend, YAMLBackend, ReportBackend
export SMTExpr
export code_gen
