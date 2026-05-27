# Exception Norm Constructor Implementation

## Overview

This document describes the constructor-based approach for creating exception norms in OpenNorm. Exception norms are created correctly from the start, without requiring a separate expansion step.

## Design Principles

1. **Constructor-based creation** - Exception norms inherit from parent via constructor
2. **Type safety** - Constructor enforces correct structure
3. **Clear semantics** - Minimal syntax uses special constructor, full syntax validated
4. **No expansion step** - Norms are created correctly from the start

## Implementation

### 1. Exception Norm Constructor

Located in `src/julia/structures/IntermediateRepresentation.jl` (lines 185-200):

```julia
function Norm(parent::Norm, ref_id::String; text::String="")
    return Norm(
        ref_id = ref_id,
        package = parent.package,
        Hohfeld = O(parent.Hohfeld),  # Auto-compute opposite
        actor = parent.actor,
        action = parent.action,
        object = parent.object,
        counterparty = parent.counterparty,
        overrules = Norm[],
        excepts = parent.ref_id,  # Link to parent
        depth = parent.depth + 1,  # Increment depth
        skipped = false,
        text = text
    )
end
```

**Features:**
- Inherits `actor`, `action`, `object`, `counterparty` from parent
- Auto-computes `Hohfeld` position as `O(parent.Hohfeld)` (Hohfeldian opposite)
- Sets `excepts` to parent's `ref_id`
- Increments `depth` from parent
- Accepts optional `text` parameter

### 2. Parser Integration

Located in `src/julia/parser/norms.jl`:

#### Two-Pass Parsing

The parser uses a two-pass approach to handle forward references:

1. **First pass**: Parse all non-exception norms
2. **Second pass**: Parse exception norms (which can reference norms from first pass)

#### Exception Detection

```julia
# Pattern: exception de #parent-ref-id [lorsque condition] [full norm syntax]
exception_pattern = r"exception\s+de\s+#([\w-]+)"
```

#### Minimal Syntax Handling

When minimal syntax is detected (no explicit Hohfeldian keyword):

```julia
# Find parent norm
parent_norm = find_norm_by_ref(norms, parent_ref)

# Create exception using constructor
return Norm(parent_norm, ref_id, text=norm_text)
```

#### Full Syntax Validation

When full syntax is provided (explicit actor/action/object/counterparty):

```julia
# Parse explicit fields
# Validate position is opposite of parent
expected_position = O(parent_norm.Hohfeld)
if position != expected_position
    error("Position must be opposite of parent")
end

# Validate actor/action/object/counterparty match parent
# ... validation checks ...

# Create with explicit fields
return Norm(
    ref_id=ref_id,
    # ... explicit fields ...
    excepts=parent_norm.ref_id,
    depth=parent_norm.depth + 1
)
```

### 3. Helper Functions

#### find_norm_by_ref

```julia
function find_norm_by_ref(norms::Vector{Norm}, ref_id::String)
    for norm in norms
        if norm.ref_id == ref_id
            return norm
        end
    end
    return nothing
end
```

#### parse_full_exception

Parses and validates full exception syntax, ensuring all explicit fields match the parent norm.

## Syntax Examples

### Minimal Syntax

```markdown
### Exception Monument Historique

exception de #art156-I-3-interdiction-dépassement-plafond
lorsque *TypePropriété* = *MonumentHistorique*
{#art156-I-3-monument-historique}
```

**Result:**
- Inherits all fields from parent
- Position auto-computed as opposite
- Depth incremented
- Linked via `excepts` field

### Full Syntax

```markdown
### Exception Monument Historique

exception de #art156-I-3-interdiction-dépassement-plafond
lorsque *TypePropriété* = *MonumentHistorique*
*Propriétaire* **a le droit de** *déduire* *déficit foncier* envers *Administration fiscale*
{#art156-I-3-monument-historique}
```

**Result:**
- Explicit fields validated against parent
- Position must be opposite of parent
- Actor/action/object/counterparty must match parent
- Error if validation fails

## Exception Depth and Position

Exceptions follow an alternating pattern:

- **Depth 0** (base rule): Original position (e.g., `NoRight`)
- **Depth 1** (exception): Opposite position (e.g., `Right`)
- **Depth 2** (exception to exception): Back to original (e.g., `NoRight`)
- **Depth 3** (exception to exception to exception): Opposite again (e.g., `Right`)

This is handled automatically by the constructor using `O(parent.Hohfeld)`.

## Validation

Exception validation is performed in `src/julia/parser/exception_validation.jl`:

1. **Parent exists** - Exception references valid parent norm
2. **Depth correct** - `depth = parent.depth + 1`
3. **Position correct** - Position is opposite of parent (for odd depths)
4. **Same relationship** - Actor/action/object/counterparty match parent
5. **No circular dependencies** - Exception cannot except itself

## Benefits

1. **No expansion step** - Norms created correctly from the start
2. **Type safety** - Constructor enforces correct structure
3. **Clear semantics** - Minimal vs full syntax distinction
4. **Validation** - Full syntax validated against parent
5. **Maintainability** - Single source of truth for exception creation
6. **Performance** - No post-processing required

## Testing

Tests are located in `test/parser/test_exception_constructor.jl`:

- ✅ Minimal exception constructor
- ✅ Field inheritance
- ✅ Auto-computed position
- ✅ Depth propagation
- ✅ Multi-level exceptions
- ✅ Relationship functions

All tests pass successfully.

## Usage in Parser

The parser automatically detects exception syntax and uses the appropriate method:

```julia
# Parser detects "exception de #parent-ref"
if exception_match !== nothing
    parent_norm = find_norm_by_ref(norms, parent_ref)
    
    if has_full_syntax
        # Validate and create with explicit fields
        return parse_full_exception(...)
    else
        # Use constructor for minimal syntax
        return Norm(parent_norm, ref_id, text=norm_text)
    end
end
```

## Future Enhancements

1. **Condition parsing** - Parse and store `lorsque` conditions
2. **Taxonomy resolution** - Resolve taxon references during parsing
3. **Cross-package exceptions** - Support exceptions across package boundaries
4. **Exception chains** - Visualize exception chains in output

## References

- Hohfeldian positions: `src/julia/structures/Hohfeldian.jl`
- Norm structure: `src/julia/structures/IntermediateRepresentation.jl`
- Parser: `src/julia/parser/norms.jl`
- Validation: `src/julia/parser/exception_validation.jl`
- Tests: `test/parser/test_exception_constructor.jl`