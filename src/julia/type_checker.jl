using Unitful

# Note: ExprNode types are now defined in structures.jl as part of the unified IRNode hierarchy
# ExprNode <: OperationalNode <: IRNode
# Note: DimensionalMismatchError is now defined in structures/exceptions.jl

"""
    infer_dimension(expr::ExprNode, type_env::Dict{String, Unitful.FreeUnits})

Infer the dimensional type of an expression using Unitful's dimensional analysis.
Returns a Unitful.FreeUnits representing the result dimension.

This function uses multiple dispatch to handle different expression types.
"""
infer_dimension(expr::ExprNode, type_env::Dict{String, Unitful.FreeUnits}) = Unitful.NoUnits

# VariableRef: Look up variable in type environment
function infer_dimension(expr::VariableRef, type_env::Dict{String, Unitful.FreeUnits})
    if haskey(type_env, expr.name)
        return type_env[expr.name]
    else
        # Variable not in type environment - assume dimensionless
        @warn "Variable $(expr.name) not found in type environment, assuming dimensionless"
        return Unitful.NoUnits
    end
end

# LiteralValue: Parse literal with unit
function infer_dimension(expr::LiteralValue, type_env::Dict{String, Unitful.FreeUnits})
    if expr.unit !== nothing
        # Literal has explicit unit: "10 EUR", "5%"
        if haskey(UNIT_REGISTRY, expr.unit)
            return UNIT_REGISTRY[expr.unit]
        else
            @warn "Unknown unit $(expr.unit) in literal, assuming dimensionless"
            return Unitful.NoUnits
        end
    else
        # Literal without unit is dimensionless
        return Unitful.NoUnits
    end
end

# BinaryOp: Apply dimensional algebra based on operation
function infer_dimension(expr::BinaryOp, type_env::Dict{String, Unitful.FreeUnits})
    # Infer dimensions of operands
    left_dim = infer_dimension(expr.left, type_env)
    right_dim = infer_dimension(expr.right, type_env)
    
    # Validate dimension compatibility for operations that require it
    if expr.op in (:+, :-) && dimension(left_dim) != dimension(right_dim)
        op_name = expr.op == :+ ? "add" : "subtract"
        error("Cannot $op_name quantities with different dimensions: $(left_dim) $(expr.op) $(right_dim)")
    end
    
    # Apply dimensional algebra based on operation
    return apply_dimensional_algebra(Val(expr.op), left_dim, right_dim)
end

apply_dimensional_algebra(::Val{:+}, left_dim, right_dim) = left_dim
apply_dimensional_algebra(::Val{:-}, left_dim, right_dim) = left_dim

function apply_dimensional_algebra(::Val{:*}, left_dim, right_dim)
    # Multiplication: dimensions multiply
    # Special case: dimensionless * X = X (for percentages)
    if dimension(left_dim) == Unitful.NoDims
        return right_dim
    elseif dimension(right_dim) == Unitful.NoDims
        return left_dim
    else
        # Both have dimensions - multiply them
        return left_dim * right_dim
    end
end

function apply_dimensional_algebra(::Val{:/}, left_dim, right_dim)
    # Division: dimensions divide
    if dimension(right_dim) == Unitful.NoDims
        return left_dim
    else
        return left_dim / right_dim
    end
end

# UnaryOp: Preserve dimension of operand
infer_dimension(expr::UnaryOp, type_env::Dict{String, Unitful.FreeUnits}) = infer_dimension(expr.operand, type_env)


# FunctionCall: Function-specific dimensional rules
function infer_dimension(expr::FunctionCall, type_env::Dict{String, Unitful.FreeUnits})
    # Infer dimensions of arguments
    arg_dims = [infer_dimension(arg, type_env) for arg in expr.args]
    
    # Dispatch based on function name
    if expr.func in [:min, :max, :sum]
        # All these functions require same dimensions and preserve dimension
        return infer_dimension_same_args(expr.func, arg_dims)
    else
        # Unknown function - assume dimensionless
        return Unitful.NoUnits
    end
end

# Helper for functions that require all arguments to have the same dimension
# Used by min, max, sum - all preserve dimension and require dimensional consistency
function infer_dimension_same_args(func::Symbol, arg_dims::Vector)
    if length(arg_dims) > 0
        first_dim = arg_dims[1]
        # Verify all arguments have the same dimension
        for dim in arg_dims[2:end]
            if dimension(dim) != dimension(first_dim)
                error("$(func) requires all arguments to have the same dimension: got $(first_dim) and $(dim)")
            end
        end
        return first_dim
    else
        return Unitful.NoUnits
    end
end

