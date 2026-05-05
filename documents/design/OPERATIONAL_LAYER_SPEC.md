# OpenNorm Operational Layer — Complete Specification
## Layer 2: Procedures and Computation

**Status:** Specification  
**Date:** 2026-05-04  
**Purpose:** Define the operational layer that bridges legal norms and executable code

---

## Table of Contents

0. [Three-Layer Architecture](#0-three-layer-architecture)
1. [Core Concepts](#1-core-concepts)
2. [Variable Types](#2-variable-types)
3. [Procedure Structure](#3-procedure-structure)
4. [Arithmetic Expressions](#4-arithmetic-expressions)
5. [Functions](#5-functions)
6. [Case](#6-case)
7. [CumulativeCase](#7-cumulativecase)
8. [Exhaustiveness Checking](#8-exhaustiveness-checking)
9. [Checker Errors](#9-checker-errors)
10. [Verification Framework](#10-verification-framework)
11. [Computation Graph](#11-computation-graph)
12. [Examples from Article 156](#12-examples-from-article-156)

---

## 0. Three-Layer Architecture

### Why Three Layers?

OpenNorm separates legal reasoning into three distinct layers, each with its own audience, verification method, and purpose.

### Layer 1: NORMATIVE (OpenNorm)

**What it is:** Legal norms expressed in Hohfeldian logic  
**Purpose:** Establish rights, duties, powers, and obligations  
**Verification:** SMT solver checks logical consistency  
**Audience:** Lawyers, judges, citizens  
**Nature:** Declarative truth statements  

**Example:**
```markdown
*FoyerFiscal* **a le droit de** *déduire* les *frais professionnels*
à *AdministrationFiscale* {#art156-II}
```

### Layer 2: OPERATIONAL (Procedures)

**What it is:** Pure computational procedures that implement norms  
**Purpose:** Define HOW to calculate the values referenced by norms  
**Verification:** Type checking, exhaustiveness checking, graph analysis  
**Audience:** Tax administrators, software specifiers, implementers  
**Nature:** Mathematical expressions and conditional logic  
**French term:** "Modalités d'application"  

**Example:**
```markdown
## *DéductionFraisProfessionnels*

Applies: #art156-II

Constants:
- *PlafondDéduction* = 13 522 EUR

Case:
  - *ModeDéduction* = *FraisRéels*:    *MontantFraisRéels*
  - *ModeDéduction* = *Forfaitaire*:   min(*RevenuBrutSalarial* × 10%, *PlafondDéduction*)
  - Default: 0 EUR
```

### Layer 3: EXECUTABLE (Generated Code)

**What it is:** Executable code in target language (Python, Julia, Solidity, etc.)  
**Purpose:** Execute the calculation  
**Verification:** Unit tests, integration tests  
**Audience:** Machines only  
**Nature:** Mechanical compilation artifact  

**Example:**
```python
class DéductionFraisProfessionnels(Variable):
    value_type = float
    entity = FoyerFiscal
    definition_period = YEAR
    reference = "CGI Art 156 II"
    
    def formula(foyer, period, parameters):
        mode = foyer('ModeDéduction', period)
        if mode == Mode.FRAIS_REELS:
            return foyer('MontantFraisRéels', period)
        elif mode == Mode.FORFAITAIRE:
            revenu = foyer('RevenuBrutSalarial', period)
            plafond = parameters(period).PlafondDéduction
            return min(revenu * 0.10, plafond)
        return 0
```

### Separation of Concerns

| Layer | What | How | Verified By |
|-------|------|-----|-------------|
| 1. Normative | Legal truth | Hohfeldian logic | SMT solver |
| 2. Operational | Computation | Mathematical expressions | Type checker, exhaustiveness |
| 3. Executable | Execution | Programming language | Unit tests |

---

## 1. Core Concepts

A procedure defines exactly one **computed variable**. It receives inputs and returns a scalar value. It knows nothing about the norms that reference it — the IR resolves that connection at compile time through the taxonomy.

### Three Invariants

1. **One procedure → one output variable**
2. **Each computed variable has at most one defining procedure**
3. **All variables referenced in expressions must exist in the taxonomy**

### Norm-Procedure Linkage

While procedures are pure compute nodes, they maintain traceability to their legal basis through the optional `Applies:` metadata field. This enables:

- **Audit trails** - trace from code back to law
- **Change impact analysis** - identify affected procedures when norms change
- **Documentation generation** - automatic legal basis reports
- **Verification** - check entity alignment, temporal constraints

---

## 2. Variable Taxonomy

All variables are declared in the **OpenNormVariables taxonomy**. The taxonomy is the single source of truth for variable types, domains, and defaults. Procedures reference these variables but do not declare them.

### 2.1 Taxonomy Structure

```markdown
## OpenNormVariables

### Constants
- *PlafondDéduction* = 13 522 EUR
  revised-by: *BarèmePremièreTranche*
- *TauxForfaitaire* = 10%
- *PériodeReport* = 6 Années

### Parameters
- *ModeDéduction* (*FraisRéels*, *Forfaitaire*) Default *Forfaitaire*
- *RevenuBrutSalarial* (required)
- *StatutProfessionnel* (*Salarié*, *Indépendant*, *Agricole*)

### ComputedVariables
- *MontantDéductionFrais*
- *RevenuImposable*
- *QuotientFamilial*
```

### 2.2 Constants

**Definition:** Fixed values defined by law. Do not vary per entity or per period.

**Syntax:**
```markdown
- *ConstantName* = value Unit
  revised-by: *RevisionParameter* (optional)
```

**Properties:**
- Declared once in taxonomy with their value
- Cannot be reassigned in procedures
- Become parameters in generated code
- Must have consistent value across entire document

**Checker behavior:**
- **E028**: Same constant name with different values
- **E041**: Assignment to constant in procedure

**Example:**
```markdown
### Constants
- *PlafondDéduction* = 13 522 EUR
  revised-by: *BarèmePremièreTranche*
- *TauxForfaitaire* = 10%
```

### 2.3 Parameters

**Definition:** Variables that depend on the entity or period — inputs provided by the execution context.

**Syntax:**
```markdown
- *ParameterName* (*EnumValue1*, *EnumValue2*, ...) Default *DefaultValue*
- *ParameterName* (required)
- *ParameterName*
```

**Three forms:**

1. **Enum with default:**
   ```markdown
   - *ModeDéduction* (*FraisRéels*, *Forfaitaire*) Default *Forfaitaire*
   ```
   - Declares valid enum values
   - Specifies default if not provided
   - Optional input

2. **Required parameter:**
   ```markdown
   - *RevenuBrutSalarial* (required)
   ```
   - Must be provided by execution context
   - Compilation fails if absent
   - No default value

3. **Optional parameter:**
   ```markdown
   - *NombreEnfants*
   ```
   - May be provided by execution context
   - No enum constraint, no default
   - Treated as optional

**Properties:**
- Enum domain declared once in taxonomy
- All procedures branching on this parameter inherit the same exhaustiveness domain
- Default is a legal declaration, not a procedural choice
- Required parameters enforce input contract at compile time

**Checker behavior:**
- **E034**: Case branches missing enum values (checked against taxonomy domain)
- **E042**: Variable used in procedure not declared in taxonomy
- **E043**: Enum value used not in taxonomy domain
- **E044**: Required parameter not provided by execution context

**Example:**
```markdown
### Parameters
- *ModeDéduction* (*FraisRéels*, *Forfaitaire*) Default *Forfaitaire*
- *RevenuBrutSalarial* (required)
- *StatutProfessionnel* (*Salarié*, *Indépendant*, *Agricole*)
- *NombreEnfants*
```

### 2.4 Computed Variables

**Definition:** Output variables produced by procedures. Each computed variable has exactly one defining procedure.

**Syntax:**
```markdown
- *ComputedVariableName*
```

**Properties:**
- Listed in taxonomy without definition
- Defined by exactly one procedure (procedure heading matches variable name)
- Can be referenced by other procedures as inputs
- Cannot be used as branching variable in Case

**Checker behavior:**
- **E027**: Two procedures declare the same computed variable
- **E031**: Computed variable used as branching variable in Case
- **W012**: Computed variable not referenced by any norm or procedure

**Example:**
```markdown
### ComputedVariables
- *MontantDéductionFrais*
- *RevenuImposable*
- *QuotientFamilial*
```

### 2.5 Variable Classification Rules

The taxonomy position determines the variable's role:

| Taxonomy Section | Role | Can Assign | Can Branch | Can Reference |
|-----------------|------|------------|------------|---------------|
| Constants | Fixed value | ❌ No | ✅ Yes | ✅ Yes |
| Parameters | Input | ❌ No | ✅ Yes | ✅ Yes |
| ComputedVariables | Output | ✅ Yes (once) | ❌ No | ✅ Yes |

**Key insight:** The checker doesn't infer variable types from usage — the taxonomy declares them explicitly.

---

## 3. Procedure Structure

### 3.1 Minimal Procedure

The `##` heading declares a procedure. The `*italics*` wrapping identifies a taxonomy variable. The heading must match a ComputedVariable declared in the OpenNormVariables taxonomy.

```markdown
## *MontantFraisRéels*

> Calcul du montant des frais réels documentés

*MontantFraisRéels* = *FraisDocumentés*
```

**Key points:**
- Procedure heading declares which ComputedVariable it produces
- Variable must exist in OpenNormVariables/ComputedVariables taxonomy
- Optional free text description using `>` quotes
- No Constants block needed (constants are in taxonomy)

### 3.2 Simplified Structure

With taxonomy-based variables, procedures are much simpler:

```markdown
## *OutputVariable*

> Free text description (optional)

Case:
  - condition: expression
  - condition: expression
  - Default: expression
```

**What's removed:**
- ❌ No `Constants:` block (constants declared in taxonomy)
- ❌ No `Applies:` field (name resolution handles linkage)
- ❌ No enum declarations (enums declared in taxonomy)

**What remains:**
- ✅ Procedure heading (matches ComputedVariable)
- ✅ Free text description with `>` quotes
- ✅ Computational logic (Case, expressions, etc.)

### 3.3 Example: Before and After

**Before (old style with Constants block):**
```markdown
## *DéductionFraisProfessionnels*

Constants:
- *PlafondDéduction* = 13 522 EUR
- *TauxForfaitaire* = 10%

Case:
  - *ModeDéduction* = *FraisRéels*:     *MontantFraisRéels*
  - *ModeDéduction* = *Forfaitaire*:    min(*RevenuBrutSalarial* × *TauxForfaitaire*, *PlafondDéduction*)
  - Default: 0 EUR
```

**After (taxonomy-based):**
```markdown
## *DéductionFraisProfessionnels*

> Calcul de la déduction pour frais professionnels selon le mode choisi

Case:
  - *ModeDéduction* = *FraisRéels*:     *MontantFraisRéels*
  - *ModeDéduction* = *Forfaitaire*:    min(*RevenuBrutSalarial* × *TauxForfaitaire*, *PlafondDéduction*)
```

Note: No Default needed if taxonomy declares `*ModeDéduction*` with exactly two enum values.

### 3.4 Delegation

A procedure can delegate to another ComputedVariable. The IR resolves the reference through the taxonomy.

```markdown
## *MontantDéductionFrais*

> Orchestration du calcul de déduction

Case:
  - *ModeDéduction* = *FraisRéels*:     *MontantFraisRéels*
  - *ModeDéduction* = *Forfaitaire*:    *DéductionForfaitaireSalarié*
```

**Key insight:** Both `*MontantFraisRéels*` and `*DéductionForfaitaireSalarié*` must be declared in OpenNormVariables/ComputedVariables.

---

## 4. Arithmetic Expressions

Standard mathematical notation. Domain terms always in `*italics*`.

```markdown
*A* + *B*
*A* - *B*
*A* × *B*
*A* / *B*
*A* × 10%                          ← percentage as literal
(*A* + *B*) × *C*                  ← parentheses for grouping
```

**Unit checking** is enforced. `EUR × EUR` is checker error **E037**. Units propagate through expressions and are validated at compile time.

---

## 5. Functions

### 5.1 Comparison and Clipping

```markdown
min(*MontantBrut*, *Plafond*)
max(*Déficit*, 0)
```

### 5.2 Summation over Known Arguments

```markdown
sum(*Déduction1*, *Déduction2*, *Déduction3*)
```

### 5.3 Aggregation over a Collection — `per`

When the set is variable-length, use the `per` extension. The collection must be a declared entity type in the taxonomy. The pairing of variable and collection is verified by the checker.

```markdown
sum(*DéductionParEnfant* per *Enfant*)
max(*RevenuParSource* per *Source*)
min(*CotisationParRégime* per *Régime*)
```

### 5.4 Rounding

```markdown
round(*Montant*, 2)        ← nearest, 2 decimal places
round(*Montant*, 0)        ← nearest integer
ceil(*Montant*, 0)         ← up to nearest integer
floor(*Montant*, 0)        ← down to nearest integer
floor(*Montant*, -1)       ← down to nearest ten
```

The second argument is the number of decimal digits. Negative values round to the left of the decimal point.

### 5.5 Complete Function Reference

| Function | Semantics |
|---|---|
| `min(A, B)` | Lesser of two values |
| `max(A, B)` | Greater of two values |
| `sum(A, B, ...)` | Sum of explicit arguments |
| `sum(X per Collection)` | Sum over variable-length collection |
| `max(X per Collection)` | Maximum over variable-length collection |
| `min(X per Collection)` | Minimum over variable-length collection |
| `round(X, n)` | Round to n decimal places |
| `ceil(X, n)` | Round up to n decimal places |
| `floor(X, n)` | Round down to n decimal places |

---

## 6. Case

`Case` is the universal conditional construct. One branch wins and its expression is returned. Branches can test enum equality, numeric comparisons, or compound conditions.

### 6.1 Enum Equality

```markdown
## *MontantDéductionFrais*

Constants:
- *PlafondDéduction* = 13 522 EUR

Case:
  - *ModeDéduction* = *FraisRéels*:       *MontantFraisRéels*
  - *ModeDéduction* = *Forfaitaire*:      min(*RevenuBrutSalarial* × 10%, *PlafondDéduction*)
  - Default: 0 EUR
```

### 6.2 Numeric Comparison

The variable under test appears in each branch condition. Supported operators: `<`, `<=`, `>`, `>=`, `=`.

```markdown
## *TauxApplicable*

Case:
  - *RevenuBrut* < 10 000 EUR:             *TauxRéduit*
  - *RevenuBrut* >= 10 000 EUR AND *RevenuBrut* < 50 000 EUR: *TauxNormal*
  - *RevenuBrut* >= 50 000 EUR:            *TauxMajoré*
```

### 6.3 Compound Conditions — `AND` / `OR`

Multiple conditions in a single branch. No nesting limit.

```markdown
## *BonificationAncienneté*

Case:
  - *StatutProfessionnel* = *Salarié* AND *AnnéesAncienneté* >= 10: *TauxSenior*
  - *StatutProfessionnel* = *Salarié* AND *AnnéesAncienneté* < 10:  *TauxJunior*
  - *StatutProfessionnel* = *Indépendant*:                           0 EUR
  - Default: 0 EUR
```

### 6.4 Multi-line Expressions

When the result expression is long, it may span multiple lines with indentation:

```markdown
## *CotisationSociale*

Case:
  - *StatutProfessionnel* = *Salarié*:
      min(
        *RevenuBrutSalarial* × *TauxCotisation*,
        *PlafondCotisation*
      )
  - *StatutProfessionnel* = *Indépendant*:
      floor(*RevenuNetIndépendant* × *TauxIndépendant*, 0)
  - Default: 0 EUR
```

---

## 7. CumulativeCase

`CumulativeCase` applies when all bands contribute and their results are summed. This is the progressive bracket construct — each rate applies only to its slice of the value, and the results are accumulated.

Semantically distinct from `Case`: `Case` picks one branch, `CumulativeCase` evaluates all applicable bands.

Three hard constraints apply to `CumulativeCase`:

- **Exactly one variable** in the header — slicing a compound condition has no defined semantics → **E039**
- **Numeric variable only** — you cannot progressively bracket an enum → **E040**
- **No compound conditions in branches** — `AND` / `OR` are not permitted inside `CumulativeCase` bands → **E039**

### 7.1 Basic Progressive Bracket

```markdown
## *ImpôtSurLeRevenu*

CumulativeCase *RevenuImposable*:
  - up to 11 294 EUR:                0%
  - from 11 294 EUR to 28 797 EUR:   11%
  - from 28 797 EUR to 82 341 EUR:   30%
  - from 82 341 EUR to 177 106 EUR:  41%
  - above 177 106 EUR:               45%
```

For a `*RevenuImposable*` of 40 000 EUR this computes:

```
(11 294 × 0%)
+ (28 797 - 11 294) × 11%
+ (40 000 - 28 797) × 30%
= 0 + 1 925.33 + 3 360.90
= 5 286.23 EUR
```

### 7.2 Bands with Variable Rates

Band rates can reference taxonomy variables rather than literal percentages:

```markdown
## *CotisationRetraite*

CumulativeCase *SalaireBrut*:
  - up to *PlafondSécuritéSociale*:    *TauxTranche1*
  - above *PlafondSécuritéSociale*:    *TauxTranche2*
```

### 7.3 Key Differences from Case

| | `Case` | `CumulativeCase` |
|---|---|---|
| Tested variables | One or more | Exactly one — **E039** |
| Variable type | Any | Numeric only — **E040** |
| Compound conditions | `AND` / `OR` allowed | Not permitted — **E039** |
| `Default` branch | Allowed | Not permitted — bands must be fully exhaustive |
| Branches evaluated | One wins | All applicable bands |
| Result | Single branch expression | Sum of all band results |
| Typical use | Categorical dispatch | Progressive tax, tiered rates |
| Exhaustiveness check | SMT — all values covered | Bands contiguous, no gaps |

---

## 8. Exhaustiveness Checking

All conditional constructs are verified for exhaustiveness by the SMT solver at compile time. A procedure that does not cover all possible input values does not compile.

### 8.1 Enum Case

All values declared in the taxonomy for the tested variable must appear as branches, or a `Default` branch must be present.

```markdown
Case:
  - *ModeDéduction* = *FraisRéels*:   ...   ← ✓
  - *ModeDéduction* = *Forfaitaire*:  ...   ← ✓
  # No Default needed — taxonomy declares exactly these two values
```

Missing value → **E034**.

### 8.2 Comparison Case

The SMT solver checks that the union of all branch conditions covers the entire domain of the tested variable. Gaps are a compile error.

```markdown
Case:
  - *RevenuBrut* < 50 000 EUR:   ...
  - *RevenuBrut* > 50 000 EUR:   ...
  # Gap: RevenuBrut = exactly 50 000 EUR is uncovered → E035
```

Corrected:

```markdown
Case:
  - *RevenuBrut* < 50 000 EUR:   ...
  - *RevenuBrut* >= 50 000 EUR:  ...
```

Overlapping conditions are also detected — if two branches can be simultaneously true, the checker reports **E038** and requires a priority ordering or a rewrite.

### 8.3 CumulativeCase

Bands must be contiguous from the minimum to the maximum domain of the tested variable, with no gaps and no overlaps. Missing coverage → **E036**.

---

## 9. Checker Errors

### Structural Errors

| Code | Condition |
|---|---|
| E003 | `#procedure-ref` points to non-existent procedure |
| E026 | Circular delegation in computation graph |
| E027 | Two procedures declare the same output variable |
| E028 | Same constant name, different values in taxonomy |
| E029 | Unit not in Units taxonomy |
| E030 | Function not in permitted list |
| E037 | Unit mismatch in expression (e.g. `EUR × EUR`) |
| E041 | Assignment to Constant (constants are immutable) |
| E042 | Variable used in procedure not declared in OpenNormVariables taxonomy |
| E043 | Enum value used not in taxonomy domain for that parameter |
| E044 | Required parameter not provided by execution context |
| E045 | Procedure heading does not match any ComputedVariable in taxonomy |

### Exhaustiveness Errors

| Code | Condition |
|---|---|
| E034 | Enum `Case` missing taxonomy values and no `Default` |
| E035 | Comparison `Case` has gaps in domain coverage |
| E036 | `CumulativeCase` bands are not contiguous |
| E038 | Overlapping conditions in `Case` without explicit priority |
| E039 | `CumulativeCase` header has multiple variables or branch uses `AND` / `OR` |
| E040 | `CumulativeCase` tested variable is not numeric |

### Taxonomy-Based Variable Errors

| Code | Condition |
|---|---|
| E031 | ComputedVariable used as branching variable in `Case` |
| E042 | Variable referenced in procedure not declared in taxonomy |
| E043 | Enum value not in taxonomy domain |
| E044 | Required parameter missing from execution context |
| E045 | Procedure heading doesn't match ComputedVariable |

### Warnings

| Code | Condition |
|---|---|
| W012 | ComputedVariable not referenced by any norm or procedure |
| W013 | Norm references a computable variable with no defining procedure |
| W014 | Variable used in expression not found in taxonomy |
| W015 | Parameter has default but is never used in any procedure |
| W016 | Constant declared in taxonomy but never referenced |

---

## 10. Verification Framework

The operational layer provides **immediate, automated verification** of consistency between norms and their implementation procedures.

### 10.1 Norm-Procedure Consistency Checks

#### Entity Alignment

**Rule:** A procedure's entities must be compatible with the norm's quantifiers.

```markdown
# Norm
*FoyerFiscal* **a le droit de** *déduire* les *frais professionnels*
à *AdministrationFiscale* {#art156-II}

# Procedure (VALID)
## *DéductionFraisProfessionnels*
Applies: #art156-II
Entity: *FoyerFiscal*
...

# Procedure (INVALID - Entity Mismatch)
## *DéductionFraisProfessionnels*
Applies: #art156-II
Entity: *Individual*  ← ERROR: Norm quantifies over *FoyerFiscal*
...
```

#### Temporal Constraint Propagation

**Rule:** A procedure's temporal parameters must respect the norm's temporal constraints.

```markdown
# Norm
*Contribuable* **a le droit de** *reporter* le *DéficitAgricole*
à *AdministrationFiscale* envers *SixAnnées* {#art156-I-1}

# Procedure (VALID)
## *ReportDéficitAgricole*
Applies: #art156-I-1
Constants:
- *DuréeReport* = 6 Années

# Procedure (INVALID - Temporal Mismatch)
## *ReportDéficitAgricole*
Applies: #art156-I-1
Constants:
- *DuréeReport* = 5 Années  ← ERROR: Norm says 6 years
```

#### Orphan Procedure Detection

**Rule:** Every procedure with an `Applies:` field must reference an existing norm.

```markdown
# Procedure (INVALID - Orphan)
## *CalculMystère*
Applies: #art999-Z  ← ERROR: No norm with ID #art999-Z exists
...
```

#### Missing Procedure Warnings (Heuristic)

**Rule:** Norms with computable entities and numerical conditions likely need procedures.

**Heuristic criteria:**
- Norm quantifies over a computable entity
- Norm references numerical quantities
- No procedure exists with `Applies: #this-norm`

→ **W013**: This norm may require an implementation procedure

### 10.2 Named Constant Consistency

#### Parameter Uniqueness

**Rule:** A named parameter must have a single, consistent value across all procedures.

```markdown
# Procedure 1
Constants:
- *PlafondDéduction* = 13 522 EUR

# Procedure 2 (INVALID)
Constants:
- *PlafondDéduction* = 15 000 EUR  ← ERROR: E028
```

#### Type Consistency

**Rule:** A named entity must have consistent type across all uses.

```markdown
# Procedure 1
Constants:
- *SeuilDéficit*: Currency(EUR) = 10 700

# Procedure 2 (INVALID)
Constants:
- *SeuilDéficit*: Integer = 10700  ← ERROR: Type mismatch
```

### 10.3 Audit Trail Capabilities

#### Bidirectional Traceability

**Forward:** From norm to implementation
```
#art156-II (norm)
  → *DéductionFraisProfessionnels* (procedure)
    → DéductionFraisProfessionnels (OpenFisca variable)
      → def formula(...): ...
```

**Backward:** From code to legal basis
```
Why does this formula exist?
  ← DéductionFraisProfessionnels implements procedure
    ← Procedure applies #art156-II
      ← #art156-II is Article 156 II of CGI
```

#### Change Impact Analysis

When a norm changes, identify affected procedures and code:

```
Norm #art156-II modified: temporal constraint changed

Impact:
  - Procedure *ReportDéficit* (MUST UPDATE)
  - OpenFisca variable DeficitCarryforward (MUST REGENERATE)
  - 12 test cases (MUST REVIEW)
```

---

## 11. Computation Graph

### 11.1 Graph Structure

Procedures form a **Directed Acyclic Graph (DAG)**:
- **Nodes** = Procedures
- **Edges** = Dependencies (via delegation)
- **Leaves** = Procedures that compute directly
- **Internal nodes** = Procedures that orchestrate sub-procedures

### 11.2 Example Graph

```
*RevenuImposable*
    ├─ *DéductionFraisProfessionnels*
    │   ├─ *DéductionForfaitaire* (leaf)
    │   └─ *FraisRéels* (leaf)
    ├─ *DéductionDéficits*
    │   ├─ *DéficitAgricole* (leaf)
    │   └─ *DéficitBIC* (leaf)
    └─ *DéficitFoncier* (leaf)
```

### 11.3 Graph Properties

1. **Acyclic**: No circular dependencies (checked by E026)
2. **Composable**: Procedures can be reused in multiple contexts
3. **Testable**: Each node can be tested independently
4. **Traceable**: Clear path from top-level to leaves
5. **Visualizable**: Can generate dependency diagrams

### 11.4 Verification

- **E026**: Circular delegation detected
- **E003**: Reference to non-existent procedure
- **W012**: Procedure output not referenced (dead code)

---

## 12. Examples from Article 156

### Taxonomy Declaration (Once per Document)

```markdown
## OpenNormVariables

### Constants
- *TauxDéduction* = 10%
- *PlafondDéduction* = 13 522 EUR
  revised-by: *BarèmePremièreTranche*
- *SeuilRevenuAutres* = 127 677 EUR
  revised-by: *BarèmePremièreTranche*
- *DuréeReport* = 6 Années

### Parameters
- *ModeDéduction* (*FraisRéels*, *Forfaitaire*) Default *Forfaitaire*
- *RevenuBrutSalarial* (required)
- *RevenuAutresSources* (required)
- *RevenuBrut* (required)
- *DéficitAgricoleAnnéePrécédente*
- *BénéficeAgricoleAnnéeCourante*

### ComputedVariables
- *DéductionForfaitaireSalarié*
- *MontantFraisRéels*
- *DéductionFraisProfessionnels*
- *ReportDéficitAgricole*
- *RevenuImposable*
- *ImpôtSurLeRevenu*
- *DéductionDéficits*
- *DéficitFoncierDéductible*
```

### Example 1: Simple Leaf Procedure

```markdown
## *DéductionForfaitaireSalarié*

> Calcul de la déduction forfaitaire pour salariés (10% du revenu brut)

*DéductionForfaitaireSalarié* = min(*RevenuBrutSalarial* × *TauxDéduction*, *PlafondDéduction*)
```

**Note:** No Constants block needed — `*TauxDéduction*` and `*PlafondDéduction*` are declared in taxonomy.

### Example 2: Branching Orchestrator

```markdown
## *DéductionFraisProfessionnels*

> Calcul de la déduction pour frais professionnels selon le mode choisi

Case:
  - *ModeDéduction* = *FraisRéels*:     *MontantFraisRéels*
  - *ModeDéduction* = *Forfaitaire*:    *DéductionForfaitaireSalarié*
```

**Note:** No Default needed — taxonomy declares `*ModeDéduction*` with exactly two enum values.

### Example 3: Progressive Tax Bracket

```markdown
## *ImpôtSurLeRevenu*

> Calcul de l'impôt sur le revenu par tranches progressives

CumulativeCase *RevenuImposable*:
  - up to 11 294 EUR:                0%
  - from 11 294 EUR to 28 797 EUR:   11%
  - from 28 797 EUR to 82 341 EUR:   30%
  - from 82 341 EUR to 177 106 EUR:  41%
  - above 177 106 EUR:               45%
```

**Note:** `*RevenuImposable*` must be declared in ComputedVariables taxonomy.

### Example 4: Deficit Carryforward with Temporal Constraint

```markdown
## *ReportDéficitAgricole*

> Report du déficit agricole sur les bénéfices agricoles des années suivantes
> Limité par le seuil de revenus autres sources

Case:
  - *RevenuAutresSources* > *SeuilRevenuAutres*:
      0 EUR
  - Default:
      min(
        *DéficitAgricoleAnnéePrécédente*,
        *BénéficeAgricoleAnnéeCourante*
      )
```

**Note:** `*SeuilRevenuAutres*` and `*DuréeReport*` are declared in Constants taxonomy.

### Example 5: Multi-Level Orchestration

```markdown
## *RevenuImposable*

> Calcul du revenu imposable après toutes déductions

*RevenuImposable* = *RevenuBrut* 
                    - *DéductionFraisProfessionnels*
                    - *DéductionDéficits*
                    - *DéficitFoncierDéductible*
```

**Note:** All referenced variables must be declared in taxonomy (either as Parameters or ComputedVariables).

### Key Differences from Old Style

| Aspect | Old Style | New Taxonomy-Based Style |
|--------|-----------|-------------------------|
| Constants | Declared in each procedure | Declared once in taxonomy |
| Enums | Scattered across procedures | Declared once in taxonomy |
| Defaults | Repeated in procedures | Declared once in taxonomy |
| Exhaustiveness | Checked per procedure | Checked against taxonomy domain |
| Type checking | Inferred from usage | Explicit in taxonomy |
| Procedure size | Larger (includes declarations) | Smaller (pure logic) |
| Consistency | Manual checking needed | Automatic from taxonomy |

---

## Summary

This specification defines the **operational layer** of OpenNorm:

✅ **Pure computational syntax** - procedures as mathematical expressions  
✅ **Legal traceability** - `Applies:` links to norms for audit trails  
✅ **Exhaustiveness checking** - SMT-verified completeness  
✅ **Type safety** - unit checking, parameter consistency  
✅ **Computation graphs** - DAG structure, dependency tracking  
✅ **Verification framework** - entity alignment, temporal constraints  

The operational layer bridges the gap between:
- **Legal norms** (what is legally true)
- **Executable code** (what machines can run)

By maintaining both computational rigor and legal traceability.