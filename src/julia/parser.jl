import CommonMark
using CommonMark: Heading, Paragraph, BlockQuote, List, Parser, FootnoteRule, Strong, Text, enable!

# Helper function to extract plain text from a node
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

# Helper function to extract text WITH markdown syntax (for ruling parsing)
# Reconstructs *emphasis* and **strong** markers
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

# Helper function to extract list items with proper formatting for Case expressions
# Reconstructs list structure with "- " markers and newlines
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

# Helper to process list items with a callback
function process_list_items(list_node, callback)
    for (item, item_entering) in list_node
        if item_entering && item.t isa CommonMark.Item
            callback(item)
        end
    end
end

# Helper to convert SubString to String
to_string(s::Union{String, SubString{String}}) = String(s)

function parse_document(path, project_root=pwd(), import_chain=String[])
    parser = Parser()
    enable!(parser, FootnoteRule())

    ast = parser(read(path, String))
    m = parse_manifest(ast)

    entities = parse_taxonomy(ast, Entity, m.package)
    roles = parse_taxonomy(ast, Role, m.package)
    actions = parse_taxonomy(ast, Action, m.package)
    objects = parse_taxonomy(ast, Object, m.package)

    norms = parse_norms(ast, m.package)

    # Process imports if any
    imported_docs = DocumentIR[]
    if !isempty(m.imports)
        base_dir = dirname(path)
        for import_spec in m.imports
            imported_doc = load_imported_document(import_spec, base_dir, project_root, import_chain)
            push!(imported_docs, imported_doc)
        end
    end

    # Merge with imported documents if any
    if !isempty(imported_docs)
        imported_pkg_names = [d.manifest.package for d in imported_docs]
        entities = merge_all_taxonomies(Entity, entities, [d.entityTaxonomy for d in imported_docs], m.package, imported_pkg_names)
        roles = merge_all_taxonomies(Role, roles, [d.actorTaxonomy for d in imported_docs], m.package, imported_pkg_names)
        actions = merge_all_taxonomies(Action, actions, [d.actionTaxonomy for d in imported_docs], m.package, imported_pkg_names)
        objects = merge_all_taxonomies(Object, objects, [d.objectTaxonomy for d in imported_docs], m.package, imported_pkg_names)
        
        # Combine norms from all documents
        all_norms = copy(norms)
        for doc in imported_docs
            append!(all_norms, doc.norms)
        end
        norms = all_norms
    end

    # Resolve taxons in norms to point to actual taxons in taxonomy trees
    # This ensures parent/child relationships are intact for subsumption checking
    resolve_norm_taxons!(norms, roles, actions, objects)
    
    # Validate all terms in norms exist in taxonomies
    validation_errors = validate_norms_terms(norms, roles, actions, objects)
    
    # Print validation report if there are errors
    if !isempty(validation_errors)
        print_validation_report(validation_errors)
        println(stderr, "⚠️  Validation failed. Returning partial DocumentIR with validation errors.\n")
    end
    
    # NOTE: Dimensional analysis is now performed once after document merge
    # in opennorm.jl, just before satisfiability checking.
    # This avoids running it multiple times during recursive document parsing.

    return DocumentIR(
        manifest=m,
        entityTaxonomy=entities,
        actorTaxonomy=roles,
        actionTaxonomy=actions,
        objectTaxonomy=objects,
        norms=norms
    )
end

# Validation error collection
struct ValidationError
    term::String
    taxonomy_type::String
    norm_id::String
    position::String
    norm_text::String
end

