# ============================================================================
# Jurisdiction Parsing and Hierarchy Management
# ============================================================================

"""
    parse_lex_superior(lines::Vector{String})

Parse the Lex Superior section from document lines.
Returns a vector of LexSuperior relationships.

# Format
- `A > B`: A has superior jurisdiction over B
- `A ~ B`: A and B have ambiguous/contested relationship

# Example
```
FR.Constitution > FR.Loi > FR.Décret > FR.Arrêté
EU.Regulation > FR.Loi
EU.Regulation ~ FR.Constitution
```
"""
function parse_lex_superior(lines::Vector{String})
    relations = LexSuperior[]
    
    for line in lines
        line = strip(line)
        if isempty(line) || startswith(line, "#")
            continue
        end
        
        # Handle chained relationships: A > B > C
        if contains(line, ">")
            parts = split(line, ">")
            for i in 1:(length(parts)-1)
                superior = Jurisdiction(String(strip(parts[i])))
                inferior = Jurisdiction(String(strip(parts[i+1])))
                push!(relations, LexSuperior(superior, inferior, false))
            end
        elseif contains(line, "~")
            # Handle ambiguous relationship: A ~ B
            parts = split(line, "~")
            if length(parts) == 2
                j1 = Jurisdiction(String(strip(parts[1])))
                j2 = Jurisdiction(String(strip(parts[2])))
                # Ambiguous is bidirectional
                push!(relations, LexSuperior(j1, j2, true))
                push!(relations, LexSuperior(j2, j1, true))
            end
        end
    end
    
    return relations
end

"""
    build_jurisdiction_hierarchy(direct_relations::Vector{LexSuperior})

Build a JurisdictionHierarchy from direct relations, computing transitive closure.
Uses SMT-based approach where transitivity is handled by Z3, so we only store
direct relations here. Transitive inference happens in the SMT solver.

# Arguments
- `direct_relations`: Vector of directly declared LexSuperior relationships

# Returns
- `JurisdictionHierarchy`: Container with all relations and known jurisdictions
"""
function build_jurisdiction_hierarchy(direct_relations::Vector{LexSuperior})
    # Collect all jurisdictions
    jurisdictions = Set{Jurisdiction}()
    for rel in direct_relations
        push!(jurisdictions, rel.superior)
        push!(jurisdictions, rel.inferior)
    end
    
    # For now, just store direct relations
    # Transitivity will be handled by SMT solver
    return JurisdictionHierarchy(direct_relations, jurisdictions)
end

"""
    get_jurisdiction_relation(hierarchy::JurisdictionHierarchy, j1::Jurisdiction, j2::Jurisdiction)

Look up the relationship between two jurisdictions.

# Returns
- `:superior` if j1 > j2
- `:inferior` if j1 < j2  
- `:ambiguous` if j1 ~ j2
- `nothing` if no relationship defined
"""
function get_jurisdiction_relation(hierarchy::JurisdictionHierarchy, j1::Jurisdiction, j2::Jurisdiction)
    for rel in hierarchy.relations
        if rel.superior == j1 && rel.inferior == j2
            return rel.ambiguous ? :ambiguous : :superior
        elseif rel.superior == j2 && rel.inferior == j1
            return rel.ambiguous ? :ambiguous : :inferior
        end
    end
    return nothing
end

"""
    validate_jurisdiction_hierarchy(hierarchy::JurisdictionHierarchy)

Validate the jurisdiction hierarchy for basic structural issues.
Note: Cycle detection and transitivity validation are handled by SMT solver.

# Returns
- Vector of validation errors (empty if valid)
"""
function validate_jurisdiction_hierarchy(hierarchy::JurisdictionHierarchy)
    errors = String[]
    
    # Check for duplicate relations
    seen = Set{Tuple{Jurisdiction, Jurisdiction}}()
    for rel in hierarchy.relations
        key = (rel.superior, rel.inferior)
        if key in seen
            push!(errors, "Duplicate relation: $(string(rel.superior)) > $(string(rel.inferior))")
        end
        push!(seen, key)
    end
    
    # Check for contradictory ambiguous/non-ambiguous relations
    for i in 1:length(hierarchy.relations)
        for j in (i+1):length(hierarchy.relations)
            rel1 = hierarchy.relations[i]
            rel2 = hierarchy.relations[j]
            
            if rel1.superior == rel2.superior && rel1.inferior == rel2.inferior
                if rel1.ambiguous != rel2.ambiguous
                    push!(errors, "Contradictory relations: $(string(rel1.superior)) and $(string(rel1.inferior)) have both ambiguous and non-ambiguous relations")
                end
            end
        end
    end
    
    return errors
