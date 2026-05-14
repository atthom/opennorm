# OpenFisca Code Generation
# Generates Python code from OpenNorm IR for OpenFisca execution

using Unicode
using ..Structures: DocumentIR, Procedure, Parameter, InputVariable, Norm
using ..Structures: ExprNode, VariableRef, LiteralValue, BinaryOp, UnaryOp, FunctionCall
using ..Structures: CaseExpression, CumulativeCaseExpression

# Backend dispatch via multiple dispatch
abstract type Backend end
struct OpenFiscaBackend <: Backend end
struct SMT2Backend <: Backend end
struct ReportBackend <: Backend end

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

"""Convert OpenNorm variable name to Python snake_case"""
function to_snake_case(name::String)::String
    # Remove asterisks
    name = replace(name, "*" => "")
    
    # Remove accents by replacing accented characters with ASCII equivalents
    accent_map = Dict(
        'à' => 'a', 'á' => 'a', 'â' => 'a', 'ã' => 'a', 
        'À' => 'A', 'Á' => 'A', 'Â' => 'A', 'Ã' => 'A', 
        'Ä' => 'A', 'Å' => 'A', 'ä' => 'a', 'å' => 'a',
        'è' => 'e', 'é' => 'e', 'ê' => 'e', 'ë' => 'e',
        'ì' => 'i', 'í' => 'i', 'î' => 'i', 'ï' => 'i',
        'ò' => 'o', 'ó' => 'o', 'ô' => 'o', 'õ' => 'o', 'ö' => 'o',
        'Ò' => 'O', 'Ó' => 'O', 'Ô' => 'O', 'Õ' => 'O', 'Ö' => 'O',
        'ù' => 'u', 'ú' => 'u', 'û' => 'u', 'ü' => 'u',
        'ý' => 'y', 'ÿ' => 'y', 'ñ' => 'n', 'ç' => 'c',
        'È' => 'E', 'É' => 'E', 'Ê' => 'E', 'Ë' => 'E',
        'Ì' => 'I', 'Í' => 'I', 'Î' => 'I', 'Ï' => 'I',
        'Ù' => 'U', 'Ú' => 'U', 'Û' => 'U', 'Ü' => 'U',
        'Ý' => 'Y', 'Ÿ' => 'Y', 'Ñ' => 'N', 'Ç' => 'C'
    )
    
    name = join([get(accent_map, c, c) for c in name])
    
    # Convert to snake_case
    result = ""
    prev_was_upper = false
    
    for (i, c) in enumerate(name)
        if isuppercase(c) && i > 1 && !prev_was_upper
            result *= "_" * lowercase(c)
            prev_was_upper = true
        else
            result *= lowercase(c)
            prev_was_upper = isuppercase(c)
        end
    end
    
    # Clean up multiple underscores
    result = replace(result, r"_+" => "_")
    result = strip(result, '_')
    
    return result
end

"""Infer Python type from OpenNorm unit/type"""
function infer_python_type(unit::Union{Nothing, String})::String
    if unit === nothing
        return "float"
    end
    
    unit_lower = lowercase(unit)
    if occursin("eur", unit_lower) || occursin("currency", unit_lower)
        return "float"
    elseif occursin("année", unit_lower) || occursin("year", unit_lower) || occursin("duration", unit_lower)
        return "int"
    elseif occursin("date", unit_lower)
        return "date"
    elseif occursin("bool", unit_lower) || occursin("oui", unit_lower) || occursin("non", unit_lower)
        return "bool"
    elseif occursin("%", unit_lower) || occursin("percent", unit_lower)
        return "float"
    else
        return "float"  # Default
    end
end

"""Infer Python type from expression tree"""
function infer_type_from_expr(expr::ExprNode)::String
    if expr isa LiteralValue
        return infer_python_type(expr.unit)
    elseif expr isa BinaryOp
        # Binary operations typically preserve numeric types
        return "float"
    elseif expr isa CaseExpression || expr isa CumulativeCaseExpression
        # Infer from first result branch
        if !isempty(expr.branches)
            _, result = expr.branches[1]
            return infer_type_from_expr(result)
        end
        return "float"
    elseif expr isa FunctionCall
        # Most functions return float
        return "float"
    else
        return "float"
    end
end

# ============================================================================
# EXPRESSION TREE TO PYTHON TRANSLATION
# ============================================================================

