# Dimensional Analysis System for OpenNorm

**Status:** Implemented  
**Date:** 2026-05-12  
**Purpose:** Enforce dimensional consistency in computed variable expressions using Unitful.jl

---

## Overview

The dimensional analysis system ensures that arithmetic operations in computed variables produce results with the correct dimensions. It prevents errors like multiplying two currency values (EUR × EUR) when the output is expected to be a currency (EUR).

## Key Features

✅ **Dynamic unit registration** - Units extracted from taxonomy, not hardcoded  
✅ **Compile-time checking** - Dimensional errors caught during parsing  
✅ **Unitful.jl integration** - Leverages battle-tested dimensional algebra  
✅ **Clear error messages** - Actionable suggestions for fixing mismatches  
✅ **Extensible** - Easy to add new units and dimensions  

---

## Architecture

### 1. Unit Extraction (`unit_system.jl`)

Units are extracted from the **Units** section of the Object Taxonomy:

```markdown
### Object Taxonomy
- AnyThing
  - Units
    - EUR (Currency)
    - USD (Currency)
    - Années (Duration)
    - % (Percentage)
```

**Process:**
1. Parse taxonomy to find Units section
2. Extract unit name and category from each child
3. Map category to Unitful dimension (Currency → :currency, Duration → :time, etc.)
4. Create `UnitDefinition` structs

### 2. Unit Registration (`unit_system.jl`)

Units are dynamically registered with Unitful.jl:

```julia
# Define custom Currency dimension
@dimension 𝐂 "𝐂" Currency

# Register each currency unit
@refunit EUR "EUR" Euro 𝐂 false
@refunit USD "USD" USDollar 𝐂 false
```

**Dimension Mapping:**
- `Currency` → Custom `𝐂` dimension
- `Duration` → Unitful's built-in time dimension
- `Percentage` → Dimensionless (NoUnits)
- Other categories → Extensible via `CATEGORY_TO_DIMENSION`

### 3. Type Environment Building (`unit_system.jl`)

Variable types are extracted from taxonomy declarations:

```markdown
- Parameters
  - RevenuBrut = *EUR* (required)
  - TauxImposition = *%*
  
- ComputedVariables
  - RevenuNet = *EUR*
```

**Process:**
1. Parse Constants, Parameters, and ComputedVariables sections
2. Extract type annotations (e.g., `*EUR*`)
3. Build mapping: `variable_name → Unitful.FreeUnits`

### 4. Expression Type Inference (`type_checker.jl`)

Expression dimensions are inferred using Unitful's dimensional algebra:

```julia
# EUR + EUR → EUR (addition preserves dimension)
# EUR × % → EUR (percentage is dimensionless)
# EUR × EUR → EUR² (multiplication multiplies dimensions)
# EUR / EUR → dimensionless (division divides dimensions)
```

**Rules:**
- **Addition/Subtraction:** Operands must have same dimension, result has that dimension
- **Multiplication:** Dimensions multiply (special case: dimensionless × X = X)
- **Division:** Dimensions divide
- **Functions:** `min`, `max`, `sum` preserve dimension; `round`, `ceil`, `floor` preserve dimension

### 5. Validation (`type_checker.jl`)

Computed variables are validated:

```julia
validate_computed_variable(
    var_name,        # "RevenuNet"
    expression,      # AST of the expression
    type_env,        # Variable → Unit mapping
    location         # "Procedure name" for error reporting
)
```

**Validation:**
1. Look up declared type of output variable
2. Infer type from expression
3. Compare dimensions
4. Throw `DimensionalMismatchError` if they don't match

---

## Integration Points

### Parser Integration (`parser.jl`)

Dimensional analysis is integrated into `parse_document`:

```julia
function parse_document(path, ...)
    # ... existing parsing ...
    
    # Extract and register units
    unit_defs = extract_units_from_taxonomy(objects)
    register_units!(unit_defs)
    
    # Build type environment
    type_env = build_type_environment(objects)
    
    # TODO: Validate procedures when procedure parsing is added
    
    # ... continue with SMT solving ...
end
```

### Future: Procedure Validation

When procedure parsing is implemented, validation will be added:

```julia
# Parse procedures from document
procedures = parse_procedures(ast, m.package)

# Validate each computed variable
for proc in procedures
    var_name = proc.output_variable
    expression = proc.expression
    validate_computed_variable(var_name, expression, type_env, proc.name)
end
```

---

## Error Reporting

### Dimensional Mismatch Error

```
═══════════════════════════════════════════════════════════════
❌ DIMENSIONAL ANALYSIS ERROR
═══════════════════════════════════════════════════════════════

  Variable:      RevenuCarré
  Location:      CalculRevenu
  Declared type: EUR
  Inferred type: EUR²

  Expression: *RevenuA* × *RevenuB*

  Problem:
    The expression produces 𝐂²,
    but the variable is declared as 𝐂.

  Suggestion:
    You are multiplying two quantities with the same dimension.
    Either:
      1. Use division instead of multiplication
      2. Declare RevenuCarré as EUR²

═══════════════════════════════════════════════════════════════
```

### Error Types

1. **EUR × EUR → EUR²** (but declared as EUR)
   - Suggestion: Use division or declare as EUR²

2. **Dimensionless result** (but declared with dimension)
   - Suggestion: Multiply by quantity with correct dimension

3. **Dimensional result** (but declared as dimensionless)
   - Suggestion: Divide to make dimensionless

---