# Validate that all terms used in norms exist in the appropriate taxonomies
# Returns a vector of validation errors instead of throwing
function validate_norms_terms(norms::Vector{Norm}, roles::Taxon{Role}, actions::Taxon{Action}, objects::Taxon{Object})
    errors = ValidationError[]
    
    for norm in norms
        # Get the norm text from the global dictionary
        norm_text = get(NORM_TEXTS, norm.ref_id, "")
        
        # Validate actor (Role taxonomy)
        if !isempty(norm.actor.name) && !term_exists_in_taxonomy(roles, norm.actor.name)
            push!(errors, ValidationError(norm.actor.name, "Role", norm.ref_id, "actor", norm_text))
        end
        
        # Validate action (Action taxonomy)
        if !isempty(norm.action.name) && !term_exists_in_taxonomy(actions, norm.action.name)
            push!(errors, ValidationError(norm.action.name, "Action", norm.ref_id, "action", norm_text))
        end
        
        # Validate object (Object taxonomy)
        if !isempty(norm.object.name) && !term_exists_in_taxonomy(objects, norm.object.name)
            push!(errors, ValidationError(norm.object.name, "Object", norm.ref_id, "object", norm_text))
        end
        
        # Validate counterparty (Role taxonomy)
        if !isempty(norm.counterparty.name) && !term_exists_in_taxonomy(roles, norm.counterparty.name)
            push!(errors, ValidationError(norm.counterparty.name, "Role", norm.ref_id, "counterparty", norm_text))
        end
    end
    
    return errors
end

# Print a comprehensive validation report
function print_validation_report(errors::Vector{ValidationError})
    if isempty(errors)
        return
    end
    
    println(stderr, "\n═══════════════════════════════════════════════════════════════")
    println(stderr, "❌ VALIDATION REPORT - Missing Taxonomy Terms")
    println(stderr, "═══════════════════════════════════════════════════════════════\n")
    
    # Group errors by taxonomy
    by_taxonomy = Dict{String, Vector{ValidationError}}()
    for err in errors
        if !haskey(by_taxonomy, err.taxonomy_type)
            by_taxonomy[err.taxonomy_type] = ValidationError[]
        end
        push!(by_taxonomy[err.taxonomy_type], err)
    end
    
    # Print summary
    println(stderr, "Summary:")
    println(stderr, "  Total missing terms: ", length(errors))
    for taxonomy in sort(collect(keys(by_taxonomy)))
        tax_errors = by_taxonomy[taxonomy]
        unique_terms = length(unique(e.term for e in tax_errors))
        println(stderr, "  - $taxonomy: $unique_terms unique term(s) missing")
    end
    println(stderr)
    
    # Print detailed breakdown by taxonomy
    for taxonomy in sort(collect(keys(by_taxonomy)))
        tax_errors = by_taxonomy[taxonomy]
        println(stderr, "─────────────────────────────────────────────────────────────────")
        println(stderr, "Missing terms in $taxonomy taxonomy:")
        println(stderr, "─────────────────────────────────────────────────────────────────")
        
        # Group by term to show all norms using each term
        by_term = Dict{String, Vector{ValidationError}}()
        for err in tax_errors
            if !haskey(by_term, err.term)
                by_term[err.term] = ValidationError[]
            end
            push!(by_term[err.term], err)
        end
        
        for term in sort(collect(keys(by_term)))
            term_errors = by_term[term]
            println(stderr, "\n  Term: \"$term\"")
            println(stderr, "  Used in $(length(term_errors)) norm(s):")
            for err in term_errors
                println(stderr, "    - $(err.norm_id) ($(err.position))")
            end
        end
        println(stderr)
    end
    
    println(stderr, "═══════════════════════════════════════════════════════════════")
    println(stderr, "Suggested actions:")
    println(stderr, "  1. Add missing terms to the appropriate taxonomies")
    println(stderr, "  2. Check for typos in the norm definitions")
    println(stderr, "  3. Verify terms are in the correct taxonomy")
    println(stderr, "═══════════════════════════════════════════════════════════════\n")
end

# Parse version from import specification
function parse_import_spec(import_spec::String)
    # Format: "path/to/doc@version" or "path/to/doc"
    parts = split(import_spec, "@")
    if length(parts) == 2
        return (parts[1], parts[2])
    elseif length(parts) == 1
        return (parts[1], nothing)
    else
        throw(ImportPathError(import_spec, "Invalid import specification format"))
    end
end

