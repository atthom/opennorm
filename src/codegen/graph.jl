# Graph Generation Module
# Generates Mermaid flowcharts visualizing norm hierarchies and exception relationships

"""
    generate_mermaid_graph(doc::DocumentIR)::String

Generate a Mermaid flowchart from a DocumentIR structure.
Creates a top-down graph showing:
- All norms as nodes (labeled with their #ref_id)
- Exception relationships as directed edges
- Different colors for different jurisdictions/packages

Returns the complete Markdown document with embedded Mermaid diagram.
"""
function generate_mermaid_graph(doc::DocumentIR)::String
    # Collect all norms
    norms = doc.norms
    
    if isempty(norms)
        return "# Norm Dependency Graph\n\nNo norms found in document.\n"
    end
    
    # Group norms by package for jurisdiction-based coloring
    packages = unique([norm.package for norm in norms])
    
    # Build the Mermaid graph
    mermaid_lines = String["```mermaid", "graph TD"]
    
    # Add node definitions (deduplicated by ref_id)
    seen_nodes = Set{String}()
    for norm in norms
        # Use ref_id as-is for node ID (should not have # prefix in source)
        node_id = norm.ref_id
        # Only add each unique node once
        if !(node_id in seen_nodes)
            push!(seen_nodes, node_id)
            # Create node with label showing the ref_id with # prefix for display
            push!(mermaid_lines, "    $(node_id)[#$(node_id)]")
        end
    end
    
    push!(mermaid_lines, "")  # Empty line for readability
    
    # Add edges for exception relationships
    # Reverse arrow direction so parent points to child (for top-down visualization)
    for norm in norms
        if norm.excepts !== nothing
            child_id = norm.ref_id
            # Remove # prefix from parent reference if present
            parent_id = replace(norm.excepts, r"^#" => "")
            # Reversed: parent --> child (so grundnorm appears at top)
            push!(mermaid_lines, "    $(parent_id) -->|exception of| $(child_id)")
        end
    end
    
    push!(mermaid_lines, "")  # Empty line for readability
    
    # Define color schemes for different jurisdictions
    # Detect jurisdiction type from package name
    color_map = Dict{String, String}()
    
    for pkg in packages
        if contains(lowercase(pkg), "universal") || contains(lowercase(pkg), "framework")
            color_map[pkg] = "universal"
        elseif contains(lowercase(pkg), "cgi") || contains(lowercase(pkg), "fr")
            color_map[pkg] = "french"
        else
            color_map[pkg] = "other"
        end
    end
    
    # Define CSS classes for jurisdictions
    push!(mermaid_lines, "    classDef universal fill:#4A90E2,stroke:#2E5C8A,color:#fff,stroke-width:2px")
    push!(mermaid_lines, "    classDef french fill:#E24A4A,stroke:#8A2E2E,color:#fff,stroke-width:2px")
    push!(mermaid_lines, "    classDef other fill:#9E9E9E,stroke:#616161,color:#fff,stroke-width:2px")
    
    push!(mermaid_lines, "")  # Empty line for readability
    
    # Apply classes to nodes based on their package
    for (pkg, color_class) in color_map
        pkg_norms = filter(n -> n.package == pkg, norms)
        if !isempty(pkg_norms)
            # Deduplicate node IDs to prevent the same node from appearing multiple times
            node_ids = unique([n.ref_id for n in pkg_norms])
            push!(mermaid_lines, "    class $(join(node_ids, ",")) $(color_class)")
        end
    end
    
    push!(mermaid_lines, "```")
    
    # Build the complete Markdown document
    markdown_doc = String[]
    push!(markdown_doc, "# Norm Dependency Graph")
    push!(markdown_doc, "")
    push!(markdown_doc, "This graph visualizes the hierarchy of norms and their exception relationships.")
    push!(markdown_doc, "")
    push!(markdown_doc, "## Legend")
    push!(markdown_doc, "")
    push!(markdown_doc, "- **Blue nodes**: Universal framework norms")
    push!(markdown_doc, "- **Red nodes**: French jurisdiction norms (CGI)")
    push!(markdown_doc, "- **Gray nodes**: Other jurisdiction norms")
    push!(markdown_doc, "- **Arrows**: Exception hierarchy (parent → child, where child excepts parent)")
    push!(markdown_doc, "")
    push!(markdown_doc, "## Statistics")
    push!(markdown_doc, "")
    push!(markdown_doc, "- Total norms: $(length(norms))")
    push!(markdown_doc, "- Jurisdictions: $(length(packages))")
    
    # Count norms by jurisdiction
    for pkg in sort(collect(packages))
        pkg_norms = filter(n -> n.package == pkg, norms)
        push!(markdown_doc, "  - $(pkg): $(length(pkg_norms)) norms")
    end
    
    # Count exception relationships
    exception_count = count(n -> n.excepts !== nothing, norms)
    push!(markdown_doc, "- Exception relationships: $(exception_count)")
    
    push!(markdown_doc, "")
    push!(markdown_doc, "## Graph")
    push!(markdown_doc, "")
    append!(markdown_doc, mermaid_lines)
    
    return join(markdown_doc, "\n") * "\n"
end

"""
    write_graph_file(doc::DocumentIR, output_path::String)

Generate and write a Mermaid flowchart to a file.
The output file will have the same base name as output_path but with .graph.md extension.

# Arguments
- `doc::DocumentIR`: The document to generate the graph from
- `output_path::String`: Base output path (e.g., "output.py" -> "output.graph.md")
"""
function write_graph_file(doc::DocumentIR, output_path::String)
    # Generate the graph
    graph_content = generate_mermaid_graph(doc)
    
    # Determine output filename
    base_name = splitext(output_path)[1]
    graph_path = "$(base_name).graph.md"
    
    # Write to file
    open(graph_path, "w") do f
        write(f, graph_content)
    end
    
    return graph_path
end