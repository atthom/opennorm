# Procedure Validation Integration Guide

**Status:** Implementation Guide  
**Date:** 2026-05-12  
**Purpose:** Document how to integrate dimensional analysis validation with operational layer procedures

---

## Overview

The dimensional analysis system is now set up and ready to validate procedures. When operational layer procedure parsing is implemented, dimensional validation can be integrated with minimal changes.

## Current State

### What's Already Implemented

1. **Unit System** (`src/julia/unit_system.jl`)
   - Dynamic unit extraction from Object Taxonomy
   - Unit registration with Unitful.jl
   - Type environment builder from taxonomy variables
   - Variable type annotation parser

2. **Type Checker** (`src/julia/type_checker.jl`)
   - Expression AST types (VariableRef, BinaryOp, FunctionCall, LiteralValue)
   - Dimension inference for expressions
   - `validate_computed_variable()` function
   - Detailed error reporting with suggestions

3. **Parser Integration** (`src/julia/parser.jl`)
   - Dimensional analysis section after norm validation
   - Unit extraction and registration
   - Type environment building
   - Integration point marked with TODO comment (lines 127-137)

### What's Needed

1. **Procedure Struct** - Define structure to hold procedure information
2. **Procedure Parser** - Extract procedures from markdown AST
3. **Expression Parser** - Convert markdown expressions to AST nodes
4. **Validation Call** - Invoke `validate_computed_variable()` for each procedure

---

## Integration Steps

### Step 1: Define Procedure Structure

Add to `src/julia/structures.jl`:

```julia
# Procedure representation for operational layer
struct Procedure
    name::String                    # Output variable name (e.g., "RevenuImposable")
    description::String             # Optional description from blockquote
    expression::Union{ExprAST, Nothing}  # Parsed expression AST
    source_text::String             # Original markdown text for error reporting
end
```

### Step 2: Implement Procedure Parser

Add to `src/julia/parser.jl`:

```julia
# Parse all procedures from the AST
function parse_procedures(ast, objects::Taxon{Object})
    procedures = Procedure[]
    
    for (node, entering) in ast
        if !entering
            continue
        end
        
        # Look for H2 headings with *italics* (procedure declarations)
        if node.t isa Heading && node.t.level == 2
            title = plain(node)
            
            # Check if this is a procedure (wrapped in *italics*)
            m = match(r"^\*(\w+)\*$", strip(title))
            if m !== nothing
                proc_name = m.captures[1]
                
                # Extract description and expression
                description, expr_text = extract_procedure_body(ast, node)
                
                # Parse expression to AST
                expression = parse_expression_for_type_checking(expr_text, objects)
                
                proc = Procedure(proc_name, description, expression, expr_text)
                push!(procedures, proc)
            end
        end
    end
    
    return procedures
end

# Extract procedure body (description and expression)
function extract_procedure_body(ast, header_node)
    description = ""
    expr_text = ""
    found_header = false
    
    for (node, entering) in ast
        if !entering
            continue
        end
        
        if node === header_node
            found_header = true
            continue
        end
        
        if !found_header
            continue
        end
        
        # Extract description from blockquote
        if node.t isa BlockQuote
            description = plain(node)
            continue
        end
        
        # Extract expression from paragraph or Case/CumulativeCase
        if node.t isa Paragraph
            text = plain_with_markers(node)
            # Check if this is an assignment or Case statement
            if occursin("=", text) || occursin("Case:", text)
                expr_text = text
                break
            end
        end
        
        # Stop at next heading
        if node.t isa Heading
            break
        end
    end
    
    return (description, expr_text)
end
```

### Step 3: Implement Expression Parser

Add to `src/julia/type_checker.jl`:

