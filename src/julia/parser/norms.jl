# ============================================================================
# Norm Parsing
# ============================================================================

# Global dictionary to store norm texts for error reporting
const NORM_TEXTS = Dict{String, String}()

"""
    parse_norms(ast, package_name)

Parse all norms from the AST.
Uses a two-pass approach:
1. First pass: parse all non-exception norms
2. Second pass: parse exception norms (which can reference norms from first pass)
"""
function parse_norms(ast, package_name)
    norms = Norm[]
    current_annotations = String[]
    
    # Clear previous norm texts
    empty!(NORM_TEXTS)
    
    # First pass: collect all norm nodes and parse non-exceptions
    norm_nodes = []
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
                push!(norm_nodes, (node, title, copy(current_annotations)))
                current_annotations = String[]
            end
        end
    end
    
    # Parse all norms, handling exceptions in a second pass if needed
    exception_nodes = []
    for (node, title, annotations) in norm_nodes
        norm = parse_norm(ast, node, title, annotations, package_name, norms)
        if norm !== nothing
            # Check if this is an exception that couldn't be parsed yet
            if norm isa Tuple && norm[1] == :deferred_exception
                push!(exception_nodes, (node, title, annotations, norm[2]))
            else
                push!(norms, norm)
            end
        end
    end
    
    # Second pass: parse any deferred exceptions
    for (node, title, annotations, norm_text) in exception_nodes
        norm = parse_norm(ast, node, title, annotations, package_name, norms)
        if norm !== nothing && !(norm isa Tuple)
            push!(norms, norm)
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
    parse_norm(ast, header_node, title, annotations, package_name, norms)

