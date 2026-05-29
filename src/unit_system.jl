using Unitful
using Unitful: @dimension, @derived_dimension, @refunit, @unit

# Structure to hold unit definitions extracted from taxonomy
struct UnitDefinition
    name::String                      # "EUR", "Années", etc.
    dimension_path::Vector{String}    # ["Currency"], ["Time", "Duration"], etc.
    alias::Union{Nothing, String}     # "yr", "mo", etc. for mapping to Unitful
end

# Global registry of registered units
const UNIT_REGISTRY = Dict{String, Unitful.FreeUnits}()

"""
    extract_units_from_taxonomy(object_taxonomy::Taxon{Object})

Extract unit definitions from the Units section of the Object taxonomy.
Walks the hierarchy to extract dimension paths and aliases.
Returns a vector of UnitDefinition structs.

Example hierarchy:
  - Units
    - Currency
      - EUR
      - USD
    - Time
      - Duration
        - Années (alias: yr)
"""
function extract_units_from_taxonomy(object_taxonomy::Taxon{Object})
    units = UnitDefinition[]
    
    # Find the "Units" node in the taxonomy
    units_node = find_child_by_name(object_taxonomy, "Units")
    if units_node === nothing
        @warn "No Units section found in Object taxonomy"
        return units
    end
    
    # Recursively extract units from the hierarchy
    extract_units_recursive!(units, units_node, String[])
    
    return units
end

"""
    extract_units_recursive!(units::Vector{UnitDefinition}, 
                            node::Taxon{Object}, 
                            path::Vector{String})

Recursively walk the Units taxonomy to extract unit definitions.
Leaf nodes are units, intermediate nodes define dimension hierarchy.
"""
function extract_units_recursive!(units::Vector{UnitDefinition}, 
                                 node::Taxon{Object}, 
                                 path::Vector{String})
    # If this node has children, it's a dimension category - recurse
    if !isempty(node.children)
        for child in node.children
            # Add current node name to path (unless it's the root "Units" node)
            new_path = isempty(node.name) || node.name == "Units" ? path : [path; node.name]
            extract_units_recursive!(units, child, new_path)
        end
    else
        # Leaf node - this is an actual unit
        unit_name, alias = parse_unit_with_alias(node.name)
        
        # Create unit definition with the dimension path
        push!(units, UnitDefinition(unit_name, path, alias))
    end
end

"""
    parse_unit_with_alias(text::String)

Parse a unit declaration that may include an alias.
Examples:
  - "EUR" -> ("EUR", nothing)
  - "Années (alias: yr)" -> ("Années", "yr")
  - "ISO8601" -> ("ISO8601", nothing)

Returns (unit_name, alias) tuple.
"""
function parse_unit_with_alias(text::String)
    text = strip(text)
    
    # Match pattern: "Name (alias: value)" or just "Name"
    m = match(r"^([^(]+?)(?:\s*\(alias:\s*([^)]+)\))?$", text)
    
    if m === nothing
        return (text, nothing)
    end
    
    name = strip(m.captures[1])
    alias = m.captures[2] !== nothing ? strip(m.captures[2]) : nothing
    
    return (name, alias)
end

"""
    find_child_by_name(taxon::Taxon{T}, name::String) where {T<:TaxonomyEnum}

Find a direct child of a taxon by name.
"""
function find_child_by_name(taxon::Taxon{T}, name::String) where {T<:TaxonomyEnum}
    for child in taxon.children
        if child.name == name
            return child
        end
    end
    return nothing
end

"""
    generate_unit_dynamically(unit_name::String)

Dynamically generate a Unitful dimension and unit at runtime.
Each unit gets its own dimension to prevent mixing (e.g., EUR and USD are incompatible).
"""
function generate_unit_dynamically(unit_name::String)
    # Create unique dimension and unit names
    dim_name = Symbol(unit_name * "Dim")
    dim_type_name = Symbol(unit_name * "Dimension")
    unit_type_name = Symbol(unit_name * "Unit")
    unit_symbol = Symbol(unit_name)
    
    # Generate dimension using eval
    # @dimension creates a new dimension type
    eval(quote
        @dimension $dim_name $unit_name $dim_type_name true
    end)
    
    # Generate reference unit using eval
    # @refunit creates a unit with the specified dimension
    eval(quote
        @refunit $unit_symbol $unit_name $unit_type_name $dim_name true
    end)
    
    # Return the generated unit
    return eval(unit_symbol)
end

