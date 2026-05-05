# OpenNorm Operational Layer - Design Document

**Status:** Draft  
**Date:** 2026-04-28  
**Purpose:** Define the intermediate layer between normative statements and executable code

---

## Table of Contents

1. [Three-Layer Architecture](#three-layer-architecture)
2. [The Operational Layer](#the-operational-layer)
3. [Procedure Syntax](#procedure-syntax)
4. [Step Types](#step-types)
5. [Computation Graph](#computation-graph)
6. [Examples from Article 156](#examples-from-article-156)
7. [Open Questions](#open-questions)
8. [Implementation Plan](#implementation-plan)

---

## Three-Layer Architecture

### Layer 1: NORMATIVE (OpenNorm)
**What it is:** Legal norms expressed in Hohfeldian logic  
**Purpose:** Establish rights, duties, powers, and obligations  
**Verification:** SMT solver checks logical consistency  
**Audience:** Lawyers, judges, citizens  
**Nature:** Declarative truth statements  
**Example:**
```markdown
The *Taxpayer* **has the right to** *deduct* *professional expenses* 
to *Tax Authority* when *Taxpayer* has *professional activity*
```

### Layer 2: OPERATIONAL (Application Procedures)
**What it is:** Step-by-step procedures for applying norms  
**Purpose:** Describe HOW to exercise the right established by the norm  
**Verification:** Type checking, parameter validation, graph analysis  
**Audience:** Tax administrators, software specifiers, implementers  
**Nature:** Procedural instructions in legal language  
**French term:** "Modalités d'application"  
**Example:**
```markdown
## Procedure: Professional expense deduction {#expense-deduction}

**Applies:** #art156-II
**Entity:** *TaxHousehold*
**Period:** *Year*
**Result:** *ProfessionalExpenseDeduction*

**Steps:**
1. Obtain *ProfessionalStatus* of *Taxpayer*
2. **If** *ProfessionalStatus* = *Employee*
   → Calculate via #standard-deduction-employee
3. **If** *ProfessionalStatus* = *SelfEmployed*
   → Calculate via #actual-expenses-self-employed
4. **Otherwise**
   → *ProfessionalExpenseDeduction* = 0
```

### Layer 3: EXECUTABLE (Generated Code)
**What it is:** Executable code in target language (Python, Julia, Solidity, etc.)  
**Purpose:** Execute the calculation  
**Verification:** Unit tests, integration tests  
**Audience:** Machines only  
**Nature:** Mechanical compilation artifact  
**Example:**
```python
class ProfessionalExpenseDeduction(Variable):
    value_type = float
    entity = TaxHousehold
    definition_period = YEAR
    reference = "Tax Code Art 156 II"
    
    def formula(household, period, parameters):
        status = household('ProfessionalStatus', period)
        return select(
            [status == Status.EMPLOYEE, status == Status.SELF_EMPLOYED],
            [household('StandardDeductionEmployee', period),
             household('ActualExpensesSelfEmployed', period)],
            default=0
        )
```

---

## The Operational Layer

### Key Insight

> "The operational layer uses the same *terms* and **keywords** conventions as OpenNorm but introduces new block types for procedures."

### Why This Layer Exists

1. **Legal text is not executable** - Norms establish rights but don't describe calculations
2. **Code is not legal text** - Python/Julia is unreadable to lawyers
3. **Need an intermediate representation** - Readable by lawyers, parseable by machines
4. **Separation of concerns**:
   - Layer 1: What is legally true (verified by SMT)
   - Layer 2: How to apply it (verified by type checking)
   - Layer 3: How to execute it (verified by tests)

### Design Principles

1. **Reads like law, not like code**
   - Natural language steps: "Obtain", "Calculate", "Verify"
   - Domain terms in *italics*: `*GrossIncome*`, `*TaxHousehold*`
   - Legal phrasing: "Verify that" not "if", "Apply ceiling" not "min()"

2. **Mechanically parseable**
   - Structured blocks with clear delimiters
   - Consistent syntax for references
   - Typed entities and results

3. **Composable through graphs**
   - Procedures can reference other procedures
   - Creates a computation DAG (Directed Acyclic Graph)
   - Enables reuse and modularity

4. **Traceable to norms**
   - `**Applies:** #norm-ref` links procedure to its legal basis
   - Maintains chain of custody from law to code

---

## Procedure Syntax

### Basic Structure

```markdown
## Procedure: <Name> {#unique-id}

**Applies:** #norm-reference
**Entity:** *EntityType*
**Period:** *TimePeriod*
**Result:** *OutputVariable*

**Steps:**
1. <Step description>
2. <Step description>
...

**Parameters:**
- *ParameterName* = value (description)
- *AnotherParameter* = value
```

### Metadata Fields

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `**Applies:**` | Yes | Reference to the norm this procedure implements | `#art156-II` |
| `**Entity:**` | Yes | The entity this procedure operates on | `*TaxHousehold*`, `*Individual*` |
| `**Period:**` | Yes | Time period for the calculation | `*Year*`, `*Month*`, `*Day*` |
| `**Result:**` | Yes | The output variable name | `*TaxableIncome*` |
| `**Parameters:**` | No | Named constants used in the procedure | `*DeductionRate* = 10%` |

### Step Numbering

- Steps are numbered sequentially: `1.`, `2.`, `3.`, etc.
- Conditional branches use the same number with arrows:
  ```markdown
  2. **If** condition
     → action
  3. **If** other condition
     → action
  4. **Otherwise**
     → default action
  ```

---

## Step Types

### 1. Retrieval Step
**Purpose:** Get a value from an entity or context  
**Syntax:** `Obtain *Variable* of *Entity*`  
**Example:**
```markdown
1. Obtain *GrossIncome* of *TaxHousehold*
```

### 2. Computation Step
**Purpose:** Perform a calculation  
**Syntax:** `Calculate *Result* = <expression>`  
**Example:**
```markdown
2. Calculate *RawDeduction* = *GrossIncome* × *DeductionRate*
3. Calculate *FinalAmount* = min(*RawDeduction*, *Ceiling*)
```

### 3. Delegation Step
**Purpose:** Call another procedure  
**Syntax:** `Calculate via #procedure-ref`  
**Example:**
```markdown
2. **If** *Status* = *Employee*
   → Calculate via #standard-deduction-employee
```

### 4. Assignment Step
**Purpose:** Set a variable to a specific value  
**Syntax:** `*Variable* = value`  
**Example:**
```markdown
4. **Otherwise**
   → *Deduction* = 0
```

### 5. Verification Step
**Purpose:** Check a condition  
**Syntax:** `Verify that <condition>`  
**Example:**
```markdown
2. Verify that *Documentation* is complete
3. **If** verification succeeds
   → Continue
4. **Otherwise**
   → *Result* = 0
```

### 6. Conditional Step
**Purpose:** Branch based on a condition  
**Syntax:** `**If** <condition> → <action>`  
**Example:**
```markdown
2. **If** *Status* = *Employee*
   → Calculate via #standard-deduction
3. **If** *Status* = *SelfEmployed*
   → Calculate via #actual-expenses
4. **Otherwise**
   → *Deduction* = 0
```

---

## Computation Graph

### Graph Structure

Procedures form a **Directed Acyclic Graph (DAG)**:
- **Nodes** = Procedures
- **Edges** = Dependencies (via delegation steps)
- **Leaves** = Procedures that compute directly
- **Internal nodes** = Procedures that orchestrate sub-procedures

### Example Graph

```
#total-tax-calculation
    ├─ #taxable-income-calculation
    │   ├─ #professional-expense-deduction
    │   │   ├─ #standard-deduction-employee (leaf)
    │   │   └─ #actual-expenses-self-employed (leaf)
    │   ├─ #deficit-deduction
    │   │   ├─ #agricultural-deficit (leaf)
    │   │   └─ #business-deficit (leaf)
    │   └─ #property-deficit (leaf)
    ├─ #tax-bracket-application (leaf)
    └─ #tax-credits-deductions
        ├─ #family-quotient (leaf)
        └─ #specific-credits (leaf)
```

### Graph Properties

1. **Acyclic**: No circular dependencies
2. **Composable**: Procedures can be reused in multiple contexts
3. **Testable**: Each node can be tested independently
4. **Traceable**: Clear path from top-level to leaves
5. **Visualizable**: Can generate dependency diagrams

---

## Verification and Validation

### Overview

The operational layer provides **immediate, automated verification** of consistency between norms and their implementation procedures. Unlike the normative layer (which verifies logical consistency via SMT) or the executable layer (which verifies correctness via tests), the operational layer verifies **structural alignment** between legal intent and computational specification.

### What Can Be Verified

#### 1. Norm-Procedure Consistency Checks

##### Entity Alignment
**Rule:** A procedure's entities must be compatible with the norm's quantifiers.

**Example:**
```markdown
# Norm
The *FoyerFiscal* **has the right to** *deduct* *professional expenses*
to *Tax Authority* when *FoyerFiscal* has *professional activity* {#art156-II}

# Procedure (VALID)
## Procedure: Professional expense deduction {#expense-deduction}
**Applies:** #art156-II
**Entity:** *FoyerFiscal*
...

# Procedure (INVALID - Entity Mismatch)
## Procedure: Professional expense deduction {#expense-deduction}
**Applies:** #art156-II
**Entity:** *Individual*  ← ERROR: Norm quantifies over *FoyerFiscal*, not *Individual*
...
```

**Checker behavior:** Flag as error if procedure entity is not a subset of norm's quantified entities.

##### Temporal Constraint Propagation
**Rule:** A procedure's temporal parameters must respect the norm's temporal constraints.

**Example:**
```markdown
# Norm
The *Taxpayer* **has the right to** *carry forward* *agricultural deficit*
to *Tax Authority* for *6 years* {#art156-I-1}

# Procedure (VALID)
## Procedure: Agricultural deficit carryforward {#deficit-carryforward}
**Applies:** #art156-I-1
**Period:** *Year*
**Steps:**
...
5. Carry forward *Deficit* to next 6 years

# Procedure (INVALID - Temporal Mismatch)
## Procedure: Agricultural deficit carryforward {#deficit-carryforward}
**Applies:** #art156-I-1
**Period:** *Year*
**Steps:**
...
5. Carry forward *Deficit* to next 5 years  ← ERROR: Norm says 6 years, procedure says 5
```

**Checker behavior:** Extract temporal constraints from norm, verify procedure respects them.

##### Orphan Procedure Detection
**Rule:** Every procedure must reference an existing norm via `**Applies:**`.

**Example:**
```markdown
# Procedure (INVALID - Orphan)
## Procedure: Mystery calculation {#mystery-calc}
**Applies:** #art999-Z  ← ERROR: No norm with ID #art999-Z exists
**Entity:** *TaxHousehold*
...
```

**Checker behavior:** Verify that every `**Applies:**` reference points to a declared norm.

##### Missing Procedure Warnings (Heuristic)
**Rule:** Norms with computable entities and numerical conditions likely need procedures.

**Heuristic criteria:**
- Norm quantifies over a computable entity (`*FoyerFiscal*`, `*Individual*`)
- Norm references numerical quantities (`*Income*`, `*Threshold*`, `*Rate*`)
- No procedure exists with `**Applies:** #this-norm`

**Example:**
```markdown
# Norm (likely needs procedure)
The *FoyerFiscal* **has the right to** *deduct* *10%* of *professional income*
to *Tax Authority* when *professional income* > *5000 EUR* {#art156-new}

# No procedure with **Applies:** #art156-new
# → WARNING: This norm may require an implementation procedure
```

**Checker behavior:** Flag as warning (not error). Human decides if procedure is needed.

#### 2. Named Constant Consistency

##### Parameter Uniqueness
**Rule:** A named parameter must have a single, consistent value across all procedures.

**Example:**
```markdown
# Procedure 1
## Procedure: Standard deduction {#standard-deduction}
**Parameters:**
- *DeductionCeiling* = 13,522 EUR

# Procedure 2 (INVALID - Inconsistent Value)
## Procedure: Alternative deduction {#alt-deduction}
**Parameters:**
- *DeductionCeiling* = 15,000 EUR  ← ERROR: Same name, different value
```

**Checker behavior:** Build global parameter registry, flag conflicts.

##### Type Consistency
**Rule:** A named entity must have consistent type across all uses.

**Example:**
```markdown
# Procedure 1
**Parameters:**
- *SeuilDéficitAgricole*: Currency(EUR) = 10,700

# Procedure 2 (INVALID - Type Mismatch)
**Parameters:**
- *SeuilDéficitAgricole*: Integer = 10700  ← ERROR: Type changed from Currency to Integer
```

**Checker behavior:** Track type declarations, flag type conflicts.

##### Reference Validation
**Rule:** All parameter references must point to declared parameters.

**Example:**
```markdown
## Procedure: Tax calculation {#tax-calc}
**Steps:**
1. Obtain *GrossIncome* of *TaxHousehold*
2. Calculate *Deduction* = *GrossIncome* × *UndeclaredRate*  ← ERROR: *UndeclaredRate* not declared

**Parameters:**
- *StandardRate* = 10%
```

**Checker behavior:** Verify all referenced parameters are declared in procedure or imported.

#### 3. Audit Trail Capabilities

##### Bidirectional Traceability
**Forward:** From norm to implementation
```
#art156-II (norm)
  → #expense-deduction (procedure)
    → ProfessionalExpenseDeduction (OpenFisca variable)
      → def formula(household, period, parameters): ...
```

**Backward:** From code to legal basis
```
Why does this formula exist?
  ← ProfessionalExpenseDeduction implements #expense-deduction
    ← #expense-deduction applies #art156-II
      ← #art156-II is Article 156 II of French Tax Code
```

**Value:** Answer regulatory questions: "What is the legal basis for this calculation?"

##### Provenance Tracking
**Capability:** For any computed value, trace back to originating norm.

**Example query:**
```
Q: Why is *StandardDeductionAmount* = 13,522 EUR?
A: 
  - Declared in procedure #standard-deduction-employee
  - Which applies norm #art156-II
  - Parameter *DeductionCeiling* = 13,522 EUR
  - Revised annually per first tax bracket (reference: BOI-IR-BASE-20-30)
```

##### Change Impact Analysis
**Capability:** If a norm changes, identify affected procedures and code.

**Example:**
```
Norm #art156-II modified: temporal constraint changed from 6 years to 5 years

Impact:
  - Procedure #deficit-carryforward (MUST UPDATE)
  - Procedure #agricultural-deficit (MUST UPDATE)
  - OpenFisca variable DeficitCarryforward (MUST REGENERATE)
  - 12 test cases (MUST REVIEW)
```

##### Documentation Generation
**Capability:** Automatically generate legal basis reports.

**Example output:**
```markdown
# Legal Basis Report: Professional Expense Deduction

**Norm:** Article 156 II, French Tax Code
**Procedure:** #expense-deduction
**Entities:** *FoyerFiscal*
**Period:** *Year*
**Parameters:**
  - *DeductionRate* = 10%
  - *DeductionCeiling* = 13,522 EUR

**Implementation:** OpenFisca variable `professional_expense_deduction`
**Last verified:** 2026-04-28
**Status:** Consistent
```

### What Cannot Be Verified

#### 1. Coverage Completeness
**Question:** Did we encode all relevant law?

**Why unverifiable:** The system cannot know what legal text exists outside the document. A lawyer could omit Article 157 entirely, and the checker would not detect it.

**Mitigation:** Human review, cross-reference with official legal codes.

#### 2. Encoding Correctness
**Question:** Does our encoding faithfully represent the law?

**Why unverifiable:** The system cannot compare the OpenNorm encoding to the original legal text. A lawyer could write `#art156-I-1` that encodes something completely different from what Article 156 I 1° actually says.

**Example of undetectable error:**
```markdown
# What the law says:
"Les déficits agricoles sont reportables pendant 6 ans"

# What we encoded (WRONG but internally consistent):
The *Taxpayer* **has the duty to** *pay* *100% of agricultural deficit*
to *State* when *Taxpayer* has *agricultural activity* {#art156-I-1}
```

**Mitigation:** Human legal review, peer review, official validation.

#### 3. Semantic Accuracy
**Question:** Is the legal interpretation sound?

**Why unverifiable:** The system cannot judge if the interpretation of ambiguous legal text is correct. Legal experts may disagree on interpretation.

**Example:**
```markdown
# Ambiguous legal text:
"Les frais professionnels réels et justifiés"

# Interpretation A:
*DocumentedExpenses* with *ValidReceipts*

# Interpretation B:
*DocumentedExpenses* with *ValidReceipts* and *BusinessPurposeProof*

# Both are internally consistent, but which is legally correct?
```

**Mitigation:** Legal doctrine, case law, administrative guidance.

### Verification Workflow

```
1. Parse document
   ↓
2. Build norm registry
   ↓
3. Build procedure registry
   ↓
4. Build parameter registry
   ↓
5. Run consistency checks:
   - Entity alignment
   - Temporal constraints
   - Orphan detection
   - Parameter uniqueness
   - Type consistency
   - Reference validation
   ↓
6. Generate warnings:
   - Missing procedures (heuristic)
   - Potential inconsistencies
   ↓
7. Build audit trail graph
   ↓
8. Generate reports
```

### Error Severity Levels

| Level | Description | Action |
|-------|-------------|--------|
| **ERROR** | Structural inconsistency that must be fixed | Block code generation |
| **WARNING** | Potential issue requiring human review | Allow code generation with flag |
| **INFO** | Suggestion or optimization opportunity | No blocking |

**Examples:**
- ERROR: Procedure references non-existent norm
- ERROR: Same parameter name with different values
- WARNING: Norm with computable entities has no procedure
- INFO: Parameter could be extracted to shared constants

### Benefits Summary

1. **Immediate value** - No network effect required
2. **Automated checking** - Catches errors before code generation
3. **Regulatory compliance** - Formal audit trail for authorities
4. **Maintainability** - Change impact analysis guides updates
5. **Documentation** - Auto-generated legal basis reports
6. **Consistency** - Single source of truth for parameters

### Limitations Summary

1. **Cannot verify coverage** - Requires human review
2. **Cannot verify correctness** - Requires legal expertise
3. **Cannot verify semantics** - Requires domain knowledge
4. **Heuristics are imperfect** - False positives/negatives possible

---

## Examples from Article 156

### Example 1: Simple Leaf Procedure

```markdown
## Procedure: Standard deduction for employee {#standard-deduction-employee}

**Applies:** #art156-II
**Entity:** *TaxHousehold*
**Period:** *Year*
**Result:** *StandardDeductionAmount*

**Steps:**
1. Obtain *GrossIncome* of *TaxHousehold*
2. Calculate *RawDeduction* = *GrossIncome* × *DeductionRate*
3. Apply ceiling: *StandardDeductionAmount* = min(*RawDeduction*, *DeductionCeiling*)

**Parameters:**
- *DeductionRate* = 10%
- *DeductionCeiling* = 13,522 EUR (revised annually according to first tax bracket)
```

### Example 2: Branching Orchestrator

```markdown
## Procedure: Professional expense deduction {#professional-expense-deduction}

**Applies:** #art156-II
**Entity:** *TaxHousehold*
**Period:** *Year*
**Result:** *ProfessionalExpenseDeduction*

**Steps:**
1. Obtain *ProfessionalStatus* of *Taxpayer*
2. **If** *ProfessionalStatus* = *Employee*
   → Calculate via #standard-deduction-employee
3. **If** *ProfessionalStatus* = *SelfEmployed*
   → Calculate via #actual-expenses-self-employed
4. **If** *ProfessionalStatus* = *Farmer*
   → Calculate via #agricultural-expenses
5. **Otherwise**
   → *ProfessionalExpenseDeduction* = 0

**Parameters:**
- (none)
```

### Example 3: Complex Procedure with Verification

```markdown
## Procedure: Actual expenses for self-employed {#actual-expenses-self-employed}

**Applies:** #art156-II
**Entity:** *TaxHousehold*
**Period:** *Year*
**Result:** *ActualExpensesDeduction*

**Steps:**
1. Obtain *DocumentedProfessionalExpenses* of *SelfEmployedTaxpayer*
2. Verify that *Documentation* is complete and valid
3. **If** verification succeeds
   → *ActualExpensesDeduction* = *DocumentedProfessionalExpenses*
4. **Otherwise**
   → *ActualExpensesDeduction* = 0

**Parameters:**
- (none)
```

### Example 4: Multi-Level Orchestration

```markdown
## Procedure: Taxable income calculation {#taxable-income-calculation}

**Applies:** #art156
**Entity:** *TaxHousehold*
**Period:** *Year*
**Result:** *TaxableIncome*

**Steps:**
1. Obtain *GrossIncome* of *TaxHousehold*
2. Calculate via #professional-expense-deduction
3. Calculate via #deficit-deduction
4. Calculate via #property-deficit-deduction
5. Calculate *TaxableIncome* = *GrossIncome* - *TotalDeductions*

**Parameters:**
- (none)
```

---

## Open Questions

### 1. Conditional Syntax
**Question:** Should we use `**If**` or a more structured format?

**Option A (Current):**
```markdown
2. **If** *Status* = *Employee*
   → Calculate via #standard-deduction
```

**Option B (More structured):**
```markdown
2. Branch on *Status*:
   - *Employee* → Calculate via #standard-deduction
   - *SelfEmployed* → Calculate via #actual-expenses
   - Default → *Deduction* = 0
```

**Decision:** TBD

### 2. Expression Syntax
**Question:** How complex should expressions be?

**Simple (Current):**
```markdown
Calculate *X* = *Y* × *Z*
Calculate *X* = min(*Y*, *Z*)
```

**Complex:**
```markdown
Calculate *X* = (*Y* × *Z*) + (*A* - *B*) / *C*
```

**Decision:** Start simple, extend as needed

### 3. Temporal References
**Question:** How to handle multi-year calculations?

**Example:**
```markdown
5. Carry forward *Deficit* to *TaxableIncome* of next 6 years
```

**Decision:** TBD - may need special syntax for temporal operations

### 4. Iteration
**Question:** How to handle loops/iterations?

**Example:** "For each child, add 0.5 to family quotient"

**Option A:**
```markdown
3. For each *Child* in *TaxHousehold*:
   → Add 0.5 to *FamilyQuotient*
```

**Option B:**
```markdown
3. Calculate *FamilyQuotient* = 2.0 + (0.5 × *NumberOfChildren*)
```

**Decision:** Prefer declarative (Option B) when possible

### 5. Error Handling
**Question:** How to handle invalid inputs or edge cases?

**Example:**
```markdown
2. Verify that *GrossIncome* > 0
3. **If** verification fails
   → Raise error: "Invalid gross income"
```

**Decision:** TBD

### 6. Units and Types
**Question:** Should we explicitly declare units?

**Option A (Implicit):**
```markdown
*DeductionCeiling* = 13,522 EUR
```

**Option B (Explicit):**
```markdown
*DeductionCeiling*: Currency(EUR) = 13,522
```

**Decision:** TBD

---

## Implementation Plan

### Phase 1: Core Syntax and Parser
1. Define complete syntax specification
2. Extend parser to recognize `## Procedure:` blocks
3. Parse metadata fields (`**Applies:**`, `**Entity:**`, etc.)
4. Parse step lists with numbering
5. Identify step types (retrieve, calculate, delegate, etc.)

### Phase 2: IR Structures
1. Define `Procedure` struct in `structures.jl`
2. Define `Step` and step type variants
3. Build procedure graph from references
4. Validate graph (check for cycles, undefined references)

### Phase 3: Code Generation
1. Implement `to_openfisca()` generator
2. Generate Python OpenFisca variables
3. Generate parameter YAML files
4. Handle delegation through variable dependencies

### Phase 4: Validation and Tooling
1. Type checking for variables
2. Parameter validation
3. Graph visualization
4. Documentation generation

### Phase 5: Extensions
1. Temporal operations
2. Iteration constructs
3. Error handling
4. Advanced expressions

---

## Next Steps

1. **Review and refine** this design document
2. **Work through more examples** from Article 156
3. **Make design decisions** on open questions
4. **Create syntax specification** document
5. **Begin implementation** of parser extensions

---

## Notes

- This is a **living document** - update as design evolves
- Focus on **readability** - lawyers must be able to write procedures
- Maintain **traceability** - always link back to norms
- Keep it **simple** - start with core features, extend as needed
- **Test with real examples** - Article 156 is a good stress test