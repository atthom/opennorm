# ============================================================================
# Utility Functions
# ============================================================================

"""
    plain(node::CommonMark.Node)

Extract plain text from a CommonMark node, handling text, soft breaks, and line breaks.
"""
function plain(node::CommonMark.Node)
    result = String[]
    for (n, entering) in node
        if entering && n.t isa Text
            push!(result, n.literal)
        elseif entering && n.t isa CommonMark.SoftBreak
            push!(result, " ")
        elseif entering && n.t isa CommonMark.LineBreak
            push!(result, " ")
        end
    end
    return join(result, "")
end

"""
    plain_with_markers(node::CommonMark.Node)

Extract text WITH markdown syntax (for ruling parsing).
Reconstructs *emphasis* and **strong** markers.
"""
function plain_with_markers(node::CommonMark.Node)
    result = String[]
    for (n, entering) in node
        if n.t isa Text
            if entering
                push!(result, n.literal)
            end
        elseif n.t isa CommonMark.Emph
            if entering
                push!(result, "*")
            else
                push!(result, "*")
            end
        elseif n.t isa Strong
            if entering
                push!(result, "**")
            else
                push!(result, "**")
            end
        elseif entering && n.t isa CommonMark.SoftBreak
            push!(result, " ")
        elseif entering && n.t isa CommonMark.LineBreak
            push!(result, " ")
        end
    end
    return join(result, "")
end

"""
    extract_list_for_case(list_node::CommonMark.Node, indent_level::Int=0)

Extract list items with proper formatting for Case expressions.
Reconstructs list structure with "- " markers and newlines.
"""
function extract_list_for_case(list_node::CommonMark.Node, indent_level::Int=0)
    result = String[]
    indent = "  " ^ indent_level
    
    for (item, item_entering) in list_node
        if item_entering && item.t isa CommonMark.Item
            # Extract item content (paragraphs and nested lists within the item)
            item_lines = String[]
            nested_list_text = ""
            
            for (child, child_entering) in item
                if child_entering && child.t isa Paragraph
                    # Get the paragraph text with markers
                    para_text = plain_with_markers(child)
                    push!(item_lines, para_text)
                elseif child_entering && child.t isa CommonMark.List
                    # Recursively extract nested list
                    nested_list_text = extract_list_for_case(child, indent_level + 1)
                end
            end
            
            # Format the item
            item_content = join(item_lines, "\n$(indent)      ")
            if !isempty(item_content)
                # Check if this is a condition:value pair
                if occursin(":", item_content)
                    # Split on first colon to separate condition from value
                    parts = split(item_content, ":", limit=2)
                    if length(parts) == 2
                        condition = strip(parts[1])
                        value = strip(parts[2])
                        
                        # If there's a nested list, append it to the value
                        if !isempty(nested_list_text)
                            # Format as: "  - condition:\n      value\n      nested_list"
                            push!(result, "$(indent)  - $(condition):\n$(indent)      $(value)\n$(nested_list_text)")
                        else
                            # Format as: "  - condition:\n      value"
                            push!(result, "$(indent)  - $(condition):\n$(indent)      $(value)")
                        end
                    else
                        push!(result, "$(indent)  - $(item_content)")
                    end
                else
                    push!(result, "$(indent)  - $(item_content)")
                end
            elseif !isempty(nested_list_text)
                # Item has only a nested list, no paragraph content
                push!(result, nested_list_text)
            end
        end
    end
    
    return join(result, "\n")
end

"""
    process_list_items(list_node, callback)

Process list items with a callback function.
"""
function process_list_items(list_node, callback)
    for (item, item_entering) in list_node
        if item_entering && item.t isa CommonMark.Item
            callback(item)
        end
    end
end

"""
    to_string(s::Union{String, SubString{String}})

Convert SubString to String.
"""
to_string(s::Union{String, SubString{String}}) = String(s)

"""
    extract_all_kvs(paragraph)

Extract all key-value pairs from a paragraph containing multiple **Key:** value pairs.
"""
function extract_all_kvs(paragraph)
    kvs = Dict{String, String}()
    current_key = nothing
    current_value = ""
    in_strong = false
    
    for (node, entering) in paragraph
        if node.t isa Strong
            if entering
                # Save previous key-value pair if exists
                if current_key !== nothing && !isempty(strip(current_value))
                    kvs[lowercase(strip(current_key))] = strip(current_value)
                end
                # Start new key
                in_strong = true
                current_key = replace(plain(node), ":" => "")
                current_value = ""
            else
                in_strong = false
            end
        elseif node.t isa Text && current_key !== nothing && !in_strong
            # Collect text for current key (only text outside Strong elements)
            # Remove the key prefix if it appears in the text
            text = node.literal
            # Remove "Key: " pattern from the beginning
            text = replace(text, r"^[^:]+:\s*" => "")
            current_value *= text
        end
    end
    
    # Save last key-value pair
    if current_key !== nothing && !isempty(strip(current_value))
        kvs[lowercase(strip(current_key))] = strip(current_value)
    end
    
    return kvs
end

"""
Safe accessors for CommonMark.Node fields that may be uninitialized.
"""
function cm_first_child(node::CommonMark.Node)
    try
        return node.first_child
    catch e
        e isa UndefRefError && return nothing
        rethrow(e)
    end
end

function cm_nxt(node::CommonMark.Node)
    try
        return node.nxt
    catch e
        e isa UndefRefError && return nothing
        rethrow(e)
    end
end

function cm_parent(node::CommonMark.Node)
    try
        return node.parent
    catch e
        e isa UndefRefError && return nothing
        rethrow(e)
    end
end