"""Convert expression tree to Python code"""
function expr_to_python(expr::VariableRef, indent::Int=0)::String
    var_name = to_snake_case(expr.name)
    return "foyer_fiscal('$var_name', period)"
end

function expr_to_python(expr::LiteralValue, indent::Int=0)::String
    if expr.unit == "EUR" || expr.unit === nothing
        return string(expr.value)
    elseif expr.unit == "Années"
        return string(expr.value)
    elseif expr.unit == "Date"
        # Handle date literals
        return "'$(expr.value)'"
    else
        return string(expr.value)
    end
end

function expr_to_python(expr::BinaryOp, indent::Int=0)::String
    left = expr_to_python(expr.left, indent)
    right = expr_to_python(expr.right, indent)
    
    op_str = if expr.op == :+
        "+"
    elseif expr.op == :-
        "-"
    elseif expr.op == :*
        "*"
    elseif expr.op == :/
        "/"
    elseif expr.op == :>
        ">"
    elseif expr.op == :<
        "<"
    elseif expr.op == :>=
        ">="
    elseif expr.op == :<=
        "<="
    elseif expr.op == :(==)
        "=="
    elseif expr.op == :!=
        "!="
    elseif expr.op == :AND
        "*"  # OpenFisca uses * for AND
    elseif expr.op == :OR
        "+"  # OpenFisca uses + for OR
    else
        string(expr.op)
    end
    
    return "($left $op_str $right)"
end

function expr_to_python(expr::UnaryOp, indent::Int=0)::String
    operand = expr_to_python(expr.operand, indent)
    
    if expr.op == :round
        return "round_($operand)"
    elseif expr.op == :ceil
        return "ceil($operand)"
    elseif expr.op == :floor
        return "floor($operand)"
    elseif expr.op == :abs
        return "abs($operand)"
    elseif expr.op == :sqrt
        return "sqrt($operand)"
    elseif expr.op == :NOT
        return "not_($operand)"
    else
        return "$(expr.op)($operand)"
    end
end

function expr_to_python(expr::FunctionCall, indent::Int=0)::String
    args = [expr_to_python(arg, indent) for arg in expr.args]
    
    if expr.func == :min
        return "min_($(join(args, ", ")))"
    elseif expr.func == :max
        return "max_($(join(args, ", ")))"
    elseif expr.func == :sum
        # Sum of multiple arguments
        if length(args) == 1
            return args[1]
        else
            return join(args, " + ")
        end
    else
        return "$(expr.func)($(join(args, ", ")))"
    end
end

function expr_to_python(expr::CaseExpression, indent::Int=0)::String
    # Generate nested where() calls
    # where(condition, true_value, false_value)
    
    if isempty(expr.branches)
        return "0"
    end
    
    # Build from the last branch backwards
    result = ""
    default_value = "0"
    
    # Find default branch
    for (cond, res) in expr.branches
        if cond === nothing
            default_value = expr_to_python(res, indent)
            break
        end
    end
    
    # Build nested where() from last to first (excluding default)
    conditional_branches = [(cond, res) for (cond, res) in expr.branches if cond !== nothing]
    
    if isempty(conditional_branches)
        return default_value
    end
    
    result = default_value
    for i in length(conditional_branches):-1:1
        cond, res = conditional_branches[i]
        cond_py = expr_to_python(cond, indent)
        res_py = expr_to_python(res, indent)
        result = "where($cond_py, $res_py, $result)"
    end
    
    return result
end

function expr_to_python(expr::CumulativeCaseExpression, indent::Int=0)::String
    # CumulativeCase accumulates results where conditions are true
    # This is more complex - we need to sum all matching branches
    
    if isempty(expr.branches)
        return "0"
    end
    
    # For cumulative case, we sum all branches where condition is true
    terms = String[]
    
    for (cond, res) in expr.branches
        if cond === nothing
            # Default case - always add
            push!(terms, expr_to_python(res, indent))
        else
            # Conditional case - add if condition is true
            cond_py = expr_to_python(cond, indent)
            res_py = expr_to_python(res, indent)
            push!(terms, "where($cond_py, $res_py, 0)")
        end
    end
    
    if length(terms) == 1
        return terms[1]
    else
        return join(terms, " + ")
    end
end

# ============================================================================
# CODE GENERATION FOR EACH IR NODE TYPE
# ============================================================================

