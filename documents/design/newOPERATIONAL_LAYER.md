# OpenNorm — Procedure Syntax Reference
## Operational Layer (Layer 2)

> This document specifies the syntax for writing procedures in the OpenNorm
> operational layer. Procedures are pure compute nodes: they take inputs and
> produce exactly one output variable. They have no normative awareness.

---

## Table of Contents

1. [Core Concepts](#1-core-concepts)
2. [Variable Types](#2-variable-types)
3. [Procedure Structure](#3-procedure-structure)
4. [Arithmetic Expressions](#4-arithmetic-expressions)
5. [Functions](#5-functions)
6. [Case](#6-case)
7. [CumulativeCase](#7-cumulativecase)
8. [Exhaustiveness Checking](#8-exhaustiveness-checking)
9. [Checker Errors](#9-checker-errors)

---

## 1. Core Concepts

A procedure defines exactly one **computed variable**. It receives inputs and
returns a scalar value. It knows nothing about the norms that reference it —
the IR resolves that connection at compile time through the taxonomy.

Three invariants always hold:

- One procedure → one output variable
- Each computed variable has at most one defining procedure
- All variables referenced in expressions must exist in the taxonomy

---

## 2. Variable Types

Three kinds of variables appear in procedures. The distinction matters for
code generation and consistency checking.

### 2.1 Constants

Fixed values defined by law. Do not vary per entity or per period. Declared
in the `Constants:` block. Become parameters in generated code.

```markdown
Constants:
- *PlafondDéduction* = 13 522 EUR
- *TauxForfaitaire* = 10%
- *PériodeReport* = 6 Années
```

A constant declared in multiple procedures must have the same value
everywhere. Conflict is checker error **E028**.

Constants that change over time carry a `revised-by:` annotation:

```markdown
Constants:
- *PlafondDéduction* = 13 522 EUR
  revised-by: *BarèmePremièreTranche*
```

### 2.2 Parameters

Variables that depend on the entity or period — the taxpayer's income, the
household's status. Not declared explicitly. The parser infers them from what
appears in expressions and is not a constant or computed variable.

If a parameter does not exist in the taxonomy, **the document does not
compile**.

```markdown
*RevenuBrutSalarial*    ← inferred parameter
*ModeDéduction*         ← inferred parameter
*StatutProfessionnel*   ← inferred parameter
```

### 2.3 Computed Variables

Output variables produced by procedures. Named as the section heading of
their defining procedure. Referenced by other procedures as inputs.

```markdown
*MontantDéductionFrais*    ← produced by a procedure
*RevenuImposable*           ← produced by a procedure
*QuotientFamilial*          ← produced by a procedure
```

---

## 3. Procedure Structure

### 3.1 Minimal Procedure

The `##` heading declares a procedure. The `*italics*` wrapping identifies a
taxonomy variable. The heading is the only required element.

```markdown
## *MontantFraisRéels*

*MontantFraisRéels* = *FraisDocumentés*
```

### 3.2 Full Structure

```markdown
## *OutputVariable*

Constants:
- *ConstantName* = value Unit

Case:
  - condition: expression
  - condition: expression
  - Default: expression
```

### 3.3 Delegation

A procedure can delegate to another procedure's output variable using `#ref`.
The IR resolves the reference through the taxonomy.

```markdown
## *MontantDéductionFrais*

Case:
  - *ModeDéduction* = *FraisRéels*:        #art83-frais-reels-proc
  - *ModeDéduction* = *Forfaitaire*:        min(*RevenuBrutSalarial* × 10%, *PlafondDéduction*)
  - Default: 0 EUR
```

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

**Unit checking** is enforced. `EUR × EUR` is checker error **E037**. Units
propagate through expressions and are validated at compile time.

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

When the set is variable-length, use the `per` extension. The collection must
be a declared entity type in the taxonomy. The pairing of variable and
collection is verified by the checker.

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

The second argument is the number of decimal digits. Negative values round
to the left of the decimal point.

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

`Case` is the universal conditional construct. One branch wins and its
expression is returned. Branches can test enum equality, numeric comparisons,
or compound conditions.

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

The variable under test appears in each branch condition. Supported operators:
`<`, `<=`, `>`, `>=`, `=`.

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

When the result expression is long, it may span multiple lines with
indentation:

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

`CumulativeCase` applies when all bands contribute and their results are
summed. This is the progressive bracket construct — each rate applies only to
its slice of the value, and the results are accumulated.

Semantically distinct from `Case`: `Case` picks one branch, `CumulativeCase`
evaluates all applicable bands.

Three hard constraints apply to `CumulativeCase`:

- **Exactly one variable** in the header — slicing a compound condition has
  no defined semantics → **E039**
- **Numeric variable only** — you cannot progressively bracket an enum → **E040**
- **No compound conditions in branches** — `AND` / `OR` are not permitted
  inside `CumulativeCase` bands → **E039**

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

All conditional constructs are verified for exhaustiveness by the SMT solver
at compile time. A procedure that does not cover all possible input values
does not compile.

### 8.1 Enum Case

All values declared in the taxonomy for the tested variable must appear as
branches, or a `Default` branch must be present.

```markdown
Case:
  - *ModeDéduction* = *FraisRéels*:   ...   ← ✓
  - *ModeDéduction* = *Forfaitaire*:  ...   ← ✓
  # No Default needed — taxonomy declares exactly these two values
```

Missing value → **E034**.

### 8.2 Comparison Case

The SMT solver checks that the union of all branch conditions covers the
entire domain of the tested variable. Gaps are a compile error.

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

Overlapping conditions are also detected — if two branches can be
simultaneously true, the checker reports **E038** and requires a priority
ordering or a rewrite.

### 8.3 CumulativeCase

Bands must be contiguous from the minimum to the maximum domain of the
tested variable, with no gaps and no overlaps. Missing coverage → **E036**.

---

## 9. Checker Errors

### Structural Errors

| Code | Condition |
|---|---|
| E003 | `#procedure-ref` points to non-existent procedure |
| E026 | Circular delegation in computation graph |
| E027 | Two procedures declare the same output variable |
| E028 | Same constant name, different values across procedures |
| E029 | Unit not in Units taxonomy |
| E030 | Function not in permitted list |
| E037 | Unit mismatch in expression (e.g. `EUR × EUR`) |

### Exhaustiveness Errors

| Code | Condition |
|---|---|
| E034 | Enum `Case` missing taxonomy values and no `Default` |
| E035 | Comparison `Case` has gaps in domain coverage |
| E036 | `CumulativeCase` bands are not contiguous |
| E038 | Overlapping conditions in `Case` without explicit priority |
| E039 | `CumulativeCase` header has multiple variables or branch uses `AND` / `OR` |
| E040 | `CumulativeCase` tested variable is not numeric |

### Warnings

| Code | Condition |
|---|---|
| W012 | Procedure output not referenced by any norm |
| W013 | Norm references a computable variable with no defining procedure |
| W014 | Variable used in expression not found in taxonomy |