end

"""
    has_overrule_relationship(norm1::Norm, norm2::Norm)

Check if one norm explicitly overrules the other via the overrules field.
"""
function has_overrule_relationship(norm1::Norm, norm2::Norm)
    return any(n.ref_id == norm2.ref_id for n in norm1.overrules) ||
           any(n.ref_id == norm1.ref_id for n in norm2.overrules)
end

"""
    has_overrule_relationship(hierarchy::JurisdictionHierarchy, j1::Jurisdiction, j2::Jurisdiction)

Check if j1 has an explicit overrule relationship over j2 in the hierarchy (j1 > j2).
Returns true only for direct superior relationships, not transitive ones.
"""
function has_overrule_relationship(hierarchy::JurisdictionHierarchy, j1::Jurisdiction, j2::Jurisdiction)
    relation = get_jurisdiction_relation(hierarchy, j1, j2)
    return relation == :superior
end

"""
    parse_jurisdiction_hierarchy(ast)

Extract and parse the "Lex Superior" section from a document AST.
Returns a JurisdictionHierarchy or nothing if no such section exists.
"""
function parse_jurisdiction_hierarchy(ast)
    lex_superior_lines = String[]
    in_lex_superior = false
    
    for (node, entering) in ast
        if !entering
            continue
        end
        
        # Check for "Lex Superior" heading
        if node.t isa CommonMark.Heading
            heading_text = plain(node)
            if occursin(r"Lex\s+Superior"i, heading_text)
                in_lex_superior = true
                continue
            elseif in_lex_superior && node.t.level <= 2
                # End of Lex Superior section (next section starts)
                break
            end
        end
        
        # Extract lines from paragraphs in the Lex Superior section
        if in_lex_superior && node.t isa CommonMark.Paragraph
            paragraph_text = plain(node)
            # Split by newlines to handle multiple jurisdiction declarations in one paragraph
            for line in split(paragraph_text, '\n')
                line = strip(line)
                if !isempty(line)
                    push!(lex_superior_lines, line)
                end
            end
        end
    end
    
    # If we found lex superior declarations, parse them
    if !isempty(lex_superior_lines)
        return build_jurisdiction_hierarchy(parse_lex_superior(lex_superior_lines))
    end
    
    return nothing
end

"""
    merge_jurisdiction_hierarchies(h1::JurisdictionHierarchy, h2::JurisdictionHierarchy)

Merge two jurisdiction hierarchies by combining their relations and jurisdictions.
If there are conflicting relations (e.g., A>B in h1 but B>A in h2), the first one wins.
"""
function merge_jurisdiction_hierarchies(h1::JurisdictionHierarchy, h2::JurisdictionHierarchy)
    # Combine all jurisdictions
    all_jurisdictions = union(h1.jurisdictions, h2.jurisdictions)
    
    # Combine relations, avoiding duplicates
    # Use a set to track unique relations (superior, inferior, ambiguous)
    seen_relations = Set{Tuple{Jurisdiction, Jurisdiction, Bool}}()
    merged_relations = LexSuperior[]
    
    for rel in h1.relations
        key = (rel.superior, rel.inferior, rel.ambiguous)
        if !(key in seen_relations)
            push!(seen_relations, key)
            push!(merged_relations, rel)
        end
    end
    
    for rel in h2.relations
        key = (rel.superior, rel.inferior, rel.ambiguous)
        # Also check reverse to avoid conflicts
        reverse_key = (rel.inferior, rel.superior, rel.ambiguous)
        if !(key in seen_relations) && !(reverse_key in seen_relations)
            push!(seen_relations, key)
            push!(merged_relations, rel)
        end
    end
    
    return JurisdictionHierarchy(merged_relations, all_jurisdictions)
end