# Check if version is compatible (for now, exact match or no version specified)
function is_version_compatible(required::Union{String, SubString{String}, Nothing}, actual::Union{String, SubString{String}})
    required === nothing && return true  # No version requirement
    # For now, require exact match
    # TODO: Implement semantic versioning compatibility
    return to_string(required) == to_string(actual)
end

# Resolve import path to absolute file path
function resolve_import_path(import_spec::String, base_dir::String, project_root::String)
    path, version = parse_import_spec(import_spec)
    
    # Check if it's a stdlib path
    if startswith(path, "stdlib/")
        # Stdlib paths are relative to project root
        full_path = joinpath(project_root, path * ".md")
    else
        # Regular paths are relative to the importing document
        full_path = joinpath(base_dir, path * ".md")
    end
    
    # Check if file exists
    if !isfile(full_path)
        throw(ImportPathError(import_spec, "File not found: $full_path"))
    end
    
    return (full_path, version)
end

# Load and parse an imported document with circular dependency detection
function load_imported_document(import_spec::String, base_dir::String, project_root::String, 
                                import_chain::Vector{String}=String[])
    full_path, required_version = resolve_import_path(import_spec, base_dir, project_root)
    
    # Check for circular dependencies
    if full_path in import_chain
        throw(CircularDependencyError(full_path, vcat(import_chain, [full_path])))
    end
    
    # Parse the document
    try
        doc = parse_document(full_path, project_root, vcat(import_chain, [full_path]))
        
        # Check version compatibility
        if required_version !== nothing && !is_version_compatible(required_version, doc.manifest.version)
            throw(ImportPathError(import_spec, 
                "Version mismatch: required $(required_version), found $(doc.manifest.version)"))
        end
        
        return doc
    catch e
        if e isa ImportPathError || e isa CircularDependencyError || e isa TaxonomyMergeConflict
            rethrow(e)
        else
            throw(DocumentParseError(full_path, string(e)))
        end
    end
end



# Walk the AST with multiple dispatch
function parse_manifest(ast)
    # Collect all paragraphs first
    all_kvs = Dict{String, String}()
    title = ""
    description_lines = String[]
    imports = String[]
    in_imports = false
    in_manifest = true  # Track if we're still in manifest section
    
    for (node, entering) in ast
        if !entering
            continue
        end
        
        t = node.t

        # Title (H1)
        if t isa Heading && t.level == 1
            title = node.first_child.literal
        # Stop collecting manifest data when we hit H2 or H3 (start of content)
        # But don't stop at "Manifest" header
        elseif t isa Heading && (t.level == 2 || t.level == 3)
            heading_text = plain(node)
            if !occursin("Manifest", heading_text)
                break
            end
        # Description (blockquote)
        elseif t isa BlockQuote
            push!(description_lines, node.first_child.literal)
        # Paragraphs (metadata)
        elseif t isa Paragraph
            txt = plain(node)
            # Check if this paragraph contains "Imports:" - if so, set flag for next list
            if occursin("Imports:", txt)
                in_imports = true
            end
            # Merge all key-value pairs (this will extract all metadata including the one with Imports:)
            kvs_from_para = extract_all_kvs(node)
            merge!(all_kvs, kvs_from_para)
        # Imports list
        elseif t isa List && in_imports
            process_list_items(node, item -> push!(imports, strip(plain(item))))
            in_imports = false
        end
    end
    
    # Extract values from collected kvs
    package = get(all_kvs, "package", "")
    package_type = get(all_kvs, "package-type", "")
    version = get(all_kvs, "version", "")
    strict = lowercase(get(all_kvs, "strict", "true")) == "true"
    
    normLevel = get_norm_level("Contract")
    if haskey(all_kvs, "opennorm") && haskey(NORMMAP, all_kvs["opennorm"])
        normLevel = get_norm_level(all_kvs["opennorm"])
    end

    status = get_status("review")
    if haskey(all_kvs, "status")
        status = get_status(all_kvs["status"])
    end

    language = get_lang("EN")
    if haskey(all_kvs, "language")
        language = get_lang(all_kvs["language"])
    end

    return Manifest(
        title, 
        join(description_lines, "\n"), 
        package, 
        package_type,
        version, 
        strict, 
        normLevel, 
        status, 
        imports, 
        language
    )