"""Generate OpenFisca Python code for a Procedure (computed variable)"""
function generate(::OpenFiscaBackend, proc::Procedure)::String
    var_name = to_snake_case(proc.name)
    value_type = infer_type_from_expr(proc.expression)
    
    # Generate formula body
    formula_body = expr_to_python(proc.expression, 2)
    
    # Add proper indentation
    indent = "        "
    formula_lines = split(formula_body, "\n")
    formula_body_indented = join([indent * line for line in formula_lines], "\n")
    
    description = proc.description !== nothing ? proc.description : proc.name
    
    """
class $(var_name)(Variable):
    value_type = $value_type
    entity = FoyerFiscal
    definition_period = YEAR
    label = "$description"
    reference = "opennorm://$(proc.location)"
    
    def formula(foyer_fiscal, period, parameters):
        return $formula_body
"""
end

"""Generate OpenFisca Python code for a Parameter (constant)"""
function generate(::OpenFiscaBackend, param::Parameter)::String
    var_name = to_snake_case(param.name)
    value_type = infer_python_type(param.unit)
    
    description = param.description !== nothing ? param.description : param.name
    
    if param.is_time_varying
        # Time-varying parameter - reference external parameter file
        param_path = replace(lowercase(var_name), "_" => ".")
        """
class $(var_name)(Variable):
    value_type = $value_type
    entity = FoyerFiscal
    definition_period = YEAR
    label = "$description"
    
    def formula(foyer_fiscal, period, parameters):
        return parameters(period).$param_path
"""
    else
        # Fixed constant
        value_str = param.value
        """
class $(var_name)(Variable):
    value_type = $value_type
    entity = FoyerFiscal
    definition_period = ETERNITY
    label = "$description"
    
    def formula(foyer_fiscal, period):
        return $value_str
"""
    end
end

"""Generate OpenFisca Python code for an InputVariable"""
function generate(::OpenFiscaBackend, var::InputVariable)::String
    var_name = to_snake_case(var.name)
    value_type = infer_python_type(var.type)
    
    description = var.description !== nothing ? var.description : var.name
    
    """
class $(var_name)(Variable):
    value_type = $value_type
    entity = FoyerFiscal
    definition_period = YEAR
    label = "$description"
"""
end

"""Generate OpenFisca Python code for a Norm (legacy support)"""
function generate(::OpenFiscaBackend, norm::Norm)::Union{String, Nothing}
    norm.skipped && return nothing
    
    # This is the old implementation - keeping for compatibility
    # In the future, norms might generate different code
    return nothing
end

# ============================================================================
# REPORT BACKEND (for debugging)
# ============================================================================

function generate(::ReportBackend, proc::Procedure)::String
    "| `$(proc.name)` | Computed Variable | ✅ Generated |"
end

function generate(::ReportBackend, param::Parameter)::String
    "| `$(param.name)` | Parameter | ✅ Generated |"
end

function generate(::ReportBackend, var::InputVariable)::String
    "| `$(var.name)` | Input Variable | ✅ Generated |"
end

function generate(::ReportBackend, norm::Norm)::String
    status = norm.skipped ? "⚠️ SKIPPED" : "✅ Verified"
    "| `#$(norm.ref_id)` | Norm | $(status) |"
end

# ============================================================================
# COMPLETE DOCUMENT COMPILATION
# ============================================================================

"""Generate complete OpenFisca Python file from DocumentIR"""
function generate_openfisca_file(ir::DocumentIR)::String
    # Header with imports
    header = """
# -*- coding: utf-8 -*-
# Generated from OpenNorm document
# Title: $(ir.manifest.title)
# Package: $(ir.manifest.package)
# Version: $(ir.manifest.version)
# Status: $(ir.manifest.status)

from openfisca_core.model_api import *
from openfisca_france.model.base import *

"""
    
    # Generate code for all components
    backend = OpenFiscaBackend()
    
    # Parameters first (constants)
    param_code = [generate(backend, p) for p in ir.parameters]
    
    # Input variables
    input_code = [generate(backend, v) for v in ir.input_variables]
    
    # Computed variables (procedures)
    proc_code = [generate(backend, p) for p in ir.procedures]
    
    # Combine all
    all_code = vcat(param_code, input_code, proc_code)
    
    return header * join(all_code, "\n\n")
end

"""Main compilation function - generates OpenFisca code"""
function compile_to_openfisca(ir::DocumentIR)::String
    return generate_openfisca_file(ir)
end