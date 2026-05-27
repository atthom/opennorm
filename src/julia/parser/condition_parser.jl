# Condition Expression Parser
# Parses "lorsque" condition clauses into expression trees for SMT encoding

"""
    ConditionExpr

Abstract base type for condition expressions.
"""
abstract type ConditionExpr end

"""
    VariableExpr

Represents a variable reference in a condition (e.g., *TypePropriété*).
"""
struct VariableExpr <: ConditionExpr
    name::String
end

"""
    LiteralExpr

Represents a literal value in a condition (e.g., *MonumentHistorique*, true, 42).
"""
struct LiteralExpr <: ConditionExpr
    value::Any
    type::Symbol  # :boolean, :integer, :string, :enum
end

"""
    ComparisonExpr

Represents a comparison operation (=, !=, <, >, <=, >=).
"""
struct ComparisonExpr <: ConditionExpr
    op::Symbol  # :eq, :ne, :lt, :gt, :le, :ge
    left::ConditionExpr
    right::ConditionExpr
end

"""
    LogicalExpr

Represents a logical operation (AND, OR, NOT).
"""
struct LogicalExpr <: ConditionExpr
    op::Symbol  # :and, :or, :not
    operands::Vector{ConditionExpr}
end

"""
    parse_condition(text::String) -> ConditionExpr

Parse a condition text into a ConditionExpr tree.

# Examples
```julia
# Simple equality
parse_condition("*TypePropriété* = *MonumentHistorique*")
# => ComparisonExpr(:eq, VariableExpr("TypePropriété"), LiteralExpr("MonumentHistorique", :enum))

# Logical AND
parse_condition("*TravauxRénovationÉnergétique* = *Oui* et *ClasseInitiale* = *E*")
# => LogicalExpr(:and, [...])

# Comparison with number
parse_condition("*MontantTravaux* > 10000")
# => ComparisonExpr(:gt, VariableExpr("MontantTravaux"), LiteralExpr(10000, :integer))
```
"""
function parse_condition(text::String)
    # Remove "lorsque" prefix if present
    text = String(strip(text))
    if startswith(text, "lorsque")
        text = String(strip(text[9:end]))
    end
    
    # Parse the expression
    return parse_logical_expr(text)
end

"""
    parse_logical_expr(text::String) -> ConditionExpr

Parse logical expressions (AND, OR).
"""
function parse_logical_expr(text::String)
    # Check for OR (lowest precedence)
    if occursin(r"\bou\b", text)
        parts = split(text, r"\bou\b")
        operands = [parse_logical_expr(String(strip(p))) for p in parts]
        return LogicalExpr(:or, operands)
    end
    
    # Check for AND
    if occursin(r"\bet\b", text)
        parts = split(text, r"\bet\b")
        operands = [parse_logical_expr(String(strip(p))) for p in parts]
        return LogicalExpr(:and, operands)
    end
    
    # Check for NOT
    if startswith(text, "non")
        inner = String(strip(text[4:end]))
        # Remove parentheses if present
        if startswith(inner, "(") && endswith(inner, ")")
            inner = String(strip(inner[2:end-1]))
        end
        return LogicalExpr(:not, [parse_logical_expr(inner)])
    end
    
    # Otherwise, parse as comparison
    return parse_comparison_expr(text)
end

"""
    parse_comparison_expr(text::String) -> ConditionExpr

Parse comparison expressions (=, !=, <, >, <=, >=).
"""
function parse_comparison_expr(text::String)
    # Try to match comparison operators
    # Order matters: check >= and <= before > and <
    for (pattern, op) in [
        (r">=", :ge),
        (r"<=", :le),
        (r"!=", :ne),
        (r"=", :eq),
        (r">", :gt),
        (r"<", :lt)
    ]
        m = match(pattern, text)
        if m !== nothing
            # Split on the operator
            parts = split(text, pattern, limit=2)
            if length(parts) == 2
                left = parse_atom(String(strip(parts[1])))
                right = parse_atom(String(strip(parts[2])))
                return ComparisonExpr(op, left, right)
            end
        end
    end
    
    # If no comparison operator found, parse as atom
    return parse_atom(text)
end