# CaseExprNode: All branches must have the same dimension
function infer_dimension(expr::CaseExprNode, type_env::Dict{String, Unitful.FreeUnits})
    # Case/CumulativeCase expression: all branches must have the same dimension
    # Both Case and CumulativeCase have the same dimensional analysis requirements
    if length(expr.branches) > 0
        # Collect dimensions from all branches
        branch_dims = [infer_dimension(result, type_env) for (condition, result) in expr.branches]
        
        # Find the first non-dimensionless dimension (if any)
        # This handles cases where some branches are literal 0 (dimensionless) 
        # and others have explicit units like "0 EUR"
        inferred_dim = Unitful.NoUnits
        for dim in branch_dims
            if dimension(dim) != Unitful.NoDims
                inferred_dim = dim
                break
            end
        end
        
        # Now check all branches are compatible with the inferred dimension
        for (i, dim) in enumerate(branch_dims)
            # Allow dimensionless values (like literal 0) to be compatible with any dimension
            if dimension(dim) != Unitful.NoDims && dimension(dim) != dimension(inferred_dim)
                case_type = expr isa CaseExpression ? "Case" : "CumulativeCase"
                error("$case_type branch $i has dimension $dim, but expected dimension is $inferred_dim")
            end
        end
        
        return inferred_dim
    else
        return Unitful.NoUnits
    end
end

"""
    validate_computed_variable(var_name::String, 
                               expression::ExprNode,
                               type_env::Dict{String, Unitful.FreeUnits},
                               location::String)

Validate that a computed variable's expression produces the correct dimension.
Throws DimensionalMismatchError if dimensions don't match.
"""
function validate_computed_variable(var_name::String, 
                                   expression::ExprNode,
                                   type_env::Dict{String, Unitful.FreeUnits},
                                   location::String)
    # Get declared type
    if !haskey(type_env, var_name)
        @warn "Computed variable $(var_name) has no type declaration in taxonomy"
        return  # Skip validation if no type declared
    end
    
    declared_type = type_env[var_name]
    
    # Infer type from expression
    inferred_type = infer_dimension(expression, type_env)
    
    # Compare dimensions
    if dimension(declared_type) != dimension(inferred_type)
        throw(DimensionalMismatchError(
            var_name,
            declared_type,
            inferred_type,
            expr_to_string(expression),
            location
        ))
    end
end

"""
    expr_to_string(expr::ExprNode)

Convert an expression AST back to a readable string for error messages.

This function uses multiple dispatch to handle different expression types.
"""
function expr_to_string(expr::ExprNode)
    # Fallback for unknown expression types
    return "<?>"
end

# VariableRef: Format as *name*
function expr_to_string(expr::VariableRef)
    return "*$(expr.name)*"
end

# LiteralValue: Format with or without unit
function expr_to_string(expr::LiteralValue)
    if expr.unit !== nothing
        return "$(expr.value) $(expr.unit)"
    else
        return string(expr.value)
    end
end

# BinaryOp: Format as "left op right"
function expr_to_string(expr::BinaryOp)
    left_str = expr_to_string(expr.left)
    right_str = expr_to_string(expr.right)
    op_str = if expr.op == :*
        "×"
    elseif expr.op == :/
        "/"
    else
        string(expr.op)
    end
    return "$(left_str) $(op_str) $(right_str)"
end

# UnaryOp: Format as "op(operand)"
function expr_to_string(expr::UnaryOp)
    operand_str = expr_to_string(expr.operand)
    return "$(expr.op)($(operand_str))"
end

# FunctionCall: Format as "func(args...)"
function expr_to_string(expr::FunctionCall)
    args_str = join([expr_to_string(arg) for arg in expr.args], ", ")
    return "$(expr.func)($(args_str))"
end

