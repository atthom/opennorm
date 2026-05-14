# ============================================================================
# Procedure Parsing
# ============================================================================

"""
    parse_procedures(ast::CommonMark.Node, document_path::String="")

Parse operational layer procedures from a markdown document.
Procedures are defined as level-2 headings with names in asterisks (e.g., ## *ProcedureName*)
followed by an optional blockquote description and a Case/CumulativeCase construct.

Returns a vector of Procedure structs.
"""
function parse_procedures(ast::CommonMark.Node, document_path::String="")
    procedures = Procedure[]
    
    # Track if we're in the operational layer section
    in_operational_layer = false
    current_procedure_name = nothing
    current_description = nothing
    current_line = 0
    
    for (node, entering) in ast
        if entering && node.t isa Heading
            # Use plain_with_markers to preserve asterisks in headings
            heading_text = strip(plain_with_markers(node))
            
            # Check if we've entered the operational layer
            if node.t.level == 2 && occursin(r"LAYER 2.*OPERATIONAL"i, heading_text)
                in_operational_layer = true
                continue
            end
            
            # Check if we've left the operational layer (entering Layer 3 or beyond)
            if node.t.level == 2 && occursin(r"LAYER [3-9]"i, heading_text)
                in_operational_layer = false
                continue
            end
            
            # Parse procedure headings (## *ProcedureName*)
            if in_operational_layer && node.t.level == 2
                # Match headings with asterisks: ## *VariableName*
                m = match(r"^\*([^*]+)\*$", heading_text)
                if m !== nothing
                    current_procedure_name = m.captures[1]
                    current_description = nothing
                    current_line = node.sourcepos !== nothing ? node.sourcepos[1][1] : 0
                end
            end
        elseif entering && node.t isa BlockQuote && current_procedure_name !== nothing
            # Extract description from blockquote
            current_description = strip(plain(node))
        elseif entering && node.t isa Paragraph && current_procedure_name !== nothing
            # Look for Case:, CumulativeCase:, or simple assignment expressions
            para_text = strip(plain_with_markers(node))
            
            # Skip empty paragraphs
            if isempty(para_text)
                continue
            end
            
            # Check if this is an expression (Case, CumulativeCase, or assignment)
            is_case = startswith(para_text, "Case:") || startswith(para_text, "CumulativeCase:")
            is_assignment = occursin(r"^\*[^*]+\*\s*=\s*", para_text)
            
            if is_case || is_assignment
                # For multi-line expressions, collect all subsequent paragraphs until next heading
                expression_text = para_text
                
                # Look ahead for continuation paragraphs
                found_current = false
                for (lookahead_node, lookahead_entering) in ast
                    if !lookahead_entering
                        continue
                    end
                    
                    # Skip until we find current node
                    if lookahead_node === node
                        found_current = true
                        continue
                    end
                    
                    if !found_current
                        continue
                    end
                    
                    # Stop at next heading
                    if lookahead_node.t isa Heading
                        break
                    end
                    
                    # Collect continuation paragraphs (indented or starting with operators/variables)
                    if lookahead_node.t isa Paragraph
                        continuation_text = strip(plain_with_markers(lookahead_node))
                        # Check if this looks like a continuation (starts with operator or variable)
                        if !isempty(continuation_text) && 
                           (startswith(continuation_text, "-") || 
                            startswith(continuation_text, "+") ||
                            startswith(continuation_text, "*") ||
                            occursin(r"^\s+", plain(lookahead_node)))  # Check original for indentation
                            expression_text *= " " * continuation_text
                        else
                            # Not a continuation, stop
                            break
                        end
                    # Also collect List nodes (for Case expressions with list items)
                    elseif lookahead_node.t isa List
                        list_text = extract_list_for_case(lookahead_node)
                        if !isempty(list_text)
                            expression_text *= "\n" * list_text
                        end
                        break  # Stop after processing list to prevent duplicate processing of items
                    end
                end
                
                # Create location string
                location = if !isempty(document_path)
                    basename(document_path) * ":line $current_line"
                else
                    "line $current_line"
                end
                
                # Parse expression text into ExprNode AST
                # Check if this is a Case expression or simple expression
                parsed_expr = if startswith(expression_text, "Case:") || startswith(expression_text, "CumulativeCase:")
                    parse_case_expression(expression_text)
                else
                    parse_expression_for_type_checking(expression_text)
                end
                
                # Create procedure with both parsed AST and raw text
                proc = Procedure(
                    current_procedure_name,
                    current_description,
                    parsed_expr,      # Parsed expression tree for type checking
                    expression_text,  # Raw text for debugging/display
                    location
                )
                
                push!(procedures, proc)
                
                # Reset for next procedure
                current_procedure_name = nothing
                current_description = nothing
            end
        end
    end
    
    return procedures
end