"""
    parse_atom(text::String) -> ConditionExpr

Parse atomic expressions (variables, literals).
"""
function parse_atom(text::String)
    text = String(strip(text))
    
    # Check if it's a variable (enclosed in *)
    if startswith(text, "*") && endswith(text, "*")
        var_name = text[2:end-1]
        return VariableExpr(var_name)
    end
    
    # Check if it's a boolean literal
    if lowercase(text) in ["true", "vrai", "oui"]
        return LiteralExpr(true, :boolean)
    elseif lowercase(text) in ["false", "faux", "non"]
        return LiteralExpr(false, :boolean)
    end
    
    # Check if it's a number
    try
        # Try integer first
        val = parse(Int, text)
        return LiteralExpr(val, :integer)
    catch
        try
            # Try float
            val = parse(Float64, text)
            return LiteralExpr(val, :float)
        catch
            # Not a number
        end
    end
    
    # Check if it's a string literal (enclosed in quotes)
    if (startswith(text, "\"") && endswith(text, "\"")) ||
       (startswith(text, "'") && endswith(text, "'"))
        return LiteralExpr(text[2:end-1], :string)
    end
    
    # Otherwise, treat as enum/string literal
    return LiteralExpr(text, :enum)
end

"""
    condition_to_string(expr::ConditionExpr) -> String

Convert a ConditionExpr back to a human-readable string.
"""
function condition_to_string(expr::VariableExpr)
    return "*$(expr.name)*"
end

function condition_to_string(expr::LiteralExpr)
    if expr.type == :boolean
        return expr.value ? "Oui" : "Non"
    elseif expr.type == :string
        return "\"$(expr.value)\""
    elseif expr.type == :enum
        return "*$(expr.value)*"
    else
        return string(expr.value)
    end
end

function condition_to_string(expr::ComparisonExpr)
    op_str = Dict(
        :eq => "=",
        :ne => "!=",
        :lt => "<",
        :gt => ">",
        :le => "<=",
        :ge => ">="
    )[expr.op]
    
    return "$(condition_to_string(expr.left)) $(op_str) $(condition_to_string(expr.right))"
end

function condition_to_string(expr::LogicalExpr)
    if expr.op == :not
        return "non ($(condition_to_string(expr.operands[1])))"
    elseif expr.op == :and
        return join([condition_to_string(op) for op in expr.operands], " et ")
    elseif expr.op == :or
        return join([condition_to_string(op) for op in expr.operands], " ou ")
    end
end

"""
    parse_norm_condition(text::String) -> NormCondition

Parse condition text from a norm and return a NormCondition object with parsed expression.
Note: NormCondition is defined in structures/IntermediateRepresentation.jl
"""
function parse_norm_condition(text::String)
    if isempty(strip(text))
        return NormCondition("")
    end
    
    expr = parse_condition(text)
    return NormCondition(text, expr)
end

"""
    conditions_are_equivalent(cond1, cond2) -> Bool

Check if two conditions are semantically equivalent.
Works with NormCondition objects from IntermediateRepresentation.jl
"""
function conditions_are_equivalent(cond1, cond2)
    # If both have parsed expressions, compare them
    if !isnothing(cond1.expr) && !isnothing(cond2.expr)
        return exprs_are_equivalent(cond1.expr, cond2.expr)
    end
    
    # Otherwise, fall back to text comparison
    return cond1.raw_text == cond2.raw_text
end

"""
    exprs_are_equivalent(expr1::ConditionExpr, expr2::ConditionExpr) -> Bool

Check if two condition expressions are semantically equivalent.
"""
function exprs_are_equivalent(expr1::VariableExpr, expr2::VariableExpr)
    return expr1.name == expr2.name
end

function exprs_are_equivalent(expr1::LiteralExpr, expr2::LiteralExpr)
    return expr1.value == expr2.value && expr1.type == expr2.type
end

function exprs_are_equivalent(expr1::ComparisonExpr, expr2::ComparisonExpr)
    return expr1.op == expr2.op &&
           exprs_are_equivalent(expr1.left, expr2.left) &&
           exprs_are_equivalent(expr1.right, expr2.right)
end

function exprs_are_equivalent(expr1::LogicalExpr, expr2::LogicalExpr)
    if expr1.op != expr2.op || length(expr1.operands) != length(expr2.operands)
        return false
    end
    
    # For AND and OR, order doesn't matter (commutative)
    if expr1.op in [:and, :or]
        # Check if all operands in expr1 have an equivalent in expr2
        for op1 in expr1.operands
            found = false
            for op2 in expr2.operands
                if exprs_are_equivalent(op1, op2)
                    found = true
                    break
                end
            end
            if !found
                return false
            end
        end
        return true
    else
        # For NOT, order matters
        return all(exprs_are_equivalent(op1, op2) for (op1, op2) in zip(expr1.operands, expr2.operands))
    end
end

function exprs_are_equivalent(expr1::ConditionExpr, expr2::ConditionExpr)
    # Different types are not equivalent
    return false
end