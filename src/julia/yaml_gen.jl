# YAML Parameter File Generation for OpenFisca
# Generates YAML parameter files from OpenNorm Constants

using YAML
using ..Structures: DocumentIR, Taxon, Object, TaxonomyEnum
using ..Structures.Taxonomies: find_child_by_name

"""
Extract Constants from the Object taxonomy
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

"""Convert OpenNorm variable name to snake_case for YAML keys"""
function to_snake_case_yaml(name::String)::String
    # Remove asterisks
    name = replace(name, "*" => "")
    
    # Remove accents
    accent_map = Dict(
        'à' => 'a', 'á' => 'a', 'â' => 'a', 'ã' => 'a', 
        'À' => 'A', 'Á' => 'A', 'Â' => 'A', 'Ã' => 'A', 
        'Ä' => 'A', 'Å' => 'A', 'ä' => 'a', 'å' => 'a',
        'è' => 'e', 'é' => 'e', 'ê' => 'e', 'ë' => 'e',
        'ì' => 'i', 'í' => 'i', 'î' => 'i', 'ï' => 'i',
        'ò' => 'o', 'ó' => 'o', 'ô' => 'o', 'õ' => 'o', 'ö' => 'o',
        'Ò' => 'O', 'Ó' => 'O', 'Ô' => 'O', 'Õ' => 'O', 'Ö' => 'O',
        'ù' => 'u', 'ú' => 'u', 'û' => 'u', 'ü' => 'u',
        'ý' => 'y', 'ÿ' => 'y', 'ñ' => 'n', 'ç' => 'c',
        'È' => 'E', 'É' => 'E', 'Ê' => 'E', 'Ë' => 'E',
        'Ì' => 'I', 'Í' => 'I', 'Î' => 'I', 'Ï' => 'I',
        'Ù' => 'U', 'Ú' => 'U', 'Û' => 'U', 'Ü' => 'U',
        'Ý' => 'Y', 'Ÿ' => 'Y', 'Ñ' => 'N', 'Ç' => 'C'
    )
    
    name = join([get(accent_map, c, c) for c in name])
    
    # Convert to snake_case
    result = ""
    prev_was_upper = false
    
    for (i, c) in enumerate(name)
        if isuppercase(c) && i > 1 && !prev_was_upper
            result *= "_" * lowercase(c)
            prev_was_upper = true
        else
            result *= lowercase(c)
            prev_was_upper = isuppercase(c)
        end
    end
    
    # Clean up multiple underscores
    result = replace(result, r"_+" => "_")
    result = strip(result, '_')
    
    return result
end

"""Map OpenNorm unit to OpenFisca YAML unit metadata"""
function map_unit_to_openfisca(unit::String)::String
    unit_lower = lowercase(unit)
    if occursin("eur", unit_lower) || occursin("currency", unit_lower)
        return "currency-EUR"
    elseif occursin("année", unit_lower) || occursin("year", unit_lower)
        return "year"
    elseif occursin("%", unit_lower) || occursin("percent", unit_lower)
        return "/1"
    else
        return unit  # Keep original if unknown
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

"""Generate OpenFisca YAML parameter file from DocumentIR"""
function generate_yaml_parameters(ir::DocumentIR)::String
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
        param_key = to_snake_case_yaml(name)
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

"""Generate YAML parameter file and save to disk"""
function generate_yaml_file(ir::DocumentIR, output_path::String)
    yaml_content = generate_yaml_parameters(ir)
    
    open(output_path, "w") do f
        write(f, yaml_content)
    end
    
    return yaml_content
end