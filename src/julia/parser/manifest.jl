# ============================================================================
# Manifest Parsing and Import Resolution
# ============================================================================

"""
    parse_manifest(ast)

Parse the manifest section from the AST using multiple dispatch.
Returns a Manifest struct with document metadata.
"""
function parse_manifest(ast)
    # Create initial context
    ctx = ManifestContext()
    
    # Traverse AST with multiple dispatch
    ctx = traverse_ast(ast, ctx)
    
    # Extract values from collected kvs
    package = get(ctx.kvs, "package", "")
    package_type = get(ctx.kvs, "package-type", "")
    version = get(ctx.kvs, "version", "")
    strict = lowercase(get(ctx.kvs, "strict", "true")) == "true"
    
    normLevel = get_norm_level("Contract")
    if haskey(ctx.kvs, "opennorm") && haskey(NORMMAP, ctx.kvs["opennorm"])
        normLevel = get_norm_level(ctx.kvs["opennorm"])
    end

    status = get_status("review")
    if haskey(ctx.kvs, "status")
        status = get_status(ctx.kvs["status"])
    end

    language = get_lang("EN")
    if haskey(ctx.kvs, "language")
        language = get_lang(ctx.kvs["language"])
    end

    return Manifest(
        ctx.title, 
        join(ctx.description_lines, "\n"), 
        package, 
        package_type,
        version, 
        strict, 
        normLevel, 
        status, 
        ctx.imports, 
        language
    )
end

"""
    parse_import_spec(import_spec::String)

Parse version from import specification.
Format: "path/to/doc@version" or "path/to/doc"
"""
function parse_import_spec(import_spec::String)
    parts = split(import_spec, "@")
    if length(parts) == 2
        return (parts[1], parts[2])
    elseif length(parts) == 1
        return (parts[1], nothing)
    else
        throw(ImportPathError(import_spec, "Invalid import specification format"))
    end
end

"""
    is_version_compatible(required, actual)

Check if version is compatible (for now, exact match or no version specified).
"""
function is_version_compatible(required::Union{String, SubString{String}, Nothing}, actual::Union{String, SubString{String}})
    required === nothing && return true  # No version requirement
    # For now, require exact match
    # TODO: Implement semantic versioning compatibility
    return to_string(required) == to_string(actual)
end

"""
    resolve_import_path(import_spec::String, base_dir::String, project_root::String)

Resolve import path to absolute file path.
"""
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

"""
    load_imported_document(import_spec, base_dir, project_root, import_chain)

Load and parse an imported document with circular dependency detection.
"""
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