end


# Get taxonomy name string for a given type
get_taxonomy(::Type{Entity}) = "Entity"
get_taxonomy(::Type{Role}) = "Role"
get_taxonomy(::Type{Action}) = "Action"
get_taxonomy(::Type{Object}) = "Object"

# Get default taxonomy for a given type
get_default_taxonomy(::Type{Entity}) = Taxon(Entity, "")
get_default_taxonomy(::Type{Role}) = Taxon(Role, "")
get_default_taxonomy(::Type{Action}) = Taxon(Action, "")
get_default_taxonomy(::Type{Object}) = Taxon(Object, "")

# Parse a taxonomy section from the AST
function parse_taxonomy(ast, ::Type{T}, package_name::String="") where {T<:TaxonomyEnum}
    taxonomy_name = get_taxonomy(T)
    
    in_taxonomy = false
    root = nothing
    stack = Vector{Taxon{T}}()
    
    for (node, entering) in ast
        if !entering
            continue
        end
        
        t = node.t
        
        # Check for taxonomy header: ### <Type> Taxonomy
        if t isa Heading && t.level == 3
            title = plain(node)
            if occursin("$taxonomy_name Taxonomy", title)
                in_taxonomy = true
                continue
            elseif in_taxonomy && !occursin("Taxonomy", title)
                # Hit a new section, stop parsing this taxonomy
                break
            end
        end
        
        # Parse list items within the taxonomy section
        if in_taxonomy && t isa List
            root = parse_taxonomy_list(node, T, package_name)
            break
        end
    end
    
    # Return root or default
    if root === nothing
        return get_default_taxonomy(T)
    end
    
    return root
end

# Resolve a taxon name to the actual taxon in the taxonomy tree
# Returns the taxon with full parent/child relationships intact
function resolve_taxon_in_tree(taxonomy_root::Taxon{T}, name::String) where {T<:TaxonomyEnum}
    # Handle empty name (default taxon)
    if isempty(name)
        return Taxon(T, "")
    end
    
    # Search the taxonomy tree for this name
    function search_tree(node::Taxon{T})
        if node.name == name
            return node
        end
        for child in node.children
            result = search_tree(child)
            if result !== nothing
                return result
            end
        end
        return nothing
    end
    
    result = search_tree(taxonomy_root)
    
    # If not found, return a new isolated taxon (for error reporting)
    if result === nothing
        return Taxon(T, name)
    end
    
    return result
end

# Resolve all taxons in norms to point to actual taxons in taxonomy trees
function resolve_norm_taxons!(norms::Vector{Norm}, actor_taxonomy::Taxon{Role}, 
                              action_taxonomy::Taxon{Action}, object_taxonomy::Taxon{Object})
    for (i, norm) in enumerate(norms)
        # Resolve each taxon to the actual one in the taxonomy tree
        resolved_actor = resolve_taxon_in_tree(actor_taxonomy, norm.actor.name)
        resolved_action = resolve_taxon_in_tree(action_taxonomy, norm.action.name)
        resolved_object = resolve_taxon_in_tree(object_taxonomy, norm.object.name)
        resolved_counterparty = resolve_taxon_in_tree(actor_taxonomy, norm.counterparty.name)
        
        # Create a new norm with resolved taxons (preserve the text field)
        norms[i] = Norm(
            ref_id=norm.ref_id,
            package=norm.package,
            Hohfeld=norm.Hohfeld,
            actor=resolved_actor,
            action=resolved_action,
            object=resolved_object,
            counterparty=resolved_counterparty,
            overrules=norm.overrules,
            skipped=norm.skipped,
            text=norm.text
        )
    end
end

# Safe accessors for CommonMark.Node fields that may be uninitialized
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