```julia
# Parse markdown expression text into AST for type checking
function parse_expression_for_type_checking(expr_text::String, objects::Taxon{Object})
    # Remove leading variable assignment if present
    # e.g., "*RevenuImposable* = ..." -> "..."
    expr_text = replace(expr_text, r"^\*\w+\*\s*=\s*" => "")
    
    # Parse based on expression type
    if occursin("Case:", expr_text)
        return parse_case_expression(expr_text, objects)
    elseif occursin("CumulativeCase", expr_text)
        return parse_cumulative_case_expression(expr_text, objects)
    else
        return parse_arithmetic_expression(expr_text, objects)
    end
end

# Parse simple arithmetic expression
function parse_arithmetic_expression(expr::String, objects::Taxon{Object})
    # Handle operators: +, -, ×, /
    # Handle functions: min, max, sum, round, ceil, floor
    # Handle variables: *VariableName*
    # Handle literals: numbers with units (e.g., "13 522 EUR", "10%")
    
    # This is a simplified example - full implementation needs proper parsing
    
    # Check for binary operations
    for op in ["×", "/", "+", "-"]
        if occursin(op, expr)
            parts = split(expr, op, limit=2)
            if length(parts) == 2
                left = parse_arithmetic_expression(strip(parts[1]), objects)
                right = parse_arithmetic_expression(strip(parts[2]), objects)
                return BinaryOp(op, left, right)
            end
        end
    end
    
    # Check for function calls
    if occursin(r"^(min|max|sum|round|ceil|floor)\(", expr)
        return parse_function_call(expr, objects)
    end
    
    # Check for variable reference
    m = match(r"^\*(\w+)\*$", strip(expr))
    if m !== nothing
        return VariableRef(m.captures[1])
    end
    
    # Check for literal value
    m = match(r"^([\d\s]+)\s*(\w+)$", strip(expr))
    if m !== nothing
        value_str = replace(m.captures[1], " " => "")
        value = parse(Float64, value_str)
        unit = m.captures[2]
        return LiteralValue(value, unit)
    end
    
    # Fallback
    @warn "Could not parse expression: $expr"
    return nothing
end

# Parse Case expression (returns first branch for now - full implementation needed)
function parse_case_expression(expr_text::String, objects::Taxon{Object})
    # Extract branches and parse each result expression
    # For now, return a placeholder
    # Full implementation would need to handle all branches
    return VariableRef("CaseResult")
end

# Parse CumulativeCase expression
function parse_cumulative_case_expression(expr_text::String, objects::Taxon{Object})
    # Similar to Case but accumulates results
    return VariableRef("CumulativeCaseResult")
end

# Parse function call
function parse_function_call(expr::String, objects::Taxon{Object})
    # Extract function name and arguments
    m = match(r"^(\w+)\((.*)\)$", strip(expr))
    if m !== nothing
        func_name = m.captures[1]
        args_text = m.captures[2]
        
        # Parse arguments
        args = ExprAST[]
        for arg_text in split(args_text, ",")
            arg = parse_arithmetic_expression(strip(arg_text), objects)
            if arg !== nothing
                push!(args, arg)
            end
        end
        
        return FunctionCall(func_name, args)
    end
    
    return nothing
end
```

### Step 4: Integrate Validation

Replace the TODO section in `src/julia/parser.jl` (lines 127-137) with:

```julia
# Parse procedures and validate their dimensional consistency
procedures = parse_procedures(ast, objects)
if !isempty(procedures)
    println("Validating $(length(procedures)) procedures...")
    
    validation_errors = 0
    for proc in procedures
        try
            if proc.expression !== nothing
                validate_computed_variable(
                    proc.name, 
                    proc.expression, 
                    type_env, 
                    proc.name
                )
            end
        catch e
            if e isa DimensionalMismatchError
                showerror(stderr, e)
                println(stderr)
                validation_errors += 1
            else
                rethrow(e)
            end
        end
    end
    
    if validation_errors > 0
        println(stderr, "⚠️  $validation_errors procedure(s) failed dimensional validation\n")
    else
        println("✓ All procedures passed dimensional validation")
    end
end

println("✓ Dimensional analysis setup complete (ready for procedure validation)")
```

---

## Example Usage

Once integrated, the system will automatically validate procedures like:

```markdown
## *RevenuImposable*

> Calcul du revenu imposable après déduction de tous les déficits et charges

*RevenuImposable* = *RevenuGlobal*
                    - *DéficitAgricoleImputable*
                    - *DéficitBICImputable*
```

If `*RevenuGlobal*` is declared as `EUR` but `*DéficitAgricoleImputable*` is declared as `EUR²`, the validator will report:

```
❌ Dimensional Mismatch in Procedure: RevenuImposable

Expected dimension: EUR
Inferred dimension: EUR²

The expression produces EUR² but the output variable expects EUR.

Suggestion: Check the types of variables used in the expression.
```

---

## Testing

Create test file `test_procedure_validation.jl`:

```julia
using Test
include("src/julia/opennorm.jl")

@testset "Procedure Validation" begin
    # Test valid procedure
    doc = parse_document("documents/articles/CGI.Art.156.opennorm.md")
    # Should complete without errors
    
    # Test invalid procedure (would need test document with dimensional error)
    # @test_throws DimensionalMismatchError parse_document("test_invalid_dimensions.md")
end
```

---

## Notes

1. **Expression Parsing Complexity**: The expression parser shown above is simplified. A full implementation would need:
   - Proper operator precedence handling
   - Parentheses support
   - Multi-line expression handling
   - Case/CumulativeCase branch parsing

2. **Performance**: For large documents with many procedures, consider:
   - Caching parsed expressions
   - Parallel validation of independent procedures
   - Incremental validation on document changes

3. **Error Recovery**: The current implementation stops at first error. Consider:
   - Collecting all errors before reporting
   - Continuing validation even after errors
   - Providing fix suggestions

4. **Future Enhancements**:
   - Validate Case exhaustiveness with dimensional constraints
   - Check CumulativeCase band dimensions
   - Infer missing type annotations
   - Generate type signatures for procedures

---

## Summary

The dimensional analysis infrastructure is complete and ready for integration. When operational layer parsing is implemented:

1. Add Procedure struct to structures.jl
2. Implement parse_procedures() in parser.jl
3. Implement parse_expression_for_type_checking() in type_checker.jl
4. Replace TODO comment with validation loop

The system will then automatically validate that all procedure expressions produce the correct dimensions for their output variables.