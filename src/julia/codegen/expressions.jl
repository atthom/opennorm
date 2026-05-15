# Expression Translation for OpenFisca Backend
# Converts OpenNorm expression trees to Python code

# ============================================================================
# EXPRESSION TRANSLATION - OPENFISCA BACKEND
# ============================================================================

"""
    code_gen(::OpenFiscaBackend, expr::VariableRef)::String

Generate Python code for a variable reference.
Handles three cases:
1. Enum values (oui, non, etc.) → quoted strings
2. Parameters → access via parameters(period).art156.name
3. Regular variables → access via foyer_fiscal('name', period)
"""
function code_gen(backend::OpenFiscaBackend, expr::VariableRef)::String
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

"""
    code_gen(::OpenFiscaBackend, expr::LiteralValue)::String

Generate Python code for a literal value.
Dates are always quoted, other values use format_python_value.
"""
function code_gen(backend::OpenFiscaBackend, expr::LiteralValue)::String
    # Special case for dates - always quote
    if expr.unit == "Date"
        return "'$(expr.value)'"
    end
    
    # For all other cases, use the shared formatting logic
    return format_python_value(expr.value)
end

"""
    code_gen(::OpenFiscaBackend, expr::BinaryOp)::String

Generate Python code for a binary operation.
Maps OpenNorm operators to OpenFisca equivalents (AND→*, OR→+).
"""
function code_gen(backend::OpenFiscaBackend, expr::BinaryOp)::String
    left = code_gen(backend, expr.left)
    right = code_gen(backend, expr.right)
    
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

"""
    code_gen(::OpenFiscaBackend, expr::UnaryOp)::String

Generate Python code for a unary operation.
Maps OpenNorm operators to OpenFisca equivalents (round→round_, NOT→not_).
"""
function code_gen(backend::OpenFiscaBackend, expr::UnaryOp)::String
    operand = code_gen(backend, expr.operand)
    
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

"""
    code_gen(::OpenFiscaBackend, expr::FunctionCall)::String

Generate Python code for a function call.
Special handling for sum with multiple arguments.
"""
function code_gen(backend::OpenFiscaBackend, expr::FunctionCall)::String
    args = [code_gen(backend, arg) for arg in expr.args]
    
    # Special case for sum with multiple args - wrap in list
    if expr.func == :sum && length(args) > 1
        return "sum([$(join(args, ", "))])"
    elseif expr.func == :sum && length(args) == 1
        return args[1]
    else
        return "$(string(expr.func))($(join(args, ", ")))"
    end
end

"""
    code_gen(::OpenFiscaBackend, expr::CaseExpression)::String

Generate Python code for a case expression (if/elif/else).
Returns a multi-line Python if/elif/else statement.
"""
function code_gen(backend::OpenFiscaBackend, expr::CaseExpression)::String
    # Generate if/else statements for Case expressions
    
    if isempty(expr.branches)
        return "0"
    end
    
    # Find default branch
    default_value = "0"
    for (cond, res) in expr.branches
        if cond === nothing
            default_value = code_gen(backend, res)
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
        cond_py = code_gen(backend, cond)
        res_py = code_gen(backend, res)
        
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

"""
    code_gen(::OpenFiscaBackend, expr::CumulativeCaseExpression)::String

Generate Python code for a cumulative case expression.
Sums all branches where conditions are true using where().
"""
function code_gen(backend::OpenFiscaBackend, expr::CumulativeCaseExpression)::String
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
            push!(terms, code_gen(backend, res))
        else
            # Conditional case - add if condition is true
            cond_py = code_gen(backend, cond)
            res_py = code_gen(backend, res)
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
# HELPER FUNCTIONS
# ============================================================================

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