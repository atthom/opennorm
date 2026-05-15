# Shared utilities for code generation
# Used by both OpenFisca Python and YAML generators

"""Standard accent mapping for French characters to ASCII equivalents"""
const ACCENT_MAP = Dict(
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

"""
    remove_accents(name::String)::String

Remove accented characters from a string, replacing them with ASCII equivalents.
Uses the ACCENT_MAP constant for character mapping.

# Examples
```julia
remove_accents("Déficit") # Returns "Deficit"
remove_accents("Année")   # Returns "Annee"
```
"""
function remove_accents(name::String)::String
    join([get(ACCENT_MAP, c, c) for c in name])
end

"""
    to_snake_case(name::String)::String

Convert OpenNorm variable name to snake_case format.
This function is used by both Python code generation and YAML parameter generation.

Process:
1. Remove asterisks (used for emphasis in OpenNorm)
2. Remove accents (convert to ASCII)
3. Convert CamelCase to snake_case
4. Clean up multiple underscores

# Examples
```julia
to_snake_case("RevenuGlobal")           # Returns "revenu_global"
to_snake_case("DéficitAgricole")        # Returns "deficit_agricole"
to_snake_case("*PlafondRenteEnfant*")   # Returns "plafond_rente_enfant"
```
"""
function to_snake_case(name::String)::String
    # Remove asterisks
    name = replace(name, "*" => "")
    
    # Remove accents
    name = remove_accents(name)
    
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

"""
    should_quote_python_value(value)::Bool

Check if a value should be quoted in Python code.
Returns true for non-numeric strings, false for numbers.

# Examples
```julia
should_quote_python_value("hello")  # Returns true
should_quote_python_value("123")    # Returns false
should_quote_python_value("45.67")  # Returns false
should_quote_python_value(123)      # Returns false
```
"""
function should_quote_python_value(value)::Bool
    if !(value isa String)
        return false
    end
    # Don't quote if it looks like a number (e.g., "123", "45.67")
    return !occursin(r"^\d+(\.\d+)?$", value)
end

"""
    format_python_value(value)::String

Format a value for Python code, adding quotes if needed.
Non-numeric strings are quoted, numbers are returned as-is.

# Examples
```julia
format_python_value("hello")  # Returns "'hello'"
format_python_value("123")    # Returns "123"
format_python_value(456)      # Returns "456"
```
"""
function format_python_value(value)::String
    if should_quote_python_value(value)
        return "'$(value)'"
    else
        return string(value)
    end
end

"""
    normalize_unit(unit::Union{Nothing, String})::Symbol

Normalize an OpenNorm unit to a standard category.
Returns one of: :currency, :year, :date, :bool, :percent, :float, :unknown

This provides a unified way to categorize units across different code generators.

# Examples
```julia
normalize_unit("EUR")           # Returns :currency
normalize_unit("Années")        # Returns :year
normalize_unit("Date")          # Returns :date
normalize_unit("%")             # Returns :percent
normalize_unit(nothing)         # Returns :float
normalize_unit("unknown_unit")  # Returns :unknown
```
"""
function normalize_unit(unit::Union{Nothing, String})::Symbol
    if unit === nothing
        return :float
    end
    
    unit_lower = lowercase(unit)
    
    if occursin("eur", unit_lower) || occursin("currency", unit_lower)
        return :currency
    elseif occursin("année", unit_lower) || occursin("year", unit_lower) || occursin("duration", unit_lower)
        return :year
    elseif occursin("date", unit_lower)
        return :date
    elseif occursin("bool", unit_lower) || occursin("oui", unit_lower) || occursin("non", unit_lower)
        return :bool
    elseif occursin("%", unit_lower) || occursin("percent", unit_lower)
        return :percent
    else
        return :unknown
    end
end

"""
    get_description_or_fallback(description, fallback)

Returns the description if it's not nothing, otherwise returns the fallback value.
This is commonly used to provide a default description when none is explicitly provided.

# Arguments
- `description::Union{Nothing, String}`: The optional description
- `fallback::String`: The fallback value to use if description is nothing

# Returns
- `String`: The description or fallback value
"""
function get_description_or_fallback(description::Union{Nothing, String}, fallback::String)::String
    return description !== nothing ? description : fallback
end