"""
    parse_expression_for_type_checking(text::Union{String, SubString{String}})

Parse an expression string into an ExprNode AST for type checking.
This is a simplified parser focused on extracting structure for dimensional analysis.
"""
function parse_expression_for_type_checking(text::Union{String, SubString{String}})
    text = String(strip(text))
    
    # Handle empty text - return a dimensionless literal 0
    # This can happen with continuation lines in multi-line expressions
    if isempty(text)
        return LiteralValue(0, nothing)
    end
    
    # Handle assignment expressions: *Variable* = expression
    # Strip off the left-hand side and only parse the right-hand side
    m = match(r"^\*([^*]+)\*\s*=\s*(.+)$", text)
    if m !== nothing
        # Only parse the right-hand side (the expression being assigned)
        text = String(strip(m.captures[2]))
    end
    
    # Try to parse as binary operation
    # Look for operators at the top level (not inside parentheses or function calls)
    # Scan from RIGHT to LEFT to handle operator precedence correctly
    # (rightmost + or - has lowest precedence)
    depth = 0
    last_add_sub = 0
    indices = collect(eachindex(text))
    for i in reverse(indices)
        c = text[i]
        if c == ')'
            depth += 1
        elseif c == '('
            depth -= 1
        elseif depth == 0
            # Check for + or - with proper whitespace handling
            if c == '+' || c == '-'
                # Make sure it's not part of a number (e.g., "1e-5")
                idx_pos = findfirst(==(i), indices)
                if idx_pos > 1 && idx_pos < length(indices)
                    prev_idx = indices[idx_pos - 1]
                    prev_char = text[prev_idx]
                    # Skip if it's part of scientific notation
                    if prev_char == 'e' || prev_char == 'E'
                        continue
                    end
                    last_add_sub = i
                    break
                elseif idx_pos == 1
                    # Unary operator at start - skip for now
                    continue
                else
                    last_add_sub = i
                    break
                end
            end
        end
    end
    
    if last_add_sub > 0
        i = last_add_sub
        c = text[i]
        left = String(strip(text[1:prevind(text, i)]))
        right = String(strip(text[nextind(text, i):end]))
        # Skip if either side is empty
        if isempty(left) || isempty(right)
            # This might be a unary operator, skip it
        else
            op = c == '+' ? :+ : :-
            return BinaryOp(op, 
                          parse_expression_for_type_checking(left),
                          parse_expression_for_type_checking(right))
        end
    end
    
    # Look for multiplication/division (higher precedence)
    depth = 0
    last_mul_div = 0
    for i in reverse(indices)
        c = text[i]
        if c == ')'
            depth += 1
        elseif c == '('
            depth -= 1
        elseif depth == 0
            if c == '×' || c == '*' || c == '/'
                last_mul_div = i
                break
            end
        end
    end
    
    if last_mul_div > 0
        i = last_mul_div
        c = text[i]
        left = String(strip(text[1:prevind(text, i)]))
        right = String(strip(text[nextind(text, i):end]))
        # Skip if either side is empty
        if isempty(left) || isempty(right)
            # Invalid expression
        else
            op = (c == '×' || c == '*') ? :* : :/
            return BinaryOp(op,
                          parse_expression_for_type_checking(left),
                          parse_expression_for_type_checking(right))
        end
    end
    
    # Try to parse as function call
    m = match(r"^(\w+)\s*\((.*)\)\s*$", text)
    if m !== nothing
        func_name = Symbol(m.captures[1])
        args_text = m.captures[2]
        
        # Split arguments by comma, respecting nested parentheses
        args = String[]
        current_arg = ""
        depth = 0
        for c in args_text
            if c == '('
                depth += 1
                current_arg *= c
            elseif c == ')'
                depth -= 1
                current_arg *= c
            elseif c == ',' && depth == 0
                push!(args, strip(current_arg))
                current_arg = ""
            else
                current_arg *= c
            end
        end
        if !isempty(strip(current_arg))
            push!(args, strip(current_arg))
        end
        
        parsed_args = [parse_expression_for_type_checking(arg) for arg in args]
        
        # Check if this is a unary operation (single argument, dimension-preserving function)
        if length(parsed_args) == 1 && func_name in [:round, :ceil, :floor, :abs, :sqrt]
            return UnaryOp(func_name, parsed_args[1])
        else
            return FunctionCall(func_name, parsed_args)
        end
    end
    
    # Try to parse as variable reference (in *italics*)
    m = match(r"^\*([^*]+)\*$", text)
    if m !== nothing
        return VariableRef(strip(m.captures[1]))
    end
    
    # Try to parse as literal with unit (improved regex to handle leading zeros)
    m = match(r"^(\d+(?:[.,]\d+)?)\s+([A-Z%]+)$", text)
    if m !== nothing
        value_str = replace(m.captures[1], "," => ".")
        value = parse(Float64, value_str)
        unit = m.captures[2]
        return LiteralValue(value, unit)
    end
    
    # Try to parse as plain number
    try
        value = parse(Float64, replace(text, "," => "."))
        return LiteralValue(value, nothing)
    catch
    end
    
    # If nothing else works, treat as variable name without asterisks
    # This handles cases where variables are referenced without markdown formatting
    return VariableRef(text)
end

