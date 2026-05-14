# ============================================================================
# Taxonomy Parsing and Merging
# ============================================================================

"""
    get_taxonomy(::Type{T}) where {T<:TaxonomyEnum}

Get taxonomy name string for a given type.
"""
get_taxonomy(::Type{Entity}) = "Entity"
get_taxonomy(::Type{Role}) = "Role"
get_taxonomy(::Type{Action}) = "Action"
get_taxonomy(::Type{Object}) = "Object"

"""
    get_default_taxonomy(::Type{T}) where {T<:TaxonomyEnum}

Get default taxonomy for a given type.
"""
get_default_taxonomy(::Type{Entity}) = Taxon(Entity, "")
get_default_taxonomy(::Type{Role}) = Taxon(Role, "")
get_default_taxonomy(::Type{Action}) = Taxon(Action, "")
get_default_taxonomy(::Type{Object}) = Taxon(Object, "")

"""
    parse_taxonomy(ast, ::Type{T}, package_name::String="") where {T<:TaxonomyEnum}

Parse a taxonomy section from the AST.
"""
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

"""
    parse_taxonomy_list(list_node, ::Type{T}, package_name::String="") where {T<:TaxonomyEnum}

Parse a nested list into a taxonomy tree.
"""
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

"""
    resolve_taxon_in_tree(taxonomy_root::Taxon{T}, name::String) where {T<:TaxonomyEnum}

Resolve a taxon name to the actual taxon in the taxonomy tree.
Returns the taxon with full parent/child relationships intact.
"""
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

"""
    resolve_norm_taxons!(norms, actor_taxonomy, action_taxonomy, object_taxonomy)

Resolve all taxons in norms to point to actual taxons in taxonomy trees.
"""
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

"""
    get_parent_chain(taxon::Taxon{T}) where {T<:TaxonomyEnum}

Get the parent chain for a taxon (path from root to this taxon).
"""
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

"""
    find_taxon(root::Taxon{T}, term::String) where {T<:TaxonomyEnum}

Find all occurrences of a term in a taxonomy tree.
"""
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

"""
    term_exists_in_taxonomy(root::Taxon{T}, term::String) where {T<:TaxonomyEnum}

Check if a term exists in a taxonomy.
"""
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

"""
    validate_term(term, taxonomy, taxonomy_name, norm_id, position, norm_text)

Validate that a term exists in the appropriate taxonomy.
"""
function validate_term(term::String, taxonomy::Taxon{T}, taxonomy_name::String, norm_id::String, position::String, norm_text::String="") where {T<:TaxonomyEnum}
    if !term_exists_in_taxonomy(taxonomy, term)
        throw(UndefinedTermError(term, taxonomy_name, norm_id, position, norm_text))
    end
end

"""
    deep_copy_taxon(taxon::Taxon{T}) where {T<:TaxonomyEnum}

Deep copy a taxon and all its children.
"""
function deep_copy_taxon(taxon::Taxon{T}) where {T<:TaxonomyEnum}
    copy = Taxon(T, taxon.name, taxon.source)
    for child in taxon.children
        child_copy = deep_copy_taxon(child)
        push!(copy.children, child_copy)
        child_copy.parent = copy
    end
    return copy
end

"""
    merge_taxonomy_trees(base::Taxon{T}, imported::Taxon{T}) where {T<:TaxonomyEnum}

Recursively merge two taxonomy trees.
"""
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

"""
    merge_taxonomies(base, imported, taxonomy_name, base_doc, imported_doc)

Merge two taxonomy trees, detecting conflicts.
"""
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

"""
    merge_all_taxonomies(::Type{T}, base, imported_list, base_doc, imported_docs) where {T<:TaxonomyEnum}

Merge multiple taxonomies.
"""
function merge_all_taxonomies(::Type{T}, base::Taxon{T}, imported_list::Vector{Taxon{T}}, base_doc::String="current", imported_docs::Vector{String}=String[]) where {T<:TaxonomyEnum}
    taxonomy_name = get_taxonomy(T)
    result = base
    
    for (i, imported) in enumerate(imported_list)
        imported_doc = i <= length(imported_docs) ? imported_docs[i] : "imported[$i]"
        result = merge_taxonomies(result, imported, taxonomy_name, base_doc, imported_doc)
    end
    
    return result
end