# Procedure and Variable Generation for OpenFisca Backend
# Generates Python Variable classes from OpenNorm IR

# ============================================================================
# TYPE INFERENCE
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
# PYTHON CLASS GENERATION
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

# ============================================================================
# PROCEDURE GENERATION - OPENFISCA BACKEND
# ============================================================================

"""
    code_gen(::OpenFiscaBackend, proc::Procedure)::String

Generate OpenFisca Python code for a Procedure (computed variable).
Returns a complete Python Variable class with formula method.
"""
function code_gen(backend::OpenFiscaBackend, proc::Procedure)::String
    var_name = to_snake_case(proc.name)
    value_type = infer_type_from_expr(proc.expression)
    
    # Generate formula body using expression translation
    formula_body = code_gen(backend, proc.expression)
    
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

"""
    code_gen(::OpenFiscaBackend, param::Parameter)::String

Generate OpenFisca Python code for a Parameter (constant).
Handles both time-varying and fixed parameters.
"""
function code_gen(backend::OpenFiscaBackend, param::Parameter)::String
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

"""
    code_gen(::OpenFiscaBackend, var::InputVariable)::String

Generate OpenFisca Python code for an InputVariable.
InputVariables don't have formulas, just declarations.
"""
function code_gen(backend::OpenFiscaBackend, var::InputVariable)::String
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

"""
    code_gen(::OpenFiscaBackend, norm::Norm)::String

Generate OpenFisca Python code for a Norm.
Currently returns empty string (norms don't generate OpenFisca code).
# Norms are verified by SMT solver but don't generate OpenFisca code
"""
code_gen(backend::OpenFiscaBackend, norm::Norm) = ""

# ============================================================================
# REPORT BACKEND (for debugging)
# ============================================================================

code_gen(backend::ReportBackend, proc::Procedure) = "| `$(proc.name)` | Computed Variable | ✅ Generated |"
code_gen(backend::ReportBackend, param::Parameter) = "| `$(param.name)` | Parameter | ✅ Generated |"
code_gen(backend::ReportBackend, var::InputVariable) = "| `$(var.name)` | Input Variable | ✅ Generated |"

function code_gen(backend::ReportBackend, norm::Norm)::String
    status = norm.skipped ? "⚠️ SKIPPED" : "✅ Verified"
    "| `#$(norm.ref_id)` | Norm | $(status) |"
end