## Usage Examples

### Valid Expressions

```markdown
# Addition: EUR + EUR → EUR
*RevenuNet* = *RevenuBrut* - *Charges*

# Percentage multiplication: EUR × % → EUR
*Impot* = *RevenuBrut* × *TauxImposition*

# Division: EUR / EUR → dimensionless
*Ratio* = *RevenuA* / *RevenuB*

# Function: min(EUR, EUR) → EUR
*PlafondAppliqué* = min(*Montant*, *Plafond*)
```

### Invalid Expressions

```markdown
# ERROR: EUR × EUR → EUR² (but declared as EUR)
- ComputedVariables
  - Produit = *EUR*

## *Produit*
*Produit* = *RevenuA* × *RevenuB*
```

**Error:** Multiplying two EUR values produces EUR², but `Produit` is declared as EUR.

**Fix 1:** Use division
```markdown
*Produit* = *RevenuA* / *RevenuB*  # → dimensionless
```

**Fix 2:** Declare correct type
```markdown
- ComputedVariables
  - Produit = *EUR²*  # If EUR² is a valid unit
```

---

## Adding New Units

To add a new unit, simply add it to the taxonomy:

```markdown
### Object Taxonomy
- AnyThing
  - Units
    - EUR (Currency)
    - GBP (Currency)  ← Add this line
    - km (Distance)   ← Add this line
```

**No code changes needed!** The system will:
1. Extract the new units
2. Register them with Unitful
3. Make them available for type annotations
4. Validate dimensional consistency

### Adding New Dimensions

To add a new dimension category:

1. Add to `CATEGORY_TO_DIMENSION` in `unit_system.jl`:
```julia
const CATEGORY_TO_DIMENSION = Dict{String, Symbol}(
    "Currency" => :currency,
    "Duration" => :time,
    "Distance" => :length,  ← Add this
    # ...
)
```

2. Add units to taxonomy:
```markdown
- Units
  - km (Distance)
  - m (Distance)
```

---

## Implementation Status

### ✅ Completed

- [x] Unit extraction from taxonomy
- [x] Dynamic unit registration with Unitful
- [x] Type environment building
- [x] Expression type inference
- [x] Dimensional mismatch error reporting
- [x] Parser integration (infrastructure)
- [x] Test suite

### 🚧 Pending

- [ ] Procedure parsing (operational layer)
- [ ] Expression parsing from markdown
- [ ] Full validation of computed variables
- [ ] Compound units (EUR/Années)
- [ ] Unit conversion support

---

## Technical Details

### Unitful.jl Integration

**Why Unitful.jl?**
- Mature, well-tested library
- Automatic dimensional algebra
- Type-safe at compile time
- Extensible with custom dimensions

**Custom Dimensions:**
```julia
@dimension 𝐂 "𝐂" Currency  # Custom currency dimension
```

**Unit Registration:**
```julia
@refunit EUR "EUR" Euro 𝐂 false
```

**Dimensional Algebra:**
```julia
EUR * EUR → EUR²
EUR / EUR → NoUnits
EUR * NoUnits → EUR
```

### Type Environment

The type environment is a dictionary mapping variable names to Unitful types:

```julia
Dict{String, Unitful.FreeUnits}(
    "RevenuBrut" => EUR,
    "TauxImposition" => NoUnits,
    "RevenuNet" => EUR,
    # ...
)
```

### Expression AST

Expressions are represented as an AST for type checking:

```julia
abstract type ExprNode end

struct VariableRef <: ExprNode
    name::String
end

struct BinaryOp <: ExprNode
    op::Symbol  # :+, :-, :*, :/
    left::ExprNode
    right::ExprNode
end

struct FunctionCall <: ExprNode
    func::Symbol
    args::Vector{ExprNode}
end
```

---

## Testing

Run the test suite:

```bash
julia test_dimensional_analysis.jl
```

**Tests:**
1. Document parsing with units
2. Unit extraction from taxonomy
3. Unit registration with Unitful
4. Type environment building
5. Expression type inference
6. Dimensional mismatch detection

---

## Future Enhancements

### 1. Compound Units

Support units like `EUR/Années` (euros per year):

```markdown
- ComputedVariables
  - RevenuAnnuel = *EUR/Années*
```

### 2. Unit Conversion

Automatic conversion between compatible units:

```markdown
*DistanceKm* = *DistanceM* / 1000  # m → km
```

### 3. Dimensional Constraints in Norms

Extend norms to specify dimensional constraints:

```markdown
*FoyerFiscal* **a le droit de** *déduire* *frais professionnels:EUR*
à *AdministrationFiscale*
```

### 4. Procedure-Level Type Inference

Infer output types from expressions when not explicitly declared:

```markdown
## *RevenuNet*
# Type inferred as EUR from expression
*RevenuNet* = *RevenuBrut* - *Charges*
```

---

## References

- [Unitful.jl Documentation](https://painterqubits.github.io/Unitful.jl/stable/)
- [OpenNorm Operational Layer Spec](./OPERATIONAL_LAYER_SPEC.md)
- [OpenNorm Type System](./OPERATIONAL_LAYER_DESIGN.md#6-units-and-types)

---

## Summary

The dimensional analysis system provides **compile-time verification** that arithmetic operations in computed variables produce results with the correct dimensions. By leveraging Unitful.jl and extracting units dynamically from the taxonomy, the system is both **powerful and flexible**, catching dimensional errors early while remaining easy to extend with new units and dimensions.