Parse a single norm starting from its H3 header.
"""
function parse_norm(ast, header_node, title, annotations, package_name, norms)
    # Extract explicit ref_id if present in the title (format: {ref-id})
    # Otherwise generate ref_id from title
    ref_id_match = match(r"\{([\w-]+)\}", title)
    if ref_id_match !== nothing
        # Use explicit ref_id (without the { and } markers)
        ref_id = ref_id_match.captures[1]
        # Remove the {ref-id} part from the title for display
        title = replace(title, r"\s*\{[\w-]+\}\s*" => "")
    else
        # Generate ref_id from title (fallback for backward compatibility)
        ref_id = lowercase(replace(strip(title), r"\s+" => "-"))
    end
    
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
            
            # Check if this looks like a norm (contains * and ** or exception syntax)
            if occursin(r"\*[^*]+\*\s+\*\*[^*]+\*\*", norm_text) || occursin(r"exception\s+de\s+", norm_text)
                # Parse the norm body
                return parse_norm_body(ref_id, norm_text, skipped, overrules, package_name, norms)
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
    parse_norm_body(ref_id, norm_text, skipped, overrules, package_name, norms)

Parse the norm body text. Handles both regular norms and exceptions.
"""
function parse_norm_body(ref_id, norm_text, skipped, overrules, package_name, norms)
    # Store the norm text for error reporting
    NORM_TEXTS[ref_id] = norm_text
    
    # Normalize whitespace: replace newlines and multiple spaces with single space
    # This handles multi-line norms
    normalized_text = replace(norm_text, r"\s+" => " ")
    
    # Check if this is an exception norm
    # Pattern: exception de parent-ref-id [lorsque condition] [full norm syntax]
    exception_pattern = r"exception\s+de\s+([\w-]+)"
    exception_match = match(exception_pattern, normalized_text)
    
    if exception_match !== nothing
        # This is an exception norm
        parent_ref = String(strip(exception_match.captures[1]))
        
        # Find parent norm
        parent_norm = find_norm_by_ref(norms, parent_ref)
        if parent_norm === nothing
            @warn "Exception $(ref_id) references non-existent parent: $(parent_ref)"
            return nothing
        end
        
        # Check if full syntax is provided (contains Hohfeldian keyword)
        has_full_syntax = occursin(r"\*\*[^*]+\*\*", normalized_text)
        
        if has_full_syntax
            # Full syntax: parse and validate against parent
            return parse_full_exception(ref_id, normalized_text, parent_norm, skipped, overrules, package_name)
        else
            # Minimal syntax: use constructor
            return Norm(parent_norm, ref_id, text=norm_text)
        end
    end
    
    # Regular norm (not an exception)
    # First, check for malformed syntax with multiple prepositions
    preposition_pattern = r"(to|from|by|over|envers|à|au|aux|de|du|des|par|sur)\s+\*[^*]+\*"
    preposition_matches = collect(eachmatch(preposition_pattern, normalized_text))
    
    if length(preposition_matches) > 1
        # Multiple prepositions found - this is malformed syntax
        preps = [m.captures[1] for m in preposition_matches]
        error("Malformed norm syntax in '$(ref_id)':\n" *
              "Found multiple prepositions: $(join(["'$p'" for p in preps], ", "))\n" *
              "A norm must have exactly one counterparty.\n\n" *
              "Invalid syntax:\n$(norm_text)\n\n" *
              "This appears to be mixing a legal relationship with a calculation.\n" *
              "Consider splitting into:\n" *
              "1. A Norm (bilateral relationship between two Roles)\n" *
              "2. A Procedure (calculation in the Procedures section)")
    end
    
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
    norm = Norm(
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
    
    # Validate bilateral constraint
    validate_bilateral_norm(norm)
    
    return norm
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

"""
    find_norm_by_ref(norms, ref_id)

Find a norm by its ref_id in the norms vector.
Returns the norm if found, nothing otherwise.
"""
function find_norm_by_ref(norms::Vector{Norm}, ref_id::String)
    for norm in norms
        if norm.ref_id == ref_id
            return norm
        end
    end
    return nothing
end

"""
    parse_full_exception(ref_id, norm_text, parent_norm, skipped, overrules, package_name)

Parse an exception with full syntax (explicit actor/action/object/counterparty).
Validates that the explicit fields match the parent norm.
"""
function parse_full_exception(ref_id, norm_text, parent_norm, skipped, overrules, package_name)
    # Normalize whitespace
    normalized_text = replace(norm_text, r"\s+" => " ")
    
    # Extract the norm components (same pattern as regular norms)
    pattern = r"(?:.*?)\*([^*]+)\*(?:.*?)\*\*([^*]+)\*\*(?:.*?)((?:\*[^*]+\*(?:,\s*)?)+)(?:.*?)\*([^*]+)\*(?:.*?)(to|from|by|over|envers|à|au|aux|de|du|des|par|sur)(?:.*?)\*([^*]+)\*"
    m = match(pattern, normalized_text)
    
    if m === nothing
        @warn "Could not parse full exception syntax: $normalized_text"
        return nothing
    end
    
    actor_name = String(strip(m.captures[1]))
    h_keyword = String(strip(m.captures[2]))
    actions_text = String(strip(m.captures[3]))
    object_name = String(strip(m.captures[4]))
    preposition = String(strip(m.captures[5]))
    counterparty_name = String(strip(m.captures[6]))
    
    # Map H-keyword to Position
    position = get_position(h_keyword)
    if position === nothing
        @warn "Unknown Hohfeldian keyword in exception: $h_keyword"
        return nothing
    end
    
    # Validate position is opposite of parent
    expected_position = O(parent_norm.Hohfeld)
    if position != expected_position
        error("Full exception syntax error in $(ref_id): position must be opposite of parent. " *
              "Expected $(position_name(expected_position)), got $(position_name(position))")
    end
    
    # Validate actor/action/object/counterparty match parent
    if actor_name != parent_norm.actor.name
        error("Full exception syntax error in $(ref_id): actor must match parent. " *
              "Expected '$(parent_norm.actor.name)', got '$(actor_name)'")
    end
    
    if counterparty_name != parent_norm.counterparty.name
        error("Full exception syntax error in $(ref_id): counterparty must match parent. " *
              "Expected '$(parent_norm.counterparty.name)', got '$(counterparty_name)'")
    end
    
    if object_name != parent_norm.object.name
        error("Full exception syntax error in $(ref_id): object must match parent. " *
              "Expected '$(parent_norm.object.name)', got '$(object_name)'")
    end
    
    # Parse actions and validate
    actions = parse_actions(actions_text)
    if !isempty(actions) && actions[1] != parent_norm.action.name
        error("Full exception syntax error in $(ref_id): action must match parent. " *
              "Expected '$(parent_norm.action.name)', got '$(actions[1])'")
    end
    
    # Create taxons
    actor = Taxon(Role, actor_name)
    counterparty = Taxon(Role, counterparty_name)
    action = if !isempty(actions)
        Taxon(Action, actions[1])
    else
        Taxon(Action, "")
    end
    object = Taxon(Object, object_name)
    
    # Create the exception norm with explicit fields
    return Norm(
        ref_id=ref_id,
        package=package_name,
        Hohfeld=position,
        actor=actor,
        action=action,
        object=object,
        counterparty=counterparty,
        overrules=overrules,
        excepts=parent_norm.ref_id,  # Link to parent
        depth=parent_norm.depth + 1,  # Increment depth
        skipped=skipped,
        text=norm_text
    )
end
