# ============================================================================
# Core Parsing Infrastructure
# ============================================================================

"""
    ManifestContext

Context for parsing manifest metadata using multiple dispatch.
"""
mutable struct ManifestContext
    kvs::Dict{String, String}
    title::String
    description_lines::Vector{String}
    imports::Vector{String}
    in_imports::Bool
    in_manifest::Bool
end

ManifestContext() = ManifestContext(Dict{String, String}(), "", String[], String[], false, true)

# ============================================================================
# Multiple Dispatch Node Processing
# ============================================================================

"""
    process_node(ctx, node::CommonMark.Node, entering::Bool)

Base fallback - do nothing for unhandled node types.
"""
process_node(ctx, node::CommonMark.Node, entering::Bool) = ctx

"""
    process_node(ctx::ManifestContext, node::CommonMark.Node, entering::Bool, ::Type{Heading})

Process Heading nodes in manifest context.
"""
function process_node(ctx::ManifestContext, node::CommonMark.Node, entering::Bool, ::Type{Heading})
    if !entering || !ctx.in_manifest
        return ctx
    end
    
    heading = node.t
    if heading.level == 1
        ctx.title = node.first_child.literal
    elseif heading.level == 2 || heading.level == 3
        heading_text = plain(node)
        if !occursin("Manifest", heading_text)
            ctx.in_manifest = false
        end
    end
    
    return ctx
end

"""
    process_node(ctx::ManifestContext, node::CommonMark.Node, entering::Bool, ::Type{BlockQuote})

Process BlockQuote nodes in manifest context.
"""
function process_node(ctx::ManifestContext, node::CommonMark.Node, entering::Bool, ::Type{BlockQuote})
    if !entering || !ctx.in_manifest
        return ctx
    end
    
    push!(ctx.description_lines, node.first_child.literal)
    return ctx
end

"""
    process_node(ctx::ManifestContext, node::CommonMark.Node, entering::Bool, ::Type{Paragraph})

Process Paragraph nodes in manifest context.
"""
function process_node(ctx::ManifestContext, node::CommonMark.Node, entering::Bool, ::Type{Paragraph})
    if !entering || !ctx.in_manifest
        return ctx
    end
    
    txt = plain(node)
    if occursin("Imports:", txt)
        ctx.in_imports = true
    end
    kvs_from_para = extract_all_kvs(node)
    merge!(ctx.kvs, kvs_from_para)
    
    return ctx
end

"""
    process_node(ctx::ManifestContext, node::CommonMark.Node, entering::Bool, ::Type{List})

Process List nodes in manifest context.
"""
function process_node(ctx::ManifestContext, node::CommonMark.Node, entering::Bool, ::Type{List})
    if !entering || !ctx.in_manifest
        return ctx
    end
    
    if ctx.in_imports
        process_list_items(node, item -> push!(ctx.imports, strip(plain(item))))
        ctx.in_imports = false
    end
    
    return ctx
end

"""
    process_node(ctx::ManifestContext, node::CommonMark.Node, entering::Bool)

Dispatcher that extracts node type and calls appropriate method.
"""
function process_node(ctx::ManifestContext, node::CommonMark.Node, entering::Bool)
    t = node.t
    if t isa Heading
        return process_node(ctx, node, entering, Heading)
    elseif t isa BlockQuote
        return process_node(ctx, node, entering, BlockQuote)
    elseif t isa Paragraph
        return process_node(ctx, node, entering, Paragraph)
    elseif t isa List
        return process_node(ctx, node, entering, List)
    end
    return ctx
end

"""
    traverse_ast(ast, ctx)

Generic AST traversal with multiple dispatch.
"""
function traverse_ast(ast, ctx)
    for (node, entering) in ast
        ctx = process_node(ctx, node, entering)
        # Stop early if context signals completion
        if ctx isa ManifestContext && !ctx.in_manifest
            break
        end
    end
    return ctx
end

"""
    parse_document(path, project_root=pwd(), import_chain=String[])

Parse a complete OpenNorm document from a markdown file.
Returns a DocumentIR struct containing all parsed components.
"""
function parse_document(path, project_root=pwd(), import_chain=String[])
    parser = CommonMark.Parser()
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

    # Parse procedures from the document
    procedures = parse_procedures(ast, path)
    
    # TODO: Parse parameters from the "Paramètres" section
    # TODO: Extract input variables by analyzing procedure dependencies
    parameters = Parameter[]
    input_variables = InputVariable[]
    
    return DocumentIR(
        manifest=m,
        entityTaxonomy=entities,
        actorTaxonomy=roles,
        actionTaxonomy=actions,
        objectTaxonomy=objects,
        norms=norms,
        procedures=procedures,
        parameters=parameters,
        input_variables=input_variables
    )
end