"""
    register_units!(unit_defs::Vector{UnitDefinition})

Dynamically register units with Unitful based on taxonomy definitions.
Uses the dimension_path from the hierarchy to determine how to register each unit.
Returns a dictionary mapping unit names to Unitful.FreeUnits.
"""
function register_units!(unit_defs::Vector{UnitDefinition})
    # Clear previous registry
    empty!(UNIT_REGISTRY)
    
    for unit in unit_defs
        try
            # Determine how to register based on the dimension path
            if isempty(unit.dimension_path)
                # No path - treat as dimensionless (e.g., Boolean at root level)
                UNIT_REGISTRY[unit.name] = Unitful.NoUnits
                
            elseif unit.dimension_path[1] == "Currency"
                # Currency units - each gets its own dimension
                unit_obj = generate_unit_dynamically(unit.name)
                UNIT_REGISTRY[unit.name] = unit_obj
                
            elseif unit.dimension_path[1] == "Time"
                # Time-related units
                if unit.alias !== nothing
                    # Has alias - map to Unitful's time dimension
                    UNIT_REGISTRY[unit.name] = uparse(unit.alias)
                elseif unit.name == "Date" || (length(unit.dimension_path) > 1 && unit.dimension_path[2] == "Date")
                    # Date formats are dimensionless
                    UNIT_REGISTRY[unit.name] = Unitful.NoUnits
                else
                    # Try to parse as Unitful time unit
                    try
                        UNIT_REGISTRY[unit.name] = uparse(unit.name)
                    catch
                        @warn "Could not map time unit $(unit.name) to Unitful, treating as dimensionless"
                        UNIT_REGISTRY[unit.name] = Unitful.NoUnits
                    end
                end
                
            elseif unit.dimension_path[1] == "Percentage"
                # Percentages are dimensionless
                UNIT_REGISTRY[unit.name] = Unitful.NoUnits
                
            elseif unit.dimension_path[1] == "Boolean"
                # Booleans are dimensionless
                UNIT_REGISTRY[unit.name] = Unitful.NoUnits
                
            else
                # Unknown dimension category - try to handle generically
                # For now, generate a custom dimension
                @warn "Unknown dimension category: $(unit.dimension_path[1]), generating custom dimension"
                unit_obj = generate_unit_dynamically(unit.name)
                UNIT_REGISTRY[unit.name] = unit_obj
            end
            
        catch e
            @warn "Failed to register unit $(unit.name): $e"
            UNIT_REGISTRY[unit.name] = Unitful.NoUnits
        end
    end
    
    return UNIT_REGISTRY
end

"""
    build_type_environment(object_taxonomy::Taxon{Object})

Build a mapping from variable names to their Unitful types.
Extracts type annotations from Constants, Parameters, and ComputedVariables.
"""
function build_type_environment(object_taxonomy::Taxon{Object})
    type_env = Dict{String, Unitful.FreeUnits}()
    
    # First find OpenNormVariables node
    opennorm_vars = find_child_by_name(object_taxonomy, "OpenNormVariables")
    if opennorm_vars === nothing
        return type_env  # No variables defined
    end
    
    # Helper function to recursively collect all nodes that look like variable declarations
    # This includes both leaf nodes and nodes with children (which may have metadata)
    function collect_variable_declarations(node::Taxon{Object})
        declarations = Taxon{Object}[]
        
        # Check if this node looks like a variable declaration (has = in the name)
        if occursin("=", node.name)
            push!(declarations, node)
            
            # Warn if this variable has children (unexpected metadata)
            if !isempty(node.children)
                @warn "Variable '$(split(node.name, "=")[1] |> strip)' has unexpected child nodes. This may indicate non-standard metadata in the taxonomy."
            end
        end
        
        # Recurse into children regardless
        for child in node.children
            append!(declarations, collect_variable_declarations(child))
        end
        
        return declarations
    end
    
    # Process Parameters FIRST (so Constants can reference them)
    params_node = find_child_by_name(opennorm_vars, "Parameters")
    if params_node !== nothing
        for param_node in collect_variable_declarations(params_node)
            var_name, unit_name = parse_variable_type_annotation(param_node.name)
            if unit_name !== nothing && haskey(UNIT_REGISTRY, unit_name)
                type_env[var_name] = UNIT_REGISTRY[unit_name]
            end
        end
    end
    
    # Process Constants SECOND (can now reference Parameters)
    constants_node = find_child_by_name(opennorm_vars, "Constants")
    if constants_node !== nothing
        for const_node in collect_variable_declarations(constants_node)
            var_name, unit_name = parse_variable_type_annotation(const_node.name)
            if unit_name !== nothing
                if haskey(UNIT_REGISTRY, unit_name)
                    # Direct unit reference
                    type_env[var_name] = UNIT_REGISTRY[unit_name]
                elseif haskey(type_env, unit_name)
                    # Variable reference - inherit type from referenced variable
                    type_env[var_name] = type_env[unit_name]
                end
            end
        end
    end
    
    # Process ComputedVariables
    computed_node = find_child_by_name(opennorm_vars, "ComputedVariables")
    if computed_node !== nothing
        for comp_node in collect_variable_declarations(computed_node)
            var_name, unit_name = parse_variable_type_annotation(comp_node.name)
            if unit_name !== nothing && haskey(UNIT_REGISTRY, unit_name)
                type_env[var_name] = UNIT_REGISTRY[unit_name]
            end
        end
    end
    
    return type_env
