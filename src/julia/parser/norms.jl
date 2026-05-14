# ============================================================================
# Norm Parsing
# ============================================================================

# Global dictionary to store norm texts for error reporting
const NORM_TEXTS = Dict{String, String}()

"""
    parse_norms(ast, package_name)

Parse all norms from the AST.
"""
function parse_norms(ast, package_name)
    norms = Norm[]
    current_annotations = String[]
    
    # Clear previous norm texts
    empty!(NORM_TEXTS)
    
    for (node, entering) in ast
        if !entering
            continue
        end
        
        t = node.t
        
        # Check for blockquote annotations before norms
        if t isa BlockQuote
            current_annotations = extract_annotations(node)
        # Check for norm headers (H3 that are not taxonomy sections)
        elseif t isa Heading && t.level == 3
            title = plain(node)
            # Skip taxonomy sections
            if !occursin("Taxonomy", title)
                # Parse the norm
                norm = parse_norm(ast, node, title, current_annotations, package_name)
                if norm !== nothing
                    push!(norms, norm)
                end
                current_annotations = String[]
            end
        end
    end
    
    return norms
end

"""
    extract_annotations(blockquote_node)

Extract annotations from blockquote (skip, overrules).
"""
function extract_annotations(blockquote_node)
    annotations = String[]
    text = plain(blockquote_node)
    
    # Check for skip directive
    if occursin(r"skip"i, text)
        push!(annotations, "skip")
    end
    
    # Check for overrules directive
    m = match(r"overrules\s+#([\w-]+)", text)
    if m !== nothing
        push!(annotations, "overrules:#$(m.captures[1])")
    end
    
    return annotations
end

"""
    parse_norm(ast, header_node, title, annotations, package_name)

Parse a single norm starting from its H3 header.
"""
function parse_norm(ast, header_node, title, annotations, package_name)
    # Generate ref_id from title
    ref_id = lowercase(replace(strip(title), r"\s+" => "-"))
    
    # Check if skipped
    skipped = "skip" in annotations
    
    # Find overrules references
    overrules = Norm[]
    for ann in annotations
        if startswith(ann, "overrules:")
            # Store reference for later resolution
            # For now, we'll leave it empty
        end
    end
    
    # Find the paragraph after the header that contains the norm body
    # Skip blockquotes (descriptions) and only look for paragraphs with the norm syntax
    found_header = false
    for (node, entering) in ast
        if !entering
            continue
        end
        
        # Skip until we find our header
        if node === header_node
            found_header = true
            continue
        end
        
        if !found_header
            continue
        end
        
        # Skip blockquotes (they are descriptions, not norms)
        if node.t isa BlockQuote
            continue
        end
        
        # Look for the paragraph with the norm
        if node.t isa Paragraph
            norm_text = plain_with_markers(node)
            
            # Check if this looks like a norm (contains * and **)
            if occursin(r"\*[^*]+\*\s+\*\*[^*]+\*\*", norm_text)
                # Parse the norm body
                return parse_norm_body(ref_id, norm_text, skipped, overrules, package_name)
            end
        end
        
        # Stop if we hit another heading
        if node.t isa Heading
            break
        end
    end
    
    return nothing
end

"""
    parse_norm_body(ref_id, norm_text, skipped, overrules, package_name)

Parse the norm body text.
"""
function parse_norm_body(ref_id, norm_text, skipped, overrules, package_name)
    # Store the norm text for error reporting
    NORM_TEXTS[ref_id] = norm_text
    
    # Normalize whitespace: replace newlines and multiple spaces with single space
    # This handles multi-line norms
    normalized_text = replace(norm_text, r"\s+" => " ")
    
    # Extract components using regex patterns
    # Pattern: *Actor* **H-keyword** *action(s)* *object* to/from/by/over *Counterparty*
    # Actions can be comma-separated: *action1*, *action2*, *action3*
    
    # Enhanced pattern to support free text between elements (e.g., French articles: le, un, à l')
    # Matches: [optional text] *Actor* [optional text] **keyword** [optional text] *action*, *action*, ... [optional text] *object* [optional text] to/from/by/over [optional text] *Counterparty*
    # The (?:.*?) allows any text (including articles) between marked elements
    pattern = r"(?:.*?)\*([^*]+)\*(?:.*?)\*\*([^*]+)\*\*(?:.*?)((?:\*[^*]+\*(?:,\s*)?)+)(?:.*?)\*([^*]+)\*(?:.*?)(to|from|by|over|envers|à|au|aux|de|du|des|par|sur)(?:.*?)\*([^*]+)\*"
    m = match(pattern, normalized_text)
    
    if m === nothing
        @warn "Could not parse norm body: $normalized_text"
        return nothing
    end
    
    actor_name = String(strip(m.captures[1]))
    h_keyword = String(strip(m.captures[2]))
    actions_text = String(strip(m.captures[3]))
    object_name = String(strip(m.captures[4]))
    preposition = String(strip(m.captures[5]))
    counterparty_name = String(strip(m.captures[6]))
    
    # Map H-keyword to Position using get_position from structures
    position = get_position(h_keyword)
    if position === nothing
        @warn "Unknown Hohfeldian keyword: $h_keyword"
        return nothing
    end
    
    # For now, create simple taxons (will need proper taxonomy resolution)
    actor = Taxon(Role, actor_name)
    counterparty = Taxon(Role, counterparty_name)
    
    # Parse actions (comma-separated)
    actions = parse_actions(actions_text)
    action = if !isempty(actions)
        Taxon(Action, actions[1])  # Use first action for now
    else
        Taxon(Action, "")
    end
    
    # Parse object
    object = Taxon(Object, object_name)
    
    # Create the norm
    return Norm(
        ref_id=ref_id,
        package=package_name,
        Hohfeld=position,
        actor=actor,
        action=action,
        object=object,
        counterparty=counterparty,
        overrules=overrules,
        skipped=skipped,
        text=norm_text
    )
end

"""
    parse_actions(actions_text)

Parse comma-separated actions.
"""
function parse_actions(actions_text)
    actions = String[]
    # Extract all *action* patterns from the text
    # Pattern matches: *action_name*
    for m in eachmatch(r"\*([^*]+)\*", actions_text)
        action_name = strip(m.captures[1])
        if !isempty(action_name)
            push!(actions, action_name)
        end
    end
    return actions
end

"""
    parse_condition(condition_text)

Parse condition clause (when ...).
For now, returns nothing (to be implemented).
"""
function parse_condition(condition_text)
    # Pattern: when *X* has *V* *O*
    # For now, return nothing (to be implemented)
    return nothing
end