"""
    parse_case_expression(text::String)

Parse a Case or CumulativeCase construct into a CaseExpression or CumulativeCaseExpression AST.
Format:
  Case:
    - condition1:
        result1
    - condition2:
        result2
    - Default:
        default_result
"""
function parse_case_expression(text::String)
    text = strip(text)
    
    # Check if it starts with Case: or CumulativeCase:
    if !startswith(text, "Case:") && !startswith(text, "CumulativeCase:")
        error("Expected Case: or CumulativeCase:, got: $(first(text, min(50, length(text))))")
    end
    
    # Determine which type to create
    is_cumulative = startswith(text, "CumulativeCase:")
    
    # Remove the "Case:" or "CumulativeCase:" prefix
    text = replace(text, r"^(Case|CumulativeCase):\s*" => "")
    
    # Check if this is an inline format (all on one line with no newlines)
    # Example: "- condition1: result1 - condition2: result2"
    if !occursin('\n', text)
        # Split on " - " that's followed by either a condition (with =) or "Default:"
        # This avoids splitting on "-" that's part of arithmetic expressions
        text = replace(text, r"\s+-\s+(?=\*[^:]+\*\s*=|Default:)" => "\n  - ")
    end
    
    # Split into branches by looking for lines starting with "-"
    branches = Tuple{Union{ExprNode, Nothing}, ExprNode}[]
    
    # Split by newlines and process
    lines = split(text, '\n')
    i = 1
    while i <= length(lines)
        line = strip(lines[i])
        
        # Skip empty lines
        if isempty(line)
            i += 1
            continue
        end
        
        # Check if this is a branch marker (starts with -)
        if startswith(line, "-")
            # Extract condition part (everything after - and before :)
            condition_match = match(r"^-\s*(.+?):\s*$", line)
            if condition_match === nothing
                i += 1
                continue
            end
            
            condition_text = strip(condition_match.captures[1])
            
            # Check if this is the Default branch
            is_default = condition_text == "Default"
            
            # Collect result lines (indented lines following the condition)
            result_lines = String[]
            i += 1
            while i <= length(lines)
                result_line = lines[i]
                # Check if line is indented (starts with spaces) but is not a new branch marker
                stripped_line = strip(result_line)
                if (startswith(result_line, " ") || startswith(result_line, "\t")) && !startswith(stripped_line, "-")
                    push!(result_lines, stripped_line)
                    i += 1
                else
                    break
                end
            end
            
            # Parse result expression
            result_text = join(result_lines, " ")
            if !isempty(result_text)
                # Check if result is a nested Case expression
                if startswith(strip(result_text), "Case:")
                    # Recursively parse nested Case expression
                    result_expr = parse_case_expression(result_text)
                else
                    result_expr = parse_expression_for_type_checking(result_text)
                end
                
                # Parse condition (or nothing for Default)
                if is_default
                    push!(branches, (nothing, result_expr))
                else
                    condition_expr = parse_condition_expression(condition_text)
                    push!(branches, (condition_expr, result_expr))
                end
            end
        else
            i += 1
        end
    end
    
    # Return appropriate type based on whether it's cumulative
    if is_cumulative
        return CumulativeCaseExpression(branches)
    else
        return CaseExpression(branches)
    end
end

"""
    parse_condition_expression(text::Union{String, SubString{String}})

Parse a condition expression (comparison or logical operation).
Examples:
  - *Variable* > *OtherVariable*
  - *Variable* = *Value*
  - *Var1* = *Val1* AND *Var2* = *Val2*
"""
function parse_condition_expression(text::Union{String, SubString{String}})
    text = String(strip(text))
    
    # Parse logical AND/OR operators first (lowest precedence)
    if occursin(" AND ", text)
        parts = split(text, " AND ", limit=2)
        left = parse_condition_expression(strip(parts[1]))
        right = parse_condition_expression(strip(parts[2]))
        return BinaryOp(:AND, left, right)
    elseif occursin(" OR ", text)
        parts = split(text, " OR ", limit=2)
        left = parse_condition_expression(strip(parts[1]))
        right = parse_condition_expression(strip(parts[2]))
        return BinaryOp(:OR, left, right)
    end
    
    # Parse comparison operators
    # Try each comparison operator in order
    for (op_str, op_sym) in [(" = ", :(==)), (" == ", :(==)), (" != ", :!=), 
                              (" >= ", :>=), (" <= ", :<=), (" > ", :>), (" < ", :<)]
        if occursin(op_str, text)
            parts = split(text, op_str, limit=2)
            if length(parts) == 2
                left = parse_expression_for_type_checking(strip(parts[1]))
                right = parse_expression_for_type_checking(strip(parts[2]))
                return BinaryOp(op_sym, left, right)
            end
        end
    end
    
    # If no operator found, try to parse as a simple expression
    return parse_expression_for_type_checking(text)
end
