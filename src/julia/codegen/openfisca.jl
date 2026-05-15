# OpenFisca Python Code Generation
# Generates Python code from OpenNorm IR for OpenFisca execution

using ..Structures: DocumentIR, Procedure, Parameter, InputVariable, Norm
using ..Structures: ExprNode, VariableRef, LiteralValue, BinaryOp, UnaryOp, FunctionCall
using ..Structures: CaseExpression, CumulativeCaseExpression
using ..Structures: Taxon, Object
using ..Structures.Taxonomies: find_child_by_name

# Import shared utilities
include("utils.jl")

# Backend dispatch via multiple dispatch
abstract type Backend end
struct OpenFiscaBackend <: Backend end
struct SMT2Backend <: Backend end
struct ReportBackend <: Backend end

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

"""Infer Python type from OpenNorm unit/type"""
function infer_python_type(unit::Union{Nothing, String})::String
    unit_category = normalize_unit(unit)
    
    return if unit_category == :currency
        "float"
    elseif unit_category == :year
        "int"
    elseif unit_category == :date
        "date"
    elseif unit_category == :bool
        "bool"
    elseif unit_category == :percent
        "float"
    else
        "float"  # Default for :float and :unknown
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
    
    # Check if this is a constant/parameter that should come from YAML
    # Common parameter names from the taxonomy
    parameter_names = [
        "age_minimum", "date_limite_justification", "seuil_revenu_autres",
        "duree_report", "plafond_rente_enfant", "duree_report_foncier",
        "plafond_renovation_energetique", "nombre_annees_imputation",
        "plafond_deficit_foncier", "plafond_deficit_foncier_majore",
        "plafond_avantages_nature", "duree_report_lmnp", "plafond_aspa",
        "abattement_art196_b"
    ]
    
    # Check if this is a string enum value (common boolean-like values)
    enum_values = ["oui", "non", "gens_de_maison", "standard", "true", "false"]
    
    if var_name in enum_values
        # This is a string literal that should be quoted
        return "'$var_name'"
    elseif var_name in parameter_names
        # This is a parameter from the YAML file
        # Access it through the parameters object with period
        return "parameters(period).art156.$var_name"
    else
        # This is a regular variable reference
        return "foyer_fiscal('$var_name', period)"
    end
end

function expr_to_python(expr::LiteralValue, indent::Int=0)::String
    # Special case for dates - always quote
    if expr.unit == "Date"
        return "'$(expr.value)'"
    end
    
    # For all other cases, use the shared formatting logic
    return format_python_value(expr.value)
end

function expr_to_python(expr::BinaryOp, indent::Int=0)::String
    left = expr_to_python(expr.left, indent)
    right = expr_to_python(expr.right, indent)
    
    # Map special operators for OpenFisca
    op_str = if expr.op == :AND
        "*"  # OpenFisca uses * for AND
    elseif expr.op == :OR
        "+"  # OpenFisca uses + for OR
    else
        string(expr.op)
    end
    
    # Only add parentheses for operations that need them (multiplication, division, comparisons)
    # For addition and subtraction chains, parentheses are not needed
    needs_parens = expr.op in [:*, :/, :>, :<, :>=, :<=, :(==), :!=, :AND, :OR]
    
    if needs_parens
        return "($left $op_str $right)"
    else
        return "$left $op_str $right"
    end
end

function expr_to_python(expr::UnaryOp, indent::Int=0)::String
    operand = expr_to_python(expr.operand, indent)
    
    # Map special operators for OpenFisca
    op_str = if expr.op == :round
        "round_"  # OpenFisca uses round_ instead of round
    elseif expr.op == :NOT
        "not_"  # OpenFisca uses not_ instead of not
    else
        string(expr.op)
    end
    
    return "$(op_str)($operand)"
end

function expr_to_python(expr::FunctionCall, indent::Int=0)::String
    args = [expr_to_python(arg, indent) for arg in expr.args]
    
    # Special case for sum with multiple args - wrap in list
    if expr.func == :sum && length(args) > 1
        return "sum([$(join(args, ", "))])"
    elseif expr.func == :sum && length(args) == 1
        return args[1]
    else
        return "$(string(expr.func))($(join(args, ", ")))"
    end
end

"""Check if an expression is a constant boolean value"""
function is_constant_bool(expr::ExprNode)::Union{Nothing, Bool}
    if expr isa LiteralValue
        if expr.value === true || expr.value == "true" || expr.value == 1
            return true
        elseif expr.value === false || expr.value == "false" || expr.value == 0
            return false
        end
    end
    return nothing
end

function expr_to_python(expr::CaseExpression, indent::Int=0)::String
    # Generate if/else statements for Case expressions
    
    if isempty(expr.branches)
        return "0"
    end
    
    # Find default branch
    default_value = "0"
    for (cond, res) in expr.branches
        if cond === nothing
            default_value = expr_to_python(res, indent)
            break
        end
    end
    
    # Get conditional branches (excluding default)
    conditional_branches = [(cond, res) for (cond, res) in expr.branches if cond !== nothing]
    
    if isempty(conditional_branches)
        return default_value
    end
    
    # Generate if/elif/else chain
    lines = String[]
    
    for (i, (cond, res)) in enumerate(conditional_branches)
        cond_py = expr_to_python(cond, indent)
        res_py = expr_to_python(res, indent)
        
        if i == 1
            push!(lines, "if $cond_py:")
            push!(lines, "    return $res_py")
        else
            push!(lines, "elif $cond_py:")
            push!(lines, "    return $res_py")
        end
    end
    
    # Add else clause for default
    push!(lines, "else:")
    push!(lines, "    return $default_value")
    
    return join(lines, "\n")
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