end

"""
    parse_variable_type_annotation(text::String)

Parse variable type annotations from taxonomy declarations.
Examples:
  - "SeuilRevenuAutres = 127 677 *EUR*" -> ("SeuilRevenuAutres", "EUR")
  - "RevenuAutresSources = *EUR* (required)" -> ("RevenuAutresSources", "EUR")
  - "DéficitAgricoleImputable = *EUR*" -> ("DéficitAgricoleImputable", "EUR")
  - "LimiteDéduction = LimiteArt154bis0A" -> ("LimiteDéduction", "LimiteArt154bis0A")
  - "ModeDéduction (*FraisRéels*, *Forfaitaire*)" -> ("ModeDéduction", nothing)

Returns (variable_name, unit_name) where unit_name may be nothing.
"""
function parse_variable_type_annotation(text::String)
    text = strip(text)
    
    # Pattern 1: "VarName = value *Unit*" (Constants with asterisks)
    m = match(r"^([^=]+?)\s*=\s*[^*]*\*([^*]+)\*", text)
    if m !== nothing
        var_name = strip(m.captures[1])
        unit_name = strip(m.captures[2])
        return (var_name, unit_name)
    end
    
    # Pattern 2: "VarName = *Unit* ..." (Parameters/ComputedVariables with asterisks)
    # This also handles Constants that reference other variables with asterisks
    m = match(r"^([^=]+?)\s*=\s*\*([^*]+)\*", text)
    if m !== nothing
        var_name = strip(m.captures[1])
        unit_or_var_name = strip(m.captures[2])
        return (var_name, unit_or_var_name)
    end
    
    # Pattern 3: "VarName = value Unit" (Constants without asterisks - parser stripped them)
    # Try to match any word after the value that might be a unit
    m = match(r"^([^=]+?)\s*=\s*[\d\s,.]+([A-Za-zÀ-ÿ]+)", text)
    if m !== nothing
        var_name = strip(m.captures[1])
        potential_unit = strip(m.captures[2])
        # Only return if it looks like a unit (check if it's in the registry)
        # This will be validated later when building the type environment
        return (var_name, potential_unit)
    end
    
    # Pattern 4: "VarName = Unit ..." (Parameters/ComputedVariables without asterisks)
    # Match any capitalized word that could be a unit
    m = match(r"^([^=]+?)\s*=\s*([A-Za-zÀ-ÿ]+)\b", text)
    if m !== nothing
        var_name = strip(m.captures[1])
        potential_unit = strip(m.captures[2])
        return (var_name, potential_unit)
    end
    
    # Pattern 5: "VarName = VariableReference" (Constants referencing other variables, no asterisks)
    # Match: variable name followed by = followed by a capitalized identifier (variable reference)
    m = match(r"^([^=]+?)\s*=\s*([A-ZÀÂÄÉÈÊËÏÎÔÙÛÜŸÆŒÇ][A-Za-z0-9àâäéèêëïîôùûüÿæœçÀÂÄÉÈÊËÏÎÔÙÛÜŸÆŒÇ]*)", text)
    if m !== nothing
        var_name = strip(m.captures[1])
        unit_name = strip(m.captures[2])
        return (var_name, unit_name)
    end
    
    # Pattern 6: "VarName (*Enum1*, *Enum2*, ...)" (Enum parameters - no unit)
    m = match(r"^([^(]+?)\s*\(", text)
    if m !== nothing
        var_name = strip(m.captures[1])
        return (var_name, nothing)
    end
    
    # Pattern 7: Just "VarName" (no type annotation)
    return (text, nothing)
end
