# Norms vs Procedures: Architectural Distinction

## Core Principle

**Norms are ALWAYS bilateral relationships between two Roles.**

This is a fundamental architectural constraint in OpenNorm that ensures clear separation between:
- **Legal relationships** (Norms)
- **Computational processes** (Procedures)

## The Bilateral Constraint

### What is a Norm?

A **Norm** represents a legal relationship between two parties (Roles). It describes rights, duties, powers, or liabilities that one party has with respect to another.

**Structure:**
```
*Actor* **Hohfeldian-Position** *action* *object* envers *Counterparty*
```

**Requirements:**
- ✅ Actor must be a Role (non-empty)
- ✅ Counterparty must be a Role (non-empty)
- ✅ Both parties must be explicitly specified

### What is a Procedure?

A **Procedure** represents a computational process or calculation. It describes how to compute a value or transform data.

**Structure:**
```julia
OutputVariable = expression
```

**Characteristics:**
- ❌ No counterparty needed
- ✅ Pure calculation/transformation
- ✅ Can involve any Objects
- ✅ No Hohfeldian positions

## Examples

### ✅ Correct: Bilateral Norm

```markdown
### Obligation de Déclaration

*Propriétaire* **a le devoir de** *déclarer* le *RevenuFoncier* envers *AdministrationFiscale*
{#art156-obligation-declaration}
```

**Why this is a Norm:**
- Actor: Propriétaire (Role)
- Counterparty: AdministrationFiscale (Role)
- Describes a legal obligation between two parties

### ❌ Incorrect: Unilateral "Norm"

```markdown
### Imputation du Déficit (WRONG!)

*Propriétaire* **a le droit de** *imputer* le *DéficitFoncier* envers *RevenuFoncier*
{#art156-imputation-foncier}
```

**Why this is WRONG:**
- RevenuFoncier is an Object, not a Role
- This describes a calculation, not a legal relationship
- No actual counterparty (another party)

### ❌ Incorrect: Multiple Prepositions (Malformed Syntax)

```markdown
### Imputation du Déficit (WRONG!)

*Propriétaire* **a le droit de** *imputer* le *DéficitFoncier* à *AdministrationFiscale* envers *RevenuFoncier*
{#art156-imputation-foncier}
```

**Why this is WRONG:**
- Contains multiple prepositions: "à" and "envers"
- Ambiguous counterparty - which one is it?
- Mixing a legal relationship with a calculation
- **Parser will reject this with an error**

**Error message:**
```
Malformed norm syntax in 'art156-imputation-foncier':
Found multiple prepositions: 'à', 'envers'
A norm must have exactly one counterparty.

This appears to be mixing a legal relationship with a calculation.
Consider splitting into:
1. A Norm (bilateral relationship between two Roles)
2. A Procedure (calculation in the Procedures section)
```

### ✅ Correct: Procedure Instead

```markdown
## Procedures

### Calcul du Revenu Foncier Net

> Le revenu foncier net est calculé en imputant le déficit foncier au revenu foncier brut

```julia
RevenuFoncierNet = RevenuFoncierBrut - DéficitFoncierImputable
```
```

**Why this is correct:**
- Describes a calculation process
- No counterparty needed
- Pure computational logic

## Common Patterns

### Pattern 1: Obligation + Calculation

When you have both a legal obligation AND a calculation:

**Norm (bilateral relationship):**
```markdown
*Propriétaire* **a le devoir de** *calculer* le *RevenuFoncierNet* envers *AdministrationFiscale*
```

**Procedure (how to calculate):**
```julia
RevenuFoncierNet = RevenuFoncierBrut - DéficitFoncierImputable
```

### Pattern 2: Right + Process

When you have a right to perform a process:

**Norm (bilateral relationship):**
```markdown
*Propriétaire* **a le droit de** *déduire* les *ChargesDéductibles* envers *AdministrationFiscale*
```

**Procedure (what can be deducted):**
```julia
ChargesDéductibles = sum([
    FraisGestion,
    PrimesAssurance,
    TravailEntretien,
    # ...
])
```

### Pattern 3: Three-Party Relationships

When you have three parties involved, use correlative norms:

**Primary norm (actor's right):**
```markdown
*Propriétaire* **a le droit de** *reporter* le *DéficitFoncier* envers *AdministrationFiscale*
{#art156-droit-report}
```

**Correlative norm (counterparty's duty):**
```markdown
*AdministrationFiscale* **a le devoir de** *reconnaître* le *report du DéficitFoncier* envers *Propriétaire*
{#art156-devoir-reconnaissance}
```

## Validation

The system enforces the bilateral constraint through validation:

```julia
function validate_bilateral_norm(norm::Norm)
    if isempty(norm.actor.name)
        error("Actor cannot be empty. Norms must be bilateral relationships.")
    end
    
    if isempty(norm.counterparty.name)
        error("Counterparty cannot be empty. " *
              "If describing a calculation, use a Procedure instead.")
    end
end
```

### Error Messages

When you try to create a unilateral "norm":

```
Error: Norm 'art156-imputation-foncier': Counterparty cannot be empty.
Norms must be bilateral relationships between two Roles.
A norm describes a legal relationship between an actor and a counterparty.
If you're describing a calculation or process (e.g., 'imputer X envers Y'),
this should be modeled as a Procedure in the Procedures section, not as a Norm.
```

## Decision Tree

When modeling a legal/tax rule, ask:

1. **Does this involve two parties (Roles)?**
   - YES → It's a Norm
   - NO → Go to question 2

2. **Is this a calculation or process?**
   - YES → It's a Procedure
   - NO → Go to question 3

3. **Does this describe HOW to do something?**
   - YES → It's a Procedure
   - NO → It's probably a Norm (check question 1 again)

## Benefits of This Distinction

### 1. Conceptual Clarity
- Clear separation between legal relationships and computations
- Easier to understand and maintain
- Self-documenting code structure

### 2. Type Safety
- Prevents misuse of norm structure
- Compile-time guarantees
- Better error messages

### 3. Code Generation
- Norms generate bilateral checks/validations
- Procedures generate computational code
- Different optimization strategies

### 4. Verification
- Can verify legal relationships separately from calculations
- Can check for missing correlatives
- Can detect contradictions in legal relationships

## Summary

| Aspect | Norms | Procedures |
|--------|-------|------------|
| **Purpose** | Legal relationships | Calculations |
| **Parties** | Two Roles (bilateral) | No counterparty |
| **Structure** | Actor-Action-Object-Counterparty | Variable = Expression |
| **Hohfeldian** | Yes (Right, Duty, etc.) | No |
| **Example** | "Owner must declare income to Tax Authority" | "Net Income = Gross - Deductions" |
| **Layer** | Normative (Layer 1) | Operational (Layer 2) |

## References

- Norm structure: `src/julia/structures/IntermediateRepresentation.jl`
- Validation: `src/julia/parser/validation.jl`
- Parser: `src/julia/parser/norms.jl`
- Procedures: `src/julia/parser/procedures.jl`
- Tests: `test/parser/test_bilateral_constraint.jl`