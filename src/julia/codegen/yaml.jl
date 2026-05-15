# YAML Parameter File Generation for OpenFisca Backend
# Generates YAML parameter files from OpenNorm Constants

using YAML

# ============================================================================
# CONSTANT EXTRACTION FROM TAXONOMY
# ============================================================================

"""
Extract Constants from the Object taxonomy.
Returns a vector of tuples: (name, value, unit)
"""
function extract_constants_from_taxonomy(object_taxonomy::Taxon{Object})
    constants = Tuple{String, String, String}[]
    
    # Find OpenNormVariables node
    opennorm_vars = find_child_by_name(object_taxonomy, "OpenNormVariables")
    if opennorm_vars === nothing
        return constants
    end
    
    # Find Constants node
    constants_node = find_child_by_name(opennorm_vars, "Constants")
    if constants_node === nothing
        return constants
    end
    
    # Extract each constant
    for const_node in constants_node.children
        # Parse "Name = value Unit" format (asterisks are stripped during parsing)
        text = const_node.name
        
        # Match pattern: "Name = value Unit" where Unit is a word at the end
        # Examples: "SeuilRevenuAutres = 127 677 EUR", "DuréeReport = 6 Années"
        m = match(r"^([^=]+?)\s*=\s*(.+?)\s+([A-Za-zÀ-ÿ/]+)$", text)
        if m !== nothing
            name = strip(m.captures[1])
            value = strip(m.captures[2])
            unit = strip(m.captures[3])
            push!(constants, (name, value, unit))
        end
    end
    
    return constants
end

# ============================================================================
# UNIT AND VALUE MAPPING
# ============================================================================

"""Map OpenNorm unit to OpenFisca YAML unit metadata"""
function map_unit_to_openfisca(unit::String)::String
    unit_category = normalize_unit(unit)
    
    return if unit_category == :currency
        "currency-EUR"
    elseif unit_category == :year
        "year"
    elseif unit_category == :percent
        "/1"
    else
        unit  # Keep original if unknown
    end
end

"""Parse numeric value from string, handling spaces in numbers"""
function parse_numeric_value(value_str::String)
    # Remove spaces from numbers (e.g., "127 677" -> "127677")
    cleaned = replace(value_str, r"\s+" => "")
    
    # Try to parse as number
    try
        # Try integer first
        if !occursin(".", cleaned)
            return parse(Int, cleaned)
        else
            return parse(Float64, cleaned)
        end
    catch
        # If parsing fails, return as string
        return value_str
    end
end

# ============================================================================
# YAML GENERATION - YAML BACKEND
# ============================================================================

"""
    code_gen(::YAMLBackend, ir::DocumentIR)::String

Generate OpenFisca YAML parameter file from DocumentIR.
Extracts constants from the taxonomy and formats them as YAML.

# Arguments
- `backend::YAMLBackend`: The YAML backend instance
- `ir::DocumentIR`: The document IR containing the taxonomy

# Returns
- `String`: YAML-formatted parameter file content
"""
function code_gen(backend::YAMLBackend, ir::DocumentIR)::String
    # Extract constants from taxonomy
    constants = extract_constants_from_taxonomy(ir.objectTaxonomy)
    
    if isempty(constants)
        return "# No constants found in document\n"
    end
    
    # Build YAML structure
    yaml_dict = Dict{String, Any}(
        "description" => ir.manifest.title,
        "metadata" => Dict{String, Any}(
            "reference" => "$(ir.manifest.package) v$(ir.manifest.version)"
        )
    )
    
    # Add each constant as a parameter
    for (name, value, unit) in constants
        param_key = to_snake_case(name)
        numeric_value = parse_numeric_value(value)
        unit_metadata = map_unit_to_openfisca(unit)
        
        yaml_dict[param_key] = Dict{String, Any}(
            "description" => name,
            "metadata" => Dict{String, Any}(
                "unit" => unit_metadata,
                "reference" => ir.manifest.package
            ),
            "values" => Dict{String, Any}(
                "1950-01-01" => Dict{String, Any}(
                    "value" => numeric_value
                )
            )
        )
    end
    
    # Convert to YAML string
    return YAML.write(yaml_dict)
end

# ============================================================================
# HELPER FUNCTIONS (for backward compatibility)
# ============================================================================

"""
Generate YAML parameter file from DocumentIR.
Wrapper around code_gen for backward compatibility.
"""
function generate_yaml_parameters(ir::DocumentIR)::String
    backend = YAMLBackend()
    return code_gen(backend, ir)
end

"""
Generate YAML parameter file and save to disk.
"""
function generate_yaml_file(ir::DocumentIR, output_path::String)
    yaml_content = generate_yaml_parameters(ir)
    
    open(output_path, "w") do f
        write(f, yaml_content)
    end
    
    return yaml_content
end