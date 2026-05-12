using Unitful
using Unitful: @dimension, @derived_dimension, @refunit, @unit

# Structure to hold unit definitions extracted from taxonomy
struct UnitDefinition
    name::String           # "EUR", "Années", etc.
    category::String       # "Currency", "Duration", etc.
    base_dimension::Symbol # :currency, :time, :dimensionless
end

# Map taxonomy categories to Unitful dimensions
const CATEGORY_TO_DIMENSION = Dict{String, Symbol}(
    "Currency" => :currency,
    "Duration" => :time,
    "Percentage" => :dimensionless,
    "Distance" => :length,
    "Mass" => :mass,
    "" => :dimensionless  # No category = dimensionless
)

# Map common unit names to Unitful equivalents
const UNIT_ALIASES = Dict{String, String}(
    "Années" => "yr",
    "Mois" => "mo",
    "Jours" => "d",
    "%" => "NoUnits"
)

# Global registry of registered units
const UNIT_REGISTRY = Dict{String, Unitful.FreeUnits}()

"""
    extract_units_from_taxonomy(object_taxonomy::Taxon{Object})

Extract unit definitions from the Units section of the Object taxonomy.
Returns a vector of UnitDefinition structs.
"""
function extract_units_from_taxonomy(object_taxonomy::Taxon{Object})
    units = UnitDefinition[]
    
    # Find the "Units" node in the taxonomy
    units_node = find_child_by_name(object_taxonomy, "Units")
    if units_node === nothing
        @warn "No Units section found in Object taxonomy"
        return units
    end
    
    # Extract each unit definition
    for unit_node in units_node.children
        name_with_category = unit_node.name
        
        # Parse category from parentheses: "EUR (Currency)" -> ("EUR", "Currency")
        name, category = parse_unit_declaration(name_with_category)
        
        # Determine base dimension
        dimension = get(CATEGORY_TO_DIMENSION, category, :dimensionless)
        
        push!(units, UnitDefinition(name, category, dimension))
    end
    
    return units
end

"""
    parse_unit_declaration(text::String)

Parse a unit declaration like "EUR (Currency)" into name and category.
Returns (name, category) tuple.
"""
function parse_unit_declaration(text::String)
    text = strip(text)
    
    # Match pattern: "Name (Category)" or just "Name"
    m = match(r"^([^(]+?)(?:\s*\(([^)]+)\))?$", text)
    
    if m === nothing
        return (text, "")
    end
    
    name = strip(m.captures[1])
    category = m.captures[2] !== nothing ? strip(m.captures[2]) : ""
    
    return (name, category)
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
    register_units!(unit_defs::Vector{UnitDefinition})

Dynamically register units with Unitful based on taxonomy definitions.
Returns a dictionary mapping unit names to Unitful.FreeUnits.
"""
function register_units!(unit_defs::Vector{UnitDefinition})
    # Clear previous registry
    empty!(UNIT_REGISTRY)
    
    # Group units by dimension
    by_dimension = Dict{Symbol, Vector{UnitDefinition}}()
    for unit in unit_defs
        if !haskey(by_dimension, unit.base_dimension)
            by_dimension[unit.base_dimension] = UnitDefinition[]
        end
        push!(by_dimension[unit.base_dimension], unit)
    end
    
    # Register currency dimension if needed
    if haskey(by_dimension, :currency)
        register_currency_units!(by_dimension[:currency])
    end
    
    # Map time units to existing Unitful time dimension
    if haskey(by_dimension, :time)
        register_time_units!(by_dimension[:time])
    end
    
    # Handle dimensionless units
    if haskey(by_dimension, :dimensionless)
        register_dimensionless_units!(by_dimension[:dimensionless])
    end
    
    return UNIT_REGISTRY
end

"""
    register_currency_units!(units::Vector{UnitDefinition})

Register currency units with Unitful.
Uses the generated currency dimensions from generated_currency_units.jl.
"""
function register_currency_units!(units::Vector{UnitDefinition})
    # Currency units are now defined at top level in generated_currency_units.jl
    # We just need to add them to our registry
    
    for unit in units
        # Check if the currency unit was generated and is available
        currency_symbol = Symbol(unit.name)
        if isdefined(Main, currency_symbol)
            # Get the unit from the global scope
            currency_unit = getfield(Main, currency_symbol)
            UNIT_REGISTRY[unit.name] = currency_unit
        else
            @warn "Currency unit $(unit.name) not found in generated units. Using dimensionless fallback."
            UNIT_REGISTRY[unit.name] = Unitful.NoUnits
        end
    end
end

"""
    register_time_units!(units::Vector{UnitDefinition})

Register time units by mapping to existing Unitful time units.
"""
function register_time_units!(units::Vector{UnitDefinition})
    for unit in units
        # Check if there's an alias
        if haskey(UNIT_ALIASES, unit.name)
            alias = UNIT_ALIASES[unit.name]
            # Map to existing Unitful unit
            UNIT_REGISTRY[unit.name] = uparse(alias)
        else
            # Try to parse directly
            try
                UNIT_REGISTRY[unit.name] = uparse(unit.name)
            catch
                @warn "Could not map time unit $(unit.name) to Unitful"
            end
        end
    end
end

"""
    register_dimensionless_units!(units::Vector{UnitDefinition})

Register dimensionless units (percentages, booleans, dates).
"""
function register_dimensionless_units!(units::Vector{UnitDefinition})
    for unit in units
        # All dimensionless units map to NoUnits
        UNIT_REGISTRY[unit.name] = Unitful.NoUnits
    end
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
    
    # Process Parameters FIRST (so Constants can reference them)
    params_node = find_child_by_name(opennorm_vars, "Parameters")
    if params_node !== nothing
        for param_node in params_node.children
            var_name, unit_name = parse_variable_type_annotation(param_node.name)
            if unit_name !== nothing && haskey(UNIT_REGISTRY, unit_name)
                type_env[var_name] = UNIT_REGISTRY[unit_name]
            end
        end
    end
    
    # Process Constants SECOND (can now reference Parameters)
    constants_node = find_child_by_name(opennorm_vars, "Constants")
    if constants_node !== nothing
        for const_node in constants_node.children
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
        for comp_node in computed_node.children
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
    m = match(r"^([^=]+?)\s*=\s*\*([^*]+)\*", text)
    if m !== nothing
        var_name = strip(m.captures[1])
        unit_name = strip(m.captures[2])
        return (var_name, unit_name)
    end
    
    # Pattern 3: "VarName = value Unit" (Constants without asterisks - parser stripped them)
    # Match known units: EUR, USD, Années, etc.
    m = match(r"^([^=]+?)\s*=\s*[\d\s,.]+(EUR|USD|Années|Mois|Jours)", text)
    if m !== nothing
        var_name = strip(m.captures[1])
        unit_name = strip(m.captures[2])
        return (var_name, unit_name)
    end
    
    # Pattern 4: "VarName = Unit ..." (Parameters/ComputedVariables without asterisks)
    m = match(r"^([^=]+?)\s*=\s*(EUR|USD|Années|Mois|Jours)\b", text)
    if m !== nothing
        var_name = strip(m.captures[1])
        unit_name = strip(m.captures[2])
        return (var_name, unit_name)
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