"""
Generate OpenFisca Python Variable class boilerplate.
This helper reduces duplication across different variable types.
"""
function generate_python_class(
    var_name::String,
    value_type::String,
    description::String,
    formula_body::String;
    definition_period::String="YEAR",
    reference::Union{String, Nothing}=nothing,
    formula_params::String="foyer_fiscal, period, parameters"
)::String
    # Build reference line if provided
    ref_line = reference !== nothing ? "\n    reference = \"$reference\"" : ""
    
    """
class $(var_name)(Variable):
    value_type = $value_type
    entity = FoyerFiscal
    definition_period = $definition_period
    label = "$description"$ref_line
    
    def formula($formula_params):
$formula_body
"""
end

"""Generate OpenFisca Python code for a Procedure (computed variable)"""
function generate(::OpenFiscaBackend, proc::Procedure)::String
    var_name = to_snake_case(proc.name)
    value_type = infer_type_from_expr(proc.expression)
    
    # Generate formula body
    formula_body = expr_to_python(proc.expression, 8)
    
    # Format formula body with proper indentation
    if occursin("\n", formula_body)
        # Multi-line formula (if/else statements)
        lines = split(formula_body, "\n")
        indented_lines = ["        " * line for line in lines]
        formula_body_formatted = join(indented_lines, "\n")
    else
        # Single-line formula - add return prefix and indentation
        formula_body_formatted = "        return $formula_body"
    end
    
    description = get_description_or_fallback(proc.description, proc.name)
    
    return generate_python_class(
        var_name,
        value_type,
        description,
        formula_body_formatted,
        reference="opennorm://$(proc.location)"
    )
end

"""Generate OpenFisca Python code for a Parameter (constant)"""
function generate(::OpenFiscaBackend, param::Parameter)::String
    var_name = to_snake_case(param.name)
    value_type = infer_python_type(param.unit)
    description = get_description_or_fallback(param.description, param.name)
    
    if param.is_time_varying
        # Time-varying parameter - reference external parameter file
        param_path = replace(lowercase(var_name), "_" => ".")
        formula_body = "        return parameters(period).$param_path"
        
        return generate_python_class(
            var_name,
            value_type,
            description,
            formula_body
        )
    else
        # Fixed constant
        formula_body = "        return $(param.value)"
        
        return generate_python_class(
            var_name,
            value_type,
            description,
            formula_body,
            definition_period="ETERNITY",
            formula_params="foyer_fiscal, period"
        )
    end
end

"""Generate OpenFisca Python code for an InputVariable"""
function generate(::OpenFiscaBackend, var::InputVariable)::String
    var_name = to_snake_case(var.name)
    value_type = infer_python_type(var.type)
    description = get_description_or_fallback(var.description, var.name)
    
    # InputVariables don't have formulas, so we generate the class directly
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
# TAXONOMY EXTRACTION
# ============================================================================

"""
Extract Parameters from the Object taxonomy and convert to InputVariables
Returns a vector of InputVariable structs
"""
function extract_parameters_from_taxonomy(object_taxonomy::Taxon{Object})::Vector{InputVariable}
    input_vars = InputVariable[]
    
    # Find OpenNormVariables node
    opennorm_vars = find_child_by_name(object_taxonomy, "OpenNormVariables")
    if opennorm_vars === nothing
        return input_vars
    end
    
    # Find Parameters node
    params_node = find_child_by_name(opennorm_vars, "Parameters")
    if params_node === nothing
        return input_vars
    end
    
    # Extract each parameter
    for param_node in params_node.children
        # Parse "Name = Type" or "Name = Type (required)" format
        # Note: Type may or may not have asterisks
        text = param_node.name
        
        # Match pattern: "Name = Type" or "Name = *Type*" with optional (required) or default value
        # First try with asterisks
        m = match(r"^([^=]+?)\s*=\s*\*([^*]+)\*", text)
        if m === nothing
            # Try without asterisks
            m = match(r"^([^=]+?)\s*=\s*([^\s(]+)", text)
        end
        
        if m !== nothing
            name = strip(m.captures[1])
            type_str = strip(m.captures[2])
            
            # Create InputVariable (positional arguments: name, type, description)
            input_var = InputVariable(name, type_str, name)
            push!(input_vars, input_var)
        end
    end
    
    return input_vars
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
    # Extract parameters from taxonomy and add as input variables
    extracted_params = extract_parameters_from_taxonomy(ir.objectTaxonomy)
    
    # Create new DocumentIR with extracted parameters as input variables
    ir_with_inputs = DocumentIR(
        manifest=ir.manifest,
        entityTaxonomy=ir.entityTaxonomy,
        actorTaxonomy=ir.actorTaxonomy,
        actionTaxonomy=ir.actionTaxonomy,
        objectTaxonomy=ir.objectTaxonomy,
        norms=ir.norms,
        procedures=ir.procedures,
        parameters=ir.parameters,
        input_variables=vcat(ir.input_variables, extracted_params)
    )
    
    return generate_openfisca_file(ir_with_inputs)
end