# Parse a nested list into a taxonomy tree
function parse_taxonomy_list(list_node, ::Type{T}, package_name::String="") where {T<:TaxonomyEnum}
    root = nothing
    stack = Vector{Union{Nothing, Taxon{T}}}()
    
    function process_item(item, depth)
        # Get the text content of this item (only direct text, not nested lists)
        text = ""
        for (node, entering) in item
            if entering && node.t isa Text
                text *= node.literal
            elseif entering && node.t isa List
                # Stop before processing nested lists
                break
            end
        end
        text = String(strip(text))
        isempty(text) && return
        
        # Create the taxon
        if depth == 0
            # Root level
            taxon = Taxon(T, text, package_name)
            if root === nothing
                root = taxon
            end
        else
            # Child level - attach to parent
            parent = stack[depth]
            if parent !== nothing
                taxon = Taxon(parent, text, package_name)
            else
                # No parent found, create as root
                taxon = Taxon(T, text, package_name)
            end
        end
        
        # Update stack
        if length(stack) <= depth
            push!(stack, taxon)
        else
            stack[depth + 1] = taxon
        end
        
        # Find the direct child List node and process only its direct Item children
        for (child, child_entering) in item
            if child_entering && child.t isa List && cm_parent(child) === item
                for (nested_item, nested_entering) in child
                    if nested_entering && nested_item.t isa CommonMark.Item &&
                       cm_parent(nested_item) === child
                        process_item(nested_item, depth + 1)
                    end
                end
                break
            end
        end
    end
    
    # Process only direct top-level items (not nested descendants)
    for (item, item_entering) in list_node
        if item_entering && item.t isa CommonMark.Item &&
           cm_parent(item) === list_node
            process_item(item, 0)
        end
    end
    
    return root
end

# Global dictionary to store norm texts for error reporting
const NORM_TEXTS = Dict{String, String}()

# Parse all norms from the AST
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

# Extract annotations from blockquote (skip, overrules)
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

# Parse a single norm starting from its H3 header
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

# Parse the norm body text
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


# Parse comma-separated actions
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

# Parse condition clause (when ...)
function parse_condition(condition_text)
    # Pattern: when *X* has *V* *O*
    # For now, return nothing (to be implemented)
    return nothing
end

# Extract all key-value pairs from a paragraph containing multiple **Key:** value pairs
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


# Get the parent chain for a taxon (path from root to this taxon)
function get_parent_chain(taxon::Taxon{T}) where {T<:TaxonomyEnum}
    chain = String[]
    current = taxon
    while current !== nothing
        if !isempty(current.name)
            pushfirst!(chain, current.name)
        end
        current = current.parent
    end
    return join(chain, " -> ")
end

# Find all occurrences of a term in a taxonomy tree
function find_taxon(root::Taxon{T}, term::String) where {T<:TaxonomyEnum}
    results = Tuple{Taxon{T}, String}[]  # (taxon, parent_chain)
    
    function search(node::Taxon{T})
        if node.name == term
            push!(results, (node, get_parent_chain(node)))
        end
        for child in node.children
            search(child)
        end
    end
    
    search(root)
    return results
end

# Check if a term exists in a taxonomy
function term_exists_in_taxonomy(root::Taxon{T}, term::String) where {T<:TaxonomyEnum}
    function search(node::Taxon{T})
        if node.name == term
            return true
        end
        for child in node.children
            if search(child)
                return true
            end
        end
        return false
    end
    
    return search(root)
end

# Validate that a term exists in the appropriate taxonomy
function validate_term(term::String, taxonomy::Taxon{T}, taxonomy_name::String, norm_id::String, position::String, norm_text::String="") where {T<:TaxonomyEnum}
    if !term_exists_in_taxonomy(taxonomy, term)
        throw(UndefinedTermError(term, taxonomy_name, norm_id, position, norm_text))
    end
end


# Merge two taxonomy trees, detecting conflicts
function merge_taxonomies(base::Taxon{T}, imported::Taxon{T}, taxonomy_name::String, base_doc::String="current", imported_doc::String="imported") where {T<:TaxonomyEnum}
    # If base is empty (default taxonomy), just return the imported one
    if isempty(base.name) && isempty(base.children)
        return imported
    end
    
    # If imported is empty, return base
    if isempty(imported.name) && isempty(imported.children)
        return base
    end
    
    # Collect all terms from imported taxonomy
    imported_terms = Dict{String, String}()  # term -> parent_chain
    
    function collect_terms(node::Taxon{T})
        if !isempty(node.name)
            imported_terms[node.name] = get_parent_chain(node)
        end
        for child in node.children
            collect_terms(child)
        end
    end
    
    collect_terms(imported)
    
    # Check each imported term against base taxonomy
    for (term, imported_chain) in imported_terms
        base_occurrences = find_taxon(base, term)
        
        if !isempty(base_occurrences)
            # Term exists in base - check if locations match
            for (_, base_chain) in base_occurrences
                if base_chain != imported_chain
                    # Conflict: same term at different locations
                    throw(TaxonomyMergeConflict(
                        term,
                        taxonomy_name,
                        [base_chain, imported_chain],
                        [base_doc, imported_doc]
                    ))
                end
            end
            # If we get here, term exists at same location - no conflict
        else
            # Term doesn't exist in base - need to add it
            # For now, we'll just verify no conflicts exist
            # Actual merging would require reconstructing the tree
        end
    end
    
    # If no conflicts, merge the trees
    # We need to recursively merge imported children into base
    return merge_taxonomy_trees(base, imported)
end

# Recursively merge two taxonomy trees
function merge_taxonomy_trees(base::Taxon{T}, imported::Taxon{T}) where {T<:TaxonomyEnum}
    # If base is empty, return imported
    if isempty(base.name) && isempty(base.children)
        return imported
    end
    
    # If imported is empty, return base
    if isempty(imported.name) && isempty(imported.children)
        return base
    end
    
    # Create a new merged taxon with base's name and source (local wins)
    merged = Taxon(T, base.name, base.source)
    
    # First, add all children from base
    for base_child in base.children
        push!(merged.children, base_child)
        base_child.parent = merged
    end
    
    # Then, merge in children from imported
    for imported_child in imported.children
        # Check if this child already exists in base
        existing_idx = findfirst(c -> c.name == imported_child.name, merged.children)
        
        if existing_idx !== nothing
            # Child exists - recursively merge (local wins, keeps base's source)
            existing_child = merged.children[existing_idx]
            merged_child = merge_taxonomy_trees(existing_child, imported_child)
            merged.children[existing_idx] = merged_child
            merged_child.parent = merged
        else
            # Child doesn't exist - add it with its import source preserved
            new_child = deep_copy_taxon(imported_child)
            push!(merged.children, new_child)
            new_child.parent = merged
        end
    end
    
    return merged
end

# Deep copy a taxon and all its children
function deep_copy_taxon(taxon::Taxon{T}) where {T<:TaxonomyEnum}
    copy = Taxon(T, taxon.name, taxon.source)
    for child in taxon.children
        child_copy = deep_copy_taxon(child)
        push!(copy.children, child_copy)
        child_copy.parent = copy
    end
    return copy
end

# Merge multiple taxonomies
function merge_all_taxonomies(::Type{T}, base::Taxon{T}, imported_list::Vector{Taxon{T}}, base_doc::String="current", imported_docs::Vector{String}=String[]) where {T<:TaxonomyEnum}
    taxonomy_name = get_taxonomy(T)
    result = base
    
    for (i, imported) in enumerate(imported_list)
        imported_doc = i <= length(imported_docs) ? imported_docs[i] : "imported[$i]"
        result = merge_taxonomies(result, imported, taxonomy_name, base_doc, imported_doc)
    end
    
    return result
end

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
                
                # Create procedure with raw expression text
                # Type resolution will happen in a separate phase
                proc = Procedure(
                    current_procedure_name,
                    current_description,
                    expression_text,  # Store raw text, not parsed AST
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

