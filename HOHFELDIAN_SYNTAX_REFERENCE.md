# OpenNorm Hohfeldian Syntax Reference
## Technical Specification v2.0

> This document specifies the Hohfeldian position-based syntax system introduced in OpenNorm 2.0.
> All legal relationships are expressed through the `holds()` predicate and eight core modal keywords.
> This is a technical reference for transpiler implementation and formal verification.

---

## Table of Contents

1. [Overview and Philosophy](#1-overview-and-philosophy)
2. [The Eight Hohfeldian Positions](#2-the-eight-hohfeldian-positions)
3. [The Counterparty Preposition System](#3-the-counterparty-preposition-system)
4. [Rule Structure Specification](#4-rule-structure-specification)
5. [Exception Hierarchies (excepts)](#5-exception-hierarchies-excepts)
6. [Scenario Syntax](#6-scenario-syntax)
7. [The Seven-Pass Transpiler Pipeline](#7-the-seven-pass-transpiler-pipeline)
8. [Lean Code Generation Patterns](#8-lean-code-generation-patterns)
9. [Complete Example: MIT License](#9-complete-example-mit-license)
10. [Grammar Extensions](#10-grammar-extensions)

---

## 1. Overview and Philosophy

### 1.0 Package Types

OpenNorm documents are classified into three package types, each serving a distinct purpose:

#### 1.0.1 stdlib (Standard Library)

**Purpose:** Framework rules and foundational legal principles that provide reusable building blocks.

**Characteristics:**
- Package-type: `stdlib`
- Defines fundamental legal constraints (e.g., nemo dat, bona fide purchaser)
- Imported by other documents
- Stable, versioned, and broadly applicable
- Located in `stdlib/frameworks/`

**Example:**
```markdown
**Package:** universal.transfer
**Package-type:** stdlib
**Version:** 1.0
**Status:** stable
```

**Common stdlib packages:**
- `stdlib/frameworks/universal/core` - Core framework axioms
- `stdlib/frameworks/universal/transfer` - Property transfer rules (nemo dat, bona fide purchaser)
- `stdlib/frameworks/universal/definitions` - Common term definitions

---

#### 1.0.2 ruling (Legal Instruments)

**Purpose:** Specific legal instruments such as licenses, contracts, statutes, or regulations.

**Characteristics:**
- Package-type: `ruling` (note: sometimes called "license" in examples, but formally "ruling")
- Contains concrete rules for a specific legal instrument
- May import stdlib frameworks
- Versioned and status-tracked (draft, review, final)
- Located in domain-specific directories (e.g., `licences/`)

**Example:**
```markdown
**Package:** MIT
**Package-type:** ruling
**Version:** 2.0
**Status:** review
**Imports:**
- stdlib/frameworks/universal/core@2.0
```

**Common ruling packages:**
- MIT License
- Apache 2.0 License
- GPL v3
- Employment contracts
- Terms of service

---

#### 1.0.3 scenario (Test Cases)

**Purpose:** Test scenarios that verify rules produce expected outcomes through Facts and Questions.

**Characteristics:**
- Package-type: `scenario`
- Contains Facts (axioms) and Questions (queries)
- Imports ruling or stdlib packages to test
- No version or status (transient test documents)
- Uses scenario-specific syntax (isa, has, under, Does)

**Example:**
```markdown
**Package:** mit.scenarios
**Package-type:** scenario
**Import:** licences/mit.strict@2.0

## Scenario: Bob Distributes Without Notice

**Facts:**
*Alice* has licensed *the Software* under *MIT*
*Bob* has obtained *the Software* from *Alice*

**Questions:**
Does *Bob* **must** include *the Copyright Notice*
```

**Purpose of scenarios:**
- Validation testing of rules
- Documentation of expected behavior
- Regression testing
- Training and examples

---

### 1.1 The Hohfeldian Foundation

OpenNorm 2.0 adopts Wesley Hohfeld's relational theory of legal positions as its formal foundation. Every legal relationship is expressed as one of eight fundamental positions that exist between two parties (holder and counterparty) regarding an action or state.

**Core Principle:** All normative content transpiles to the `holds()` predicate:

```lean4
holds : Position → Quantifier → Action → Object → Quantifier → Prop
```

Where:
- **Position** ∈ {Privilege, Duty, Right, NoRight, Power, Disability, Immunity, Liability}
- **First Quantifier** = actor (the holder or party subject to the position)
- **Action** = the action being performed
- **Object** = what the action operates on
- **Second Quantifier** = counterparty (who the position is held against/toward)

### 1.2 Why Hohfeld?

Traditional legal language conflates multiple distinct relationships under ambiguous terms like "right" and "duty". Hohfeld's system disambiguates these relationships:

- **First-order positions** govern primary conduct (may/must/is entitled to/has no right to)
- **Second-order positions** govern legal relationships themselves (can/cannot/is protected from)

This distinction is crucial for:
1. **Contradiction detection** — knowing exactly what conflicts with what
2. **C-correlative generation** — every position implies its opposite for the counterparty
3. **Exception hierarchies** — depth determines whether the position or its opposite applies

### 1.3 The holds() Predicate

Every rule in OpenNorm ultimately becomes a `holds()` statement:

```lean4
-- Surface syntax:
-- *Licensee* **must** *include* *the Copyright Notice* to *AnyOne*

-- Lean target:
holds Duty (Only Licensee) include CopyrightNotice AnyOne
```

The transpiler's job is to:
1. Parse surface syntax into Position + Quantifiers + Action + Object
2. Validate preposition matches position type
3. Generate the `holds()` statement
4. Apply conditions and exceptions through logical operators

---

## 2. The Eight Hohfeldian Positions

### 2.1 Position Type System

```lean4
inductive Order where
  | First   -- primary conduct
  | Second  -- legal relationships

inductive Polarity where
  | Positive   -- permits/empowers
  | Negative   -- prohibits/disables

inductive Subject where
  | Holder       -- position held by actor
  | Counterparty -- position held against actor

structure Position where
  subject  : Subject
  polarity : Polarity
  order    : Order
```

### 2.2 First-Order Positions (Primary Conduct)

#### 2.2.1 Privilege (has privilege to)

**Surface syntax:** `**has privilege to**`

**Lean target:**
```lean4
Position := Privilege (Counterparty, Negative, First)
```

**Meaning:** The actor is permitted to perform the action. The counterparty has no right to prevent it.

**Example:**
```markdown
*Licensor* **has privilege to** *use*, *copy*, *modify* *the Software* to *AnyOne*
```

**Transpiles to:**
```lean4
holds Privilege (Only Licensor) use Software AnyOne ∧
holds Privilege (Only Licensor) copy Software AnyOne ∧
holds Privilege (Only Licensor) modify Software AnyOne
```

**C-correlative:** If A has a Privilege against B, then B has a NoRight against A.

---

#### 2.2.2 Duty (must)

**Surface syntax:** `**must**`

**Lean target:**
```lean4
Position := Duty (Counterparty, Positive, First)
```

**Meaning:** The actor is obligated to perform the action. The counterparty has a right to demand it.

**Example:**
```markdown
*Licensee* **must** *include* *the Copyright Notice* to *AnyOne*
when *Licensee* has *distributed* *the Software*
```

**Transpiles to:**
```lean4
∀ (licensee : Quantifier) (sw : Software),
  holds Privilege licensee distribute sw AnyOne →
  holds Duty licensee include CopyrightNotice AnyOne
```

**C-correlative:** If A has a Duty to B, then B has a Right against A.

---

#### 2.2.3 Right (has right to)

**Surface syntax:** `**has right to**`

**Lean target:**
```lean4
Position := Right (Holder, Positive, First)
```

**Meaning:** The actor (holder) can demand the action from the counterparty. The counterparty has a duty.

**Example:**
```markdown
*DataSubject* **has right to** *erasure* *PersonalData* from *Controller*
```

**Transpiles to:**
```lean4
holds Right (Only DataSubject) erasure PersonalData (Only Controller)
```

**C-correlative:** If A has a Right against B, then B has a Duty to A.

---

#### 2.2.4 NoRight (has no right to)

**Surface syntax:** `**has no right to**`

**Lean target:**
```lean4
Position := NoRight (Holder, Negative, First)
```

**Meaning:** The actor (holder) cannot demand the action. The counterparty has a privilege to refuse.

**Example:**
```markdown
*Licensor* **has no right to** *warrant* *the Software* from *Licensee*
```

**Transpiles to:**
```lean4
holds NoRight (Only Licensor) warrant Software (Only Licensee)
```

**C-correlative:** If A has NoRight against B, then B has a Privilege against A.

---

#### 2.2.5 Liability (is subject to)

**Surface syntax:** `**is subject to**`

**Lean target:**
```lean4
Position := Liability (Counterparty, Positive, Second)
```

**Meaning:** The actor is subject to the counterparty's power to alter legal relationships. When the counterparty exercises their power, the actor's legal position changes.

**Example:**
```markdown
*Transferee* **is subject to** *receive* *Property* by *Transferor*
when *Transferor* has *exercised* *Power of Transfer*
```

**Transpiles to:**
```lean4
∀ (transferor : Quantifier) (transferee : Quantifier) (prop : Object),
  holds Power transferor transfer prop transferee →
  holds Liability transferee receive prop transferor
```

**C-correlative:** If A has Liability to B, then B has a Power over A.

**Note:** Liability is rarely written explicitly in surface syntax. It is typically **auto-generated** as the correlative of Power. When you write "X has power to Y over Z", the transpiler automatically generates "Z is subject to Y by X".

---

### 2.4 Second-Order Positions (Legal Relationships)

#### 2.4.1 Power (has power to)

**Surface syntax:** `**has power to**`

**Lean target:**
```lean4
Position := Power (Holder, Positive, Second)
```

**Meaning:** The actor (holder) has the legal ability to alter legal relationships.

**Example:**
```markdown
*Licensor* **has power to** *sublicense* *the Software* over *Licensee*
```

**Transpiles to:**
```lean4
holds Power (Only Licensor) sublicense Software (Only Licensee)
```

**C-correlative:** If A has Power over B, then B has Liability to A (subject to A's power).

---

#### 2.4.2 Disability (has no power to)

**Surface syntax:** `**has no power to**`

**Lean target:**
```lean4
Position := Disability (Holder, Negative, Second)
```

**Meaning:** The actor (holder) lacks the legal ability to alter legal relationships.

**Example:**
```markdown
*Licensor* **has no power to** *revoke* *the License* over *Licensee*
when *Licensee* has *obtained* *the Software*
```

**Transpiles to:**
```lean4
∀ (licensor : Quantifier) (licensee : Quantifier) (sw : Software),
  holds Privilege licensee obtain sw licensor →
  holds Disability licensor revoke License licensee
```

**C-correlative:** If A has Disability to B, then B has Immunity from A.

---

#### 2.4.3 Immunity (has immunity from)

**Surface syntax:** `**has immunity from**`

**Lean target:**
```lean4
Position := Immunity (Counterparty, Negative, Second)
```

**Meaning:** The actor is protected from the counterparty's attempt to alter legal relationships.

**Example:**
```markdown
*Licensor* **has immunity from** *claim* *damages* by *AnyOne*
when *AnyOne* has *used* *the Software*
```

**Transpiles to:**
```lean4
∀ (licensor : Quantifier) (user : Quantifier) (sw : Software),
  holds Privilege user use sw AnyOne →
  holds Immunity licensor claim_damages user
```

**C-correlative:** If A has Immunity from B, then B has Disability to A.

---

### 2.5 Position Summary Tables

#### Table 1: Position Definitions

| Surface Syntax | Position | Subject | Polarity | Order |
|---|---|---|---|---|
| **has right to** | Right | Holder | Positive | First |
| **has no right to** | NoRight | Holder | Negative | First |
| **has privilege to** | Privilege | Counterparty | Negative | First |
| **must** | Duty | Counterparty | Positive | First |
| **has power to** | Power | Holder | Positive | Second |
| **has no power to** | Disability | Holder | Negative | Second |
| **is subject to** | Liability | Counterparty | Positive | Second |
| **has immunity from** | Immunity | Counterparty | Negative | Second |

#### Table 2: Position Operators

| Position | C-Correlative | O-Opposite | E-Order Change |
|---|---|---|---|
| Right | Duty | NoRight | Power |
| NoRight | Privilege | Right | Disability |
| Privilege | NoRight | Duty | Immunity |
| Duty | Right | Privilege | Liability |
| Power | Liability | Disability | Right |
| Disability | Immunity | Power | NoRight |
| Liability | Power | Immunity | Duty |
| Immunity | Disability | Liability | Privilege |

**Operator Definitions:**

- **C-Correlative** (Correlative): Swap subject (Holder ↔ Counterparty). If A has position P against B, then B has C(P) against A.
- **O-Opposite** (Opposite): Flip polarity (Positive ↔ Negative), keep subject and order. The negation of a position.
- **E-Order Change** (Order Transformation): Change order (First ↔ Second), keep subject and polarity. Maps conduct positions to power positions.

**Note on Exceptions:**

When a rule uses the `excepts #parent-rule` clause (see §4.10, §5), the H-keyword (surface syntax) is **omitted**. The position is automatically computed by the transpiler from:
1. The parent rule's position
2. The exception depth (parent.depth + 1)
3. Position flipping: if depth is odd → O_pos(parent.position), if even → parent.position

This makes exception syntax simpler - drafters don't need to determine or write the correct H-keyword.

**Example:**
```markdown
*Licensee* **has privilege to** *use*, *copy*, *distribute*, *sell* *the Software*
```

**Transpiles to:**
```lean4
holds Privilege Licensee distribute Software AnyOne →
holds Duty Licensee include Notice AnyOne
```

---

### 2.6 The Z₂³ Torsor: Mathematical Foundation

#### 2.6.1 Why Exactly Eight Positions?

The eight Hohfeldian positions are not an arbitrary list. They form a **Z₂³ torsor** — the complete set generated by three independent binary operators acting on a three-dimensional binary space.

**The fundamental insight:** Each legal position is characterized by exactly three binary properties:
1. **Subject** ∈ {Holder, Counterparty}
2. **Polarity** ∈ {Positive, Negative}
3. **Order** ∈ {First, Second}

Since each property has two values, the total number of distinct positions is:
```
2 × 2 × 2 = 2³ = 8 positions
```

This is **provably complete** (no missing positions) and **provably minimal** (no redundant positions).

---

#### 2.6.2 The Three Operators Form Z₂³

The three operators {C, O, E} correspond to flipping each dimension:

| Operator | Dimension Changed | Other Dimensions |
|---|---|---|
| **C** (Correlative) | Subject: Holder ↔ Counterparty | Polarity and Order **unchanged** |
| **O** (Opposite) | Polarity: Positive ↔ Negative | Subject and Order **unchanged** |
| **E** (Order Change) | Order: First ↔ Second | Subject and Polarity **unchanged** |

**Critical property:** Each operator changes **exactly one dimension** while leaving the other two untouched. This guarantees:
- **Independence**: The operators are orthogonal
- **Completeness**: Any position can be reached from any other
- **Minimality**: No operator is redundant

---

#### 2.6.3 Torsor Property: No Privileged Origin

Unlike a vector space, a **torsor has no distinguished origin**. No position is more "fundamental" than any other. 

You can start from **any** position and generate all eight by applying {C, O, E}:

**Example starting from Right:**
```
Right (Holder, Positive, First)
  ├─ C(Right) = Duty         (Counterparty, Positive, First)
  ├─ O(Right) = NoRight      (Holder, Negative, First)
  ├─ E(Right) = Power        (Holder, Positive, Second)
  ├─ C∘O(Right) = Privilege  (Counterparty, Negative, First)
  ├─ C∘E(Right) = Liability  (Counterparty, Positive, Second)
  ├─ O∘E(Right) = Disability (Holder, Negative, Second)
  └─ C∘O∘E(Right) = Immunity (Counterparty, Negative, Second)
```

**Same result starting from any other position** — the group structure is preserved.

---

#### 2.6.4 Group Properties

The operators form an **abelian group** (commutative group):

**Involution:** Each operator is its own inverse.
```
C² = O² = E² = identity
```

**Commutativity:** Operators can be applied in any order.
```
C∘O = O∘C
C∘E = E∘C  
O∘E = E∘O
```

**Closure:** Applying any operator to any position yields another valid position.

**Generator property:** The set {C, O, E} generates the complete group Z₂³ with 2³ = 8 elements (including identity).

---

#### 2.6.5 Why This Matters for Legal Reasoning

**Trustworthiness:** The system is not arbitrary. It's mathematically complete and minimal. There are no "forgotten" positions and no redundant ones.

**Mechanical verification:** The transpiler can verify that:
- Every position is reachable
- No contradictory positions are asserted simultaneously
- Correlatives are computed correctly (by applying C)
- Exception hierarchies preserve legal meaning (by alternating O)

**Formal proof:** In Lean, we can prove:
```lean4
theorem hohfeld_complete : 
  ∀ (s : Subject) (p : Polarity) (o : Order),
  ∃! (pos : Position), pos.subject = s ∧ pos.polarity = p ∧ pos.order = o := by
  -- Proof by exhaustive case analysis on the 8 positions
  
theorem operator_independence :
  ∀ (pos : Position),
  C(pos).polarity = pos.polarity ∧ C(pos).order = pos.order ∧
  O(pos).subject = pos.subject ∧ O(pos).order = pos.order ∧
  E(pos).subject = pos.subject ∧ E(pos).polarity = pos.polarity := by
  -- Each operator changes exactly one dimension
```

This mathematical foundation makes OpenNorm's legal reasoning **verifiable** and **trustworthy**.

---

### 2.7 Tree Structure and Operator Roles

#### 2.7.1 Two Trees, Not Eight Independent Positions

The eight positions are not independent — they form **four correlative pairs** organized into **two trees**:

**First-order tree (conduct positions):**
```
Right ←─C─→ Duty
  │           │
  O           O
  │           │
NoRight ←─C─→ Privilege
```

**Second-order tree (power positions):**
```
Power ←─C─→ Liability
  │           │
  O           O
  │           │
Disability ←─C─→ Immunity
```

---

#### 2.7.2 Operator Roles in the Tree Structure

Each operator has a specific role:

| Operator | Role | Effect |
|---|---|---|
| **C** | Generates correlatives | Horizontal: moves between holders and counterparties |
| **O** | Alternates within tree | Vertical: flips polarity at same order |
| **E** | Connects the trees | Diagonal: maps First-order ↔ Second-order |

**Example chains:**
```
Right →(O)→ NoRight →(C)→ Privilege →(E)→ Immunity
Right →(E)→ Power →(O)→ Disability →(C)→ Immunity
Right →(C)→ Duty →(E)→ Liability →(O)→ Immunity
```

All paths from Right to Immunity apply the operators in different orders, but the **commutativity** guarantees the same result.

---

#### 2.7.3 Exception Hierarchies and Tree Navigation

**In exception hierarchies**, depth determines which operator is applied:

**Odd depth:** Apply **O** (opposite) — navigate vertically within the tree
```
Depth 0: Right (root)
Depth 1: NoRight (O applied)
Depth 2: Right (O applied again, back to root position)
```

**C is applied automatically** for correlatives — the counterparty always has the correlative position.

**E connects the trees** — a second-order exception to a first-order rule (or vice versa) would apply E, but this is rare in practice.

**Key insight:** Normally there are **no more than 3 trees for a given predicate**:
- **First-order tree**: root is Right or Privilege
- **Second-order tree**: root is Power or Disability
- **C generates correlatives automatically** — they're computed, not asserted
- **E connects the two trees** when conduct rules create power relationships
- **O alternates within trees** through the exception hierarchy

This tree structure explains why we have **four pairs** of positions, not eight independent ones. The mathematical structure directly reflects the legal structure.

---

## 3. The Counterparty Preposition System

### 3.1 Purpose

Prepositions are **semantic sugar for humans**. They make the surface syntax more natural to read, but all map identically to the `counterparty` parameter in the `holds()` predicate.

```lean4
-- All four of these are identical in Lean:
holds Position actor action object counterparty
```

The transpiler validates that the preposition matches the expected usage for the position type. Mismatches are flagged for human review.

### 3.2 The Four Prepositions

#### 3.2.1 to *Q*

**Natural for:** Privilege, Duty

**Meaning:** The action is performed toward/for the counterparty.

**Example:**
```markdown
*Licensor* **has privilege to** *distribute* *the Software* to *AnyOne*
```

**Validation:** Privilege expects `to` — ✓ valid

---

#### 3.2.2 from *Q*

**Natural for:** Right, NoRight

**Meaning:** The actor demands/lacks demand from the counterparty.

**Example:**
```markdown
*DataSubject* **has right to** *erasure* *PersonalData* from *Controller*
```

**Validation:** Right expects `from` — ✓ valid

---

#### 3.2.3 by *Q*

**Natural for:** Immunity

**Meaning:** The actor is protected from actions by the counterparty.

**Example:**
```markdown
*Licensor* **has immunity from** *claim* *damages* by *AnyOne*
```

**Validation:** Immunity expects `by` — ✓ valid

---

#### 3.2.4 over *Q*

**Natural for:** Power, Disability

**Meaning:** The actor has/lacks power over the counterparty's legal position.

**Example:**
```markdown
*Licensor* **has no power to** *revoke* *the License* over *Licensee*
```

**Validation:** Disability expects `over` — ✓ valid

---

### 3.3 Validation Rules

The transpiler checks position-preposition pairs:

| Position | Expected Preposition | Mismatch Action |
|---|---|---|
| Privilege | `to` | Flag for review |
| Duty | `to` | Flag for review |
| Right | `from` | Flag for review |
| NoRight | `from` | Flag for review |
| Power | `over` | Flag for review |
| Disability | `over` | Flag for review |
| Liability | `by` | Flag for review |
| Immunity | `by` | Flag for review |

**Example mismatch:**
```markdown
*Licensor* **has privilege to** *distribute* *the Software* from *AnyOne*
```
Expected `to`, found `from` → **W101: Preposition mismatch for Privilege. Suggestion: Use "to *AnyOne*" instead of "from *AnyOne*"**

**Transpiler behavior on mismatch:**
The transpiler suggests the correct preposition based on the position type, making it easy for drafters to fix the syntax without needing to memorize the preposition rules.

---

## 4. Rule Structure Specification

### 4.1 Rule Anatomy

Every rule follows this structure:

```markdown
### Title

> Description (optional)
> See: internal-reference (optional)
> [External Reference Text](https://external.url) (optional)

*Actor* **H-keyword** *action*, *action* *the Object* to/from/by/over *Counterparty*
when *condition* (optional)
```

### 4.2 Title → RuleId Generation

**Algorithm:**
1. Take the title text after `###`
2. Convert to lowercase
3. Replace spaces with hyphens
4. Prefix with `#`

**Examples:**
- `### MIT Grant` → `#mit-grant`
- `### MIT Notice Obligation` → `#mit-notice-obligation`
- `### Data Subject Rights` → `#data-subject-rights`

**Lean target:**
```lean4
def rule_ref : RuleId := ⟨"mit-grant"⟩
```

### 4.3 Description and References

#### 4.3.1 Description

**Surface syntax:**
```markdown
> This is a human-readable description.
> It can span multiple lines.
```

**Lean target:**
```lean4
/- This is a human-readable description.
   It can span multiple lines. -/
```

**Purpose:** Preserved for documentation. Ignored by prover.

---

#### 4.3.2 Internal Reference (See:)

**Surface syntax:**
```markdown
> See: #another-rule-id
```

**Lean target:**
```lean4
/- internal reference: #another-rule-id -/
```

**Purpose:** Logged for traceability. Not verified.

---

#### 4.3.3 External Reference

**Surface syntax:**
```markdown
> [MIT License Text](https://opensource.org/licenses/MIT)
```

**Lean target:**
```lean4
/- external anchor: MIT License Text - https://opensource.org/licenses/MIT -/
```

**Purpose:** Standard Markdown link syntax for external references. Availability checked during validation. Not part of formal verification.

---

### 4.4 Actor

**Surface syntax:** `*Actor*`

**Taxonomy resolution:**
1. Lookup in LegalEntities taxonomy
2. If found → coerce to `Quantifier` via `Only`
3. If not found in LegalEntities, lookup in Role taxonomy
4. If found → use directly as `Quantifier`
5. If not found anywhere → **error or sorry stub**

**Example 1 (LegalEntity):**
```markdown
*Alice* **has privilege to** *use* *the Software*
```
`Alice` ∈ LegalEntities → transpiles to:
```lean4
holds Privilege (Only Alice) use Software AnyOne
```

**Example 2 (Role):**
```markdown
*Licensee* **must** *include* *CopyrightNotice*
```
`Licensee` ∈ Role → transpiles to:
```lean4
holds Duty Licensee include CopyrightNotice AnyOne
```

---

### 4.5 Actions (Multiple Actions)

**Surface syntax:** `*action*, *action*, *action*`

**Lean target:** Each action generates a separate `holds()` statement, combined with conjunction (∧).

**Example:**
```markdown
*Licensor* **has privilege to** *use*, *copy*, *distribute* *the Software* to *AnyOne*
```

**Transpiles to:**
```lean4
holds Privilege (Only Licensor) use Software AnyOne ∧
holds Privilege (Only Licensor) copy Software AnyOne ∧
holds Privilege (Only Licensor) distribute Software AnyOne
```

**Note:** One syntax tree per action. Each action is independently evaluated.

---

### 4.6 Object

**Surface syntax:** `*the Object*`

**Taxonomy resolution:**
1. Lookup in Object taxonomy
2. If found → use directly
3. If not found → **error or sorry stub**

**Example:**
```markdown
*Licensee* **has privilege to** *use* *the Software*
```

**Transpiles to:**
```lean4
holds Privilege (Only Licensee) use Software AnyOne
```

---

### 4.7 Counterparty

**Surface syntax:** `to/from/by/over *Q*`

**Taxonomy resolution:** Same as Actor (LegalEntities → Only Q, Role → Q directly)

**Example:**
```markdown
*Licensor* **has privilege to** *distribute* *the Software* to *AnyOne*
```

**Transpiles to:**
```lean4
holds Privilege (Only Licensor) distribute Software AnyOne
```

---

### 4.8 Conditions (when)

**Surface syntax:**
```markdown
when *X* has *V* *O*
```

**Lean target:**
```lean4
condition : Prop := holds Privilege (Only X) V O AnyOne
```

**Integration with Rule:**
```lean4
Rule := condition → holds H actor action object counterparty
```

**Example:**
```markdown
*Licensee* **must** *include* *CopyrightNotice* to *AnyOne*
when *Licensee* has *distributed* *the Software*
```

**Transpiles to:**
```lean4
∀ (licensee : Quantifier) (sw : Software),
  holds Privilege licensee distribute sw AnyOne →
  holds Duty licensee include CopyrightNotice AnyOne
```

---

#### 4.8.1 Condition with Counterparty

**Surface syntax:**
```markdown
when *X* has *V* *O* to *Y*
```

**Lean target:**
```lean4
condition : Prop := holds Privilege (Only X) V O (Only Y)
```

**Example:**
```markdown
*Controller* **must** *erase* *PersonalData* from *DataSubject*
when *DataSubject* has *requested* *erasure* to *Controller*
```

**Transpiles to:**
```lean4
∀ (controller : Quantifier) (subject : Quantifier) (data : Object),
  holds Privilege subject request_erasure controller →
  holds Duty controller erase PersonalData subject
```

---

### 4.9 Definitions (Document-Level Predicates)

**Purpose:** Define custom predicates, constitutive rules, and axioms that are specific to the document and not in stdlib.

**Section header:**
```markdown
## Definitions
```

**Surface syntax:**
```markdown
## Definitions

### predicate_name

> Description (optional)

```lean4
[Lean code for axiom or definition]
```
```

**Placement:** After manifest, before Rules section.

**What can be defined:**

1. **Constitutive rules** - acts that make entities satisfy roles
2. **Custom predicates** - domain-specific conditions
3. **Axioms** - assumed-true statements about the domain
4. **Type refinements** - more specific quantifiers

**Example 1: Constitutive Rule**
```markdown
## Definitions

### obtained_constitutes_licensee

> Obtaining the software from a licensor constitutes becoming a licensee.

```lean4
axiom obtained_constitutes_licensee :
  ∀ (e : LegalEntity) (sw : Software) (licensor : LegalEntity),
  holds Privilege (Only e) obtain sw (Only licensor) →
  licensed_under licensor sw License →
  Licensee (Only e)
```
```

**Example 2: Custom Predicate**
```markdown
## Definitions

### has_active_conviction

> An entity has an active criminal conviction.

```lean4
def has_active_conviction (e : LegalEntity) : Prop :=
  ∃ (c : Conviction), active c ∧ convicted_of e c ∧ ¬pardoned e c
```
```

**Example 3: Domain Axiom**
```markdown
## Definitions

### distribution_implies_use

> Distributing software implies it has been used.

```lean4
axiom distribution_implies_use :
  ∀ (e : LegalEntity) (sw : Software),
  holds Privilege e distribute sw AnyOne →
  holds Privilege e use sw AnyOne
```
```

**Lean target:**
All definitions are placed in the preamble of the generated Lean file, before rule definitions. They become available for use in:
- Rule conditions (`when` clauses)
- Scenario facts
- Quantifier refinements
- Defeasibility resolvers

**Validation:**
- Lean code must be syntactically valid
- Referenced types must exist in stdlib or taxonomy
- Axioms should be explicitly marked with `axiom` keyword
- Definitions should use `def` keyword

**Why this is essential:**
Without document-level definitions, documents can only use:
1. Stdlib axioms (limited to universal principles)
2. Taxonomy entries (limited to pre-defined roles/actions)

Any real license or contract needs domain-specific predicates. For example:
- MIT needs: `obtained_constitutes_licensee`
- GDPR needs: `is_personal_data`, `has_consent`
- Employment contracts need: `is_employee`, `during_working_hours`

---

### 4.10 Exception Hierarchy (excepts)

**Surface syntax:**
```markdown
### Exception Rule Title
excepts #parent-rule-id
actions *action1*, *action2* (optional - filters to specific parent actions)

*Actor* (often narrowed from parent) *actions* *object* (inherited from parent) to/from/by/over *Counterparty*
when *condition* (optional)
```

**Key characteristic:** No H-keyword is written. The position is automatically computed by the transpiler.

**Meaning:** This rule is an exception to `#parent-rule-id`. It has higher priority in the defeasibility chain.

**What the transpiler computes:**
1. **Depth:** `parent.depth + 1`
2. **Position:** 
   - If depth is **even** → same position as root ancestor
   - If depth is **odd** → O_pos(root position) - the Hohfeldian opposite
3. **Actions:** Inherited from parent unless filtered with `actions` clause
4. **Object:** Inherited from parent
5. **Actor:** Can be narrowed from parent actor (validated for subset relationship)

**Example 1: Simple Exception (Nemo Dat / Bona Fide)**
```markdown
### Base Rule (depth 0)
*Transferor* **has no right to** *transfer* *Property* from *Transferee*

### Exception (depth 1)
excepts #base-rule
*bona_fide_purchaser* → is entitled to receive
```

**Transpiler generates:**
```lean4
-- Depth 0: NoRight (explicit)
def base_rule (transferor : Quantifier) (transferee : Quantifier) : Prop :=
  holds NoRight transferor transfer Property transferee

-- Depth 1: Right (auto-computed: O_pos(NoRight))
def exception_rule (purchaser : Quantifier) (transferor : Quantifier) : Prop :=
  bona_fide_purchaser purchaser →
  holds Right purchaser receive Property transferor
```

**Example 2: Action Filtering**
```markdown
### Base Grant (depth 0)
*Licensee* **has privilege to** *use*, *copy*, *distribute*, *sell* *the Software*

### Commercial Restriction (depth 1)
excepts #base-grant
actions *sell*
*NonCommercialUser* → cannot sell
```

**Transpiler generates:**
```lean4
-- Base rule: all four actions with Privilege
-- Exception: only "sell" action with NoRight
-- Result: NonCommercialUser can use, copy, distribute but not sell
```

**Example 3: Exception to Exception (depth 2)**
```markdown
### Base Rule (depth 0)
*Transferor* **has no right to** *transfer* *Property*

### Bona Fide Exception (depth 1)
excepts #base-rule
*bona_fide_purchaser* → is entitled to receive

### Fraudulent Transferor (depth 2)
excepts #bona-fide-exception
*fraudulent_transferor* → has no right to transfer
```

**Transpiler generates:**
```lean4
-- Depth 0: NoRight (explicit)
-- Depth 1: Right (odd → O_pos(NoRight))
-- Depth 2: NoRight (even → same as depth 0)
```

**Why exceptions are simpler:**

Writing exceptions without H-keywords is syntactic sugar that reduces cognitive load:
- Drafter doesn't need to compute O_pos manually
- Drafter doesn't need to track depth parity
- The transpiler handles the formal logic automatically
- The hierarchy structure remains clear and readable

**See §5 for complete semantics** of depth calculation, position flipping, and defeasibility resolution.

---

### 4.10.1 Exception Syntax - Complete Specification

**CRITICAL:** Exceptions use a simplified syntax where most elements are inherited from the parent rule.

#### What Must Be Written

```markdown
### Exception Title
excepts #parent-rule-id
[optional: actions *action1*, *action2*]
*narrowed-actor*
[optional: when *additional-condition*]
```

**That's it.** No H-keyword, no actions (unless filtering), no object, no preposition, no counterparty.

#### What Is Automatically Inherited

1. **Actions** - Copied from parent (unless filtered with `actions` clause)
2. **Object** - Copied from parent exactly
3. **Preposition** - Copied from parent exactly  
4. **Counterparty** - Copied from parent exactly
5. **Position** - Computed from depth: even→same, odd→O_pos(parent)

#### Surface Syntax Format

**Minimal exception (only actor):**
```markdown
### Bona Fide Exception
excepts #nemo-dat-rule
*bona_fide_purchaser*
```

**Exception with action filter:**
```markdown
### Commercial Restriction
excepts #base-grant
actions *sell*
*NonCommercialUser*
```

**Exception with additional condition:**
```markdown
### Conditional Exception
excepts #base-rule
*special_actor*
when *special_actor* has *met* *condition*
```

#### Complete Example with Inheritance

**Parent rule:**
```markdown
### Nemo Dat Rule (depth 0)
*Transferor* **has no right to** *transfer* *Property* from *Transferee*
```

**Exception rule:**
```markdown
### Bona Fide Exception (depth 1)
excepts #nemo-dat-rule
*bona_fide_purchaser*
```

**What the transpiler generates:**
```lean4
-- Exception inherits:
-- - Actions: transfer (from parent)
-- - Object: Property (from parent)
-- - Preposition: from (from parent)
-- - Counterparty: Transferee (from parent, but actor narrowed)
-- - Position: Right (computed: depth 1 is odd → O_pos(NoRight) = Right)

def bona_fide_exception (purchaser : Quantifier) (transferor : Quantifier) : Prop :=
  bona_fide_purchaser purchaser →
  holds Right purchaser transfer Property transferor
  -- Note: action is "transfer" (inherited), not "receive"
  -- The semantic difference is in the position (Right vs NoRight)
```

#### Grammar Rules

```pest
// Exception declaration
exception_rule = {
    exception_header ~
    excepts_clause ~
    action_filter? ~
    exception_actor ~
    condition?
}

excepts_clause = {
    "excepts" ~ " "+ ~ "#" ~ rule_id ~ NEWLINE
}

action_filter = {
    "actions" ~ " "+ ~ action_list ~ NEWLINE
}

exception_actor = {
    "*" ~ term_word ~ "*" ~ NEWLINE
}
```

#### Validation Rules

1. **Parent must exist** - `#parent-rule-id` must resolve to a valid rule
2. **Actor subsumption** - `child.actor ⊆ parent.actor` (checked via taxonomy)
3. **Action filter validity** - If specified, actions must be subset of parent actions
4. **No H-keyword allowed** - If H-keyword detected in exception → Error
5. **No duplicate inheritance** - Cannot specify object/preposition/counterparty explicitly

#### Common Mistakes

❌ **Incorrect: Writing full rule in exception**
```markdown
excepts #base-rule
*narrowed_actor* **has no right to** *action* *object*
```

✓ **Correct: Only actor**
```markdown
excepts #base-rule
*narrowed_actor*
```

❌ **Incorrect: Re-specifying inherited elements**
```markdown
excepts #base-rule
*narrowed_actor* *same-action* *same-object*
```

✓ **Correct: Actor only (inheritance is automatic)**
```markdown
excepts #base-rule
*narrowed_actor*
```

---

## 5. Exception Hierarchies (excepts)

### 5.1 Parent-Child Relationship

**Surface syntax:**
```markdown
### Child Rule
excepts #parent-rule
```

**Meaning:** This rule is an exception to the parent rule. It has higher priority in the defeasibility chain.

**Important: Exceptions are Syntactic Sugar**

Exceptions **do not require H-keywords** in the surface syntax. The transpiler automatically computes the position from:
1. The parent rule's position
2. The exception depth (parent.depth + 1)
3. Position flipping rule: odd depth → O_pos(parent.position)

This makes exceptions simpler to write - you only need to specify:
- `excepts #parent-rule` (which rule this excepts)
- Actor (often narrowed from parent)
- Actions (inherited or filtered from parent)
- Object (inherited from parent)
- Conditions/predicates (optional)

The transpiler reconstructs the full rule with the correct position automatically.

**Example:**
```markdown
### Base Rule (depth 0)
*Citizen* **has privilege to** *vote* *in elections*

### Exception (depth 1)
excepts #base-rule
*convicted_felon* → cannot vote
```

The drafter doesn't write `**has no right to**` explicitly - the transpiler knows:
- Parent has Privilege at depth 0
- Child at depth 1 (odd) → O_pos(Privilege) = NoRight
- Automatically generates: `holds NoRight convicted_felon vote elections AnyOne`

**Lean target:**
```lean4
def child_rule : Rule := {
  parent := some parent_rule,
  depth := parent_rule.depth + 1,
  position := computed_from_depth parent_rule.position,
  ...
}
```

---

### 5.2 Depth Calculation and Position Flipping

**Algorithm:**
```
child.depth = parent.depth + 1

if child.depth is even:
  child.position = parent.position
else:  -- odd depth
  child.position = O_pos(parent.position)
```

The `O_pos` operator is defined in Table 2 (Section 2.5). It flips the polarity while keeping subject and order unchanged.

**Example:**
```markdown
### Base Rule (depth 0)
*Transferor* **has no right to** *transfer* *Property* from *Transferee*

### Exception (depth 1)
excepts #base-rule
*bona_fide_purchaser* → is entitled to receive

### Exception to Exception (depth 2)
excepts #exception
*fraudulent_transferor* → has no right to transfer
```

**Transpiled positions:**
- Depth 0: NoRight (root position)
- Depth 1: Right (odd depth → O_pos(NoRight) = Right)
- Depth 2: NoRight (even depth → same as root)

---

### 5.3 Action Filtering

**Surface syntax:**
```markdown
### Exception
excepts #parent-rule
actions *action1*, *action2*
```

**Meaning:** This exception applies **only** to the specified actions from the parent rule.

**Example:**
```markdown
### Base Grant (depth 0)
*Licensee* **has privilege to** *use*, *copy*, *distribute*, *sell* *the Software*

### Commercial Restriction (depth 1)
excepts #base-grant
actions *sell*
*NonCommercialUser* → cannot sell
```

**Transpiles to:**
```lean4
-- Base rule applies to: use, copy, distribute, sell
-- Exception only affects: sell
-- Result: NonCommercialUser can use, copy, distribute but not sell
```

**Validation:** If `actions` is omitted, the exception applies to **all** parent actions.

---

### 5.4 Single Parent Constraint

**Critical constraint:** An exception can have **exactly one parent**. Multiple parents break the depth calculation and parity rule.

**Why this matters:**

The exception hierarchy forms a **tree structure**, not a directed acyclic graph (DAG). Each child has a single path to the root, which determines:
1. **Depth** — incremented by 1 from parent
2. **Position** — computed from depth parity
3. **Defeasibility order** — determined by depth

**Invalid: Multiple Parents**
```markdown
### Base Rule A
*Citizen* **has privilege to** *vote*

### Base Rule B  
*Person* **has privilege to** *travel*

### Invalid Exception
excepts #base-rule-a
excepts #base-rule-b   ← INVALID: second excepts clause
*Resident* → mixed rules
```

**Transpiler behavior:** If multiple `excepts` clauses are detected → **E031: Multiple parent rules specified. Exception must have exactly one parent.**

**Valid: Linear Chain**
```markdown
### Base (depth 0)
*Citizen* **has privilege to** *vote*

### Exception 1 (depth 1)
excepts #base
*convicted_felon* → depth = 0 + 1 = 1

### Exception 2 (depth 2)  
excepts #exception-1
*served_sentence* → depth = 1 + 1 = 2
```

**Parity calculation requires single parent:**
```
depth 0 → Privilege (even, root position)
depth 1 → Duty (odd, O_pos applied)
depth 2 → Privilege (even, back to root position)
```

With multiple parents, the parity rule becomes undefined. The transpiler **must reject** documents with multiple parent specifications.

---

### 5.5 Taxonomy-as-Types: Automatic Defeasibility Resolution

**Core Principle:** Defeasibility is **automatic** through the type system. The taxonomy defines type hierarchies, and more specific types naturally have higher priority through Lean's pattern matching.

#### 5.5.1 Taxonomy Generates Type Hierarchies

The Role taxonomy is not just metadata—it generates actual Lean type definitions with subset relationships:

**Taxonomy definition:**
```
Role/
├── Citizen
│   └── convicted_felon (subset of Citizen)
│       └── served_sentence (subset of convicted_felon)
```

**Generated Lean types:**
```lean4
-- Base quantifier
def Citizen : Quantifier := 
  fun (e : LegalEntity) => has_citizenship e

-- More specific: convicted_felon is a refinement of Citizen
def convicted_felon : Quantifier := 
  fun (e : LegalEntity) => Citizen e ∧ has_active_conviction e

-- Even more specific: served_sentence is a refinement of convicted_felon
def served_sentence : Quantifier := 
  fun (e : LegalEntity) => convicted_felon e ∧ sentence_completed e
```

**Key insight:** The taxonomy structure (`convicted_felon ⊆ Citizen`) is expressed through **logical conjunction** in the type definition. A person who satisfies `convicted_felon` automatically satisfies `Citizen`.

---

#### 5.5.2 Exception Depth Corresponds to Type Specificity

When you write exception hierarchies, the depth level corresponds directly to type specificity:

**Surface syntax:**
```markdown
### Base Rule (depth 0)
*Transferor* **has no right to** *transfer* *Property* from *Transferee*

### Bona Fide Exception (depth 1)
excepts #base-rule
*bona_fide_purchaser* → is entitled to receive

### Fraudulent Exception (depth 2)
excepts #bona-fide-exception
*fraudulent_transferor* → has no right to transfer
```

**Type specificity hierarchy:**
```
Transferee                    (depth 0, least specific)
  └─ bona_fide_purchaser     (depth 1, more specific)
      └─ fraudulent_transferor (depth 2, even more specific)
```

The transpiler **validates** that each exception uses a more specific quantifier:
- `bona_fide_purchaser ⊆ Transferee` ✓ valid
- `fraudulent_transferor ⊆ bona_fide_purchaser` ✓ valid

If an exception tries to use an incomparable or broader quantifier → **error or sorry stub**.

---

#### 5.5.3 Defeasibility Through Definitional Subsumption

**Correction from earlier discussion:** Defeasibility does NOT rely on pattern matching. It follows from two things working together:

1. **Depth encodes specificity** — higher depth = more specific rule
2. **Quantifier subsumption is definitional** — proved automatically by Lean from type definitions

**Key insight:** The taxonomy IS the Quantifier definition hierarchy. Not metadata. Not classification. The actual Lean type definitions.

**How subsumption works:**
```lean4
-- convicted_felon is DEFINED as a conjunction
def convicted_felon (e : LegalEntity) : Prop :=
  Citizen e ∧ has_active_conviction e

-- Subsumption is proved automatically from the definition
theorem felon_is_citizen : ∀ e, convicted_felon e → Citizen e := by
  intro e h
  exact h.1  -- Extract Citizen from conjunction - no pattern matching needed!
```

**Defeasibility resolver:**
```lean4
-- Individual rule definitions
def base_voting_rule (c : Quantifier) : Prop :=
  Citizen c → holds Privilege c vote elections AnyOne

def felon_restriction (f : Quantifier) : Prop :=
  convicted_felon f → holds NoRight f vote elections AnyOne

def restoration_rule (s : Quantifier) : Prop :=
  served_sentence s → holds Privilege s vote elections AnyOne

-- Defeasibility: check depth in reverse order (highest first)
def voting_rights (person : LegalEntity) : Prop :=
  if served_sentence person then
    -- Depth 2: most specific wins
    holds Privilege person vote elections AnyOne
  else if convicted_felon person then
    -- Depth 1: more specific than depth 0
    holds NoRight person vote elections AnyOne
  else if Citizen person then
    -- Depth 0: base case
    holds Privilege person vote elections AnyOne
  else
    false
```

**Why this is trustworthy:**
1. The `if-else` chain checks **depth order** (2 → 1 → 0)
2. Subsumption is **definitional**: `convicted_felon person` IMPLIES `Citizen person` by definition
3. Lean verifies this automatically — no axioms needed
4. The taxonomy definitions ARE the formal specification

**The key difference:** We don't rely on pattern matching to discover relationships. The relationships are **built into the type definitions** through logical conjunction.

---

#### 5.5.4 Transpiler Validation of Exception Quantifiers

During **Pass 3 (Tree Construction)**, the transpiler validates exception hierarchies:

**Validation algorithm:**
```rust
fn validate_exception_quantifier(
    parent: &Rule,
    child: &Rule,
    taxonomy: &Taxonomy
) -> Result<(), ValidationError> {
    // Check that child actor is subset of parent actor
    if !taxonomy.is_subset(child.actor, parent.actor) {
        if taxonomy.are_comparable(child.actor, parent.actor) {
            return Err("Exception actor must be subset of parent actor");
        } else {
            // Incomparable quantifiers - cannot determine subset relationship
            return Err("Cannot determine if exception actor is valid - sorry stub generated");
        }
    }
    Ok(())
}
```

**Example validation:**

✓ **Valid:**
```markdown
### Base: *Citizen* **has privilege to** *vote*
### Exception: *convicted_felon* 
```
Validation: `convicted_felon ⊆ Citizen` ✓

✗ **Invalid:**
```markdown
### Base: *Citizen* **has privilege to** *vote*
### Exception: *Resident*
```
Validation: `Resident ⊄ Citizen` and `Resident ⊈ Citizen` → **Error: incomparable quantifiers**

⚠️ **Warning (sorry stub):**
```markdown
### Base: *Person* **has privilege to** *travel*
### Exception: *dual_citizen*
```
Validation: Cannot determine if `dual_citizen ⊆ Person` from taxonomy → **Sorry stub with warning**

---

#### 5.5.5 Complete Working Example

**Taxonomy definition (in stdlib):**
```markdown
# Role Taxonomy

## Citizen
A person holding citizenship.

**Subtypes:**
- convicted_felon: Citizen with active criminal conviction
- registered_voter: Citizen who has completed voter registration

## convicted_felon
**Parent:** Citizen
A citizen with an active criminal conviction.

**Subtypes:**
- served_sentence: convicted_felon who has completed their sentence
```

**Generated Lean types:**
```lean4
-- From taxonomy
def Citizen (e : LegalEntity) : Prop :=
  has_citizenship e

def convicted_felon (e : LegalEntity) : Prop :=
  Citizen e ∧ has_active_conviction e

def served_sentence (e : LegalEntity) : Prop :=
  convicted_felon e ∧ sentence_completed e

-- Proof that subset relationships hold
theorem felon_is_citizen : ∀ e, convicted_felon e → Citizen e := by
  intro e h
  exact h.1  -- Extract Citizen from conjunction

theorem served_is_felon : ∀ e, served_sentence e → convicted_felon e := by
  intro e h
  exact h.1  -- Extract convicted_felon from conjunction
```

**OpenNorm rules:**
```markdown
### Citizen Voting Right
*Citizen* **has privilege to** *vote* *in elections* to *Government*

### Felon Disenfranchisement
excepts #citizen-voting-right
*convicted_felon* → cannot vote

### Sentence Served Restoration
excepts #felon-disenfranchisement
*served_sentence* → may vote again
```

**Generated defeasibility resolver:**
```lean4
def voting_rights (person : LegalEntity) : Prop :=
  -- Check most specific first (highest depth)
  if served_sentence person then
    -- Depth 2: restoration applies
    holds Privilege person vote elections Government
  else if convicted_felon person then
    -- Depth 1: disenfranchisement applies
    holds NoRight person vote elections Government
  else if Citizen person then
    -- Depth 0: base right applies
    holds Privilege person vote elections Government
  else
    -- Person is not a Citizen
    false

-- Example derivations
example (alice : LegalEntity) 
  (h1 : Citizen alice) 
  (h2 : ¬convicted_felon alice) : 
  voting_rights alice := by
  unfold voting_rights
  simp [h2]  -- not a felon, not served
  exact holds_privilege_citizen h1

example (bob : LegalEntity) 
  (h1 : convicted_felon bob) 
  (h2 : ¬served_sentence bob) : 
  ¬voting_rights bob := by
  unfold voting_rights
  simp [h2, h1]  -- felon but not served
  exact holds_noright_felon h1

example (carol : LegalEntity) 
  (h : served_sentence carol) : 
  voting_rights carol := by
  unfold voting_rights
  simp [h]  -- served sentence
  exact holds_privilege_served h
```

---

#### 5.5.6 Why This Approach Works

**Advantages of taxonomy-as-types:**

1. **Automatic validation** - Transpiler checks subset relationships during tree construction
2. **Type safety** - Lean's type system ensures defeasibility rules are sound
3. **No manual priority** - Depth = specificity, automatically enforced
4. **Clear semantics** - More specific types always defeat more general ones
5. **Composable** - Works with arbitrary taxonomy hierarchies

**Key principle:** The formal system mirrors the intuition. If `convicted_felon ⊆ Citizen` in the taxonomy, then a felon-specific rule naturally defeats a general citizen rule through the type system.

**No axioms needed** - The subset relationships are **definitional** (through conjunction in type definitions), not axiomatic. This makes the system more trustworthy and easier to verify.

---

## 6. Scenario Syntax

### 6.1 Scenarios vs Rules

**Rules** define what positions hold under various conditions.

**Scenarios** define:
1. **Facts** — what is assumed to be true (axioms)
2. **Questions** — what we want to verify

Scenarios test whether the rules produce the expected conclusions when applied to specific facts.

---

### 6.2 Scenario Structure

```markdown
# Manifest

**OpenNorm:** 0.1
**Package:** scenarios.name
**Package-type:** scenario
**Import:** /path/to/rules

## Scenario: Descriptive Name

**Facts:**
[fact statements]

**Questions:**
[query statements]
```

---

### 6.3 Fact Primitives

#### 6.3.1 isa (Type Assertion)

**Surface syntax:**
```markdown
*X* isa *Type*
```

**Lean target:**
```lean4
axiom fact_isa : Type (Only X)
```

**Meaning:** X satisfies Type. This is assumed true — no proof required.

**Usage:** For Object types and Role memberships.

**Example:**
```markdown
*the Software* isa *Software*
*Alice* isa *Licensor*
```

**Transpiles to:**
```lean4
axiom software_is_software : Software (Only the_software)
axiom alice_is_licensor : Licensor (Only Alice)
```

**Note:** LegalEntities are assumed by default. You don't need to declare `*Alice* isa *Person*` unless Alice is not obviously a LegalEntity.

---

#### 6.3.2 has (Past Event)

**Surface syntax:**
```markdown
*X* has *V* *O*
```

**Lean target:**
```lean4
axiom fact_has : holds Privilege (Only X) V O AnyOne
```

**Meaning:** X performed action V on object O in the past. This is assumed true.

**Example:**
```markdown
*Alice* has licensed *the Software* under *MIT*
*Bob* has obtained *the Software* from *Alice*
*Bob* has distributed *the Software*
```

**Transpiles to:**
```lean4
axiom alice_licensed : holds Privilege (Only Alice) license Software AnyOne
axiom bob_obtained : holds Privilege (Only Bob) obtain Software (Only Alice)
axiom bob_distributed : holds Privilege (Only Bob) distribute Software AnyOne
```

---

#### 6.3.3 has with Counterparty

**Surface syntax:**
```markdown
*X* has *V* *O* from/to/by *Y*
```

**Lean target:**
```lean4
axiom fact_has : holds Privilege (Only X) V O (Only Y)
```

**Example:**
```markdown
*Bob* has obtained *the Software* from *Alice*
```

**Transpiles to:**
```lean4
axiom bob_obtained_from_alice : holds Privilege (Only Bob) obtain Software (Only Alice)
```

---

#### 6.3.4 under (Constitutive Licensing Act)

**Surface syntax:**
```markdown
*X* has licensed *O* under *License*
```

**Lean target:**
```lean4
axiom fact_licensed : holds Power (Only X) license O AnyOne
axiom licensing_act : licensed_under X O License
```

**Meaning:** This is a **constitutive act** — an event that, when it occurs, makes X satisfy the Licensor Quantifier and activates the named License rule set.

**Constitutive Acts as Events (Not Axioms with Timing):**

The `licensed_under` predicate is an **event predicate**. When the event occurs (Alice chooses MIT), the constitutive consequence immediately follows: Alice becomes a Licensor. No explicit temporal marker is needed - it's simply: "this event happened, therefore this status now holds."

This is **instantaneous from a logical perspective** - the act of licensing constitutes the role. The framework axiom states:

```lean4
-- Framework axiom (not specific to any scenario)
axiom licensing_constitutes_licensor :
  ∀ (x : LegalEntities) (o : Object) (l : RuleId),
  licensed_under x o l →
  Licensor (Only x)  -- x now satisfies Licensor role
```

When we assert `licensed_under Alice Software MIT` in a scenario, the Licensor role immediately follows by this axiom.

**Example:**
```markdown
**Facts:**
*Alice* has licensed *the Software* under *MIT*
```

**Transpiles to:**
```lean4
axiom alice_is_licensor : holds Power (Only Alice) license Software AnyOne
axiom alice_licensed_under_mit : licensed_under Alice Software MIT

-- Immediate consequence (via framework axiom):
theorem alice_is_licensor_role : Licensor (Only Alice) := by
  apply licensing_constitutes_licensor
  exact alice_licensed_under_mit
```

**Event sequence in MIT example:**
1. Alice licenses the Software under MIT → Alice becomes Licensor (constitutive)
2. Bob obtains the Software from Alice → Bob becomes Licensee (constitutive)
3. Bob distributes the Software → notice obligation activates (conditional)

Each event is a logical predicate. The temporal aspect (when they occurred) can be optionally specified using `when` in scenario facts (see §6.5.2).

---

### 6.5.3 when Clause Implementation Phases

The `when` keyword serves different purposes in different contexts, with phased implementation:

#### MVP Implementation (Current)

**1. when in Rules - Logical Conditions ✅ IMPLEMENTED**

```markdown
*Actor* **H-keyword** *action* *object*
when *condition*
```

**Status:** Fully implemented in MVP
**Transpiles to:** Lean implication (→)
**Usage:** Conditional rules, obligations triggered by events

**Example:**
```markdown
*Licensee* **must** *include* *Notice*
when *Licensee* has *distributed* *Software*
```

Becomes:
```lean4
holds Privilege licensee distribute software AnyOne →
holds Duty licensee include notice AnyOne
```

**2. when in Scenarios - Event Assertions ✅ IMPLEMENTED**

```markdown
**Facts:**
*X* has *V* *O*
```

**Status:** Facts are asserted as axioms (implemented)
**Temporal ordering:** Not evaluated in MVP
**Usage:** Declare that events occurred

**Example:**
```markdown
*Bob* has obtained *Software* from *Alice*
```

Becomes:
```lean4
axiom bob_obtained : holds Privilege (Only Bob) obtain Software (Only Alice)
```

#### Post-MVP Implementation (Future)

**3. when in Scenarios - Temporal Ordering ⏳ RESERVED SYNTAX**

```markdown
**Facts:**
*X* has *V* *O*
when *timestamp* or *event-reference*
```

**Status:** Syntax is reserved but not evaluated
**Transpiler behavior:** Parses successfully, generates warning
**Usage:** Future temporal reasoning

**Example:**
```markdown
*Alice* has licensed *Software*
when 2024-01-01

*Bob* has obtained *Software*
when after:alice-licensing
```

**Future transpilation:**
```lean4
axiom alice_licensed : holds Privilege (Only Alice) license Software AnyOne
axiom alice_licensed_at : occurred_at alice_licensed (Date.mk 2024 1 1)

axiom bob_obtained : holds Privilege (Only Bob) obtain Software AnyOne
axiom bob_obtained_after : occurs_after bob_obtained alice_licensed
```

**Temporal primitives (reserved for post-MVP):**
```lean4
inductive TemporalRelation where
  | before  : TemporalRelation
  | after   : TemporalRelation
  | upon    : TemporalRelation
  | during  : TemporalRelation

-- Temporal ordering predicates (reserved)
axiom occurred_at : Prop → Timestamp → Prop
axiom occurs_after : Prop → Prop → Prop
axiom occurs_before : Prop → Prop → Prop
axiom occurs_during : Prop → TimeInterval → Prop
```

#### Implementation Guidelines

**For MVP transpiler:**
- ✅ Implement: `when` in rules as logical conditions
- ✅ Implement: Scenario facts as axiom assertions
- ⚠️ Parse but ignore: `when` with timestamps in scenario facts
- ⚠️ Generate warning: "W300: Temporal when clause in scenario fact - syntax reserved for post-MVP"

**For Post-MVP:**
- Evaluate temporal ordering in scenarios
- Support time-based queries ("Did X hold at time T?")
- Verify temporal consistency
- Enable event sequencing constraints

**Error codes:**
- **W300**: Temporal when in scenario fact (reserved syntax)
- **E300**: Invalid temporal reference (post-MVP)
- **E301**: Temporal contradiction (post-MVP)

#### Why This Phasing?

**MVP priorities:**
1. Core Hohfeldian positions ✅
2. Exception hierarchies ✅
3. Logical conditions ✅
4. Basic scenario evaluation ✅

**Post-MVP adds:**
1. Full temporal reasoning
2. Time-based queries
3. Event sequencing
4. Temporal consistency checking

The MIT license works perfectly in MVP without temporal evaluation - the facts are simply "these events occurred" without needing to reason about when or in what order (except via constitutive rules).

---

### 6.4 Question Primitives

#### 6.4.1 Does *X* isa *R* (Role Query)

**Surface syntax:**
```markdown
Does *X* isa *Role*
```

**Lean target:**
```lean4
query : Role (Only X)
```

**Meaning:** Derive whether X satisfies Role from the Facts and Rules.

**Example:**
```markdown
Does *Alice* isa *Licensor*
Does *Bob* isa *Licensee*
```

**Engine behavior:** Check if X has performed actions that constitute the Role, or if it was explicitly declared.

---

#### 6.4.2 Does *X* **H** *V* *O* (Position Query)

**Surface syntax:**
```markdown
Does *X* **H-keyword** *V* *O*
```

**Lean target:**
```lean4
query : holds H (Only X) V O AnyOne
```

**Meaning:** Evaluate whether the position holds based on Facts and Rules.

**Example:**
```markdown
Does *Bob* **has privilege to** distribute *the Software*
Does *Bob* **must** include *the Copyright Notice*
```

**Engine returns:**
- `HOLDS` — the position is derivable
- `DOES NOT HOLD` — the position is refuted
- `UNKNOWN` — insufficient information
- `CONTRADICTION` — conflicting rules

---

#### 6.4.3 Does *X* **H** *V* *O* to/from/by/over *Y*

**Surface syntax:**
```markdown
Does *X* **H-keyword** *V* *O* to/from/by/over *Y*
```

**Lean target:**
```lean4
query : holds H (Only X) V O (Only Y)
```

**Example:**
```markdown
Does *Alice* **has immunity from** claim *damages* by *Bob*
```

---

### 6.5 The Two Uses of `when` (MVP)

The keyword `when` has **two distinct uses** in OpenNorm, both essential for MVP:

#### 6.5.1 `when` in Rules (Logical Condition)

**Surface syntax:**
```markdown
*Actor* **H-keyword** *action* *object* to/from/by/over *Counterparty*
when *condition*
```

**Meaning:** The rule only applies when the condition is satisfied. This is a **logical condition**, not temporal ordering.

**Example:**
```markdown
*Licensee* **must** *include* *CopyrightNotice* to *AnyOne*
when *Licensee* has *distributed* *the Software*
```

**Lean target:**
```lean4
def notice_obligation (licensee : Quantifier) (sw : Software) : Prop :=
  holds Privilege licensee distribute sw AnyOne →
  holds Duty licensee include CopyrightNotice AnyOne
```

The `when` becomes an implication (→) in Lean: "if the condition holds, then the obligation holds."

---

#### 6.5.2 `when` in Scenarios (Temporal Predicate)

**Surface syntax:**
```markdown
**Facts:**
*X* has *V* *O*
when *timestamp* or *event-reference*
```

**Meaning:** Marks when an event occurred. This creates a **temporal predicate** for scenario evaluation.

**Example:**
```markdown
**Facts:**
*Alice* has licensed *the Software* under *MIT*
when *2024-01-01*

*Bob* has obtained *the Software* from *Alice*
when *after-alice-licensing*
```

**Lean target:**
```lean4
axiom alice_licensed : licensed_under Alice the_software MIT
axiom alice_licensed_at : occurred_at alice_licensed (Date.mk 2024 1 1)

axiom bob_obtained : holds Privilege (Only Bob) obtain the_software (Only Alice)
axiom bob_obtained_after : occurs_after bob_obtained alice_licensed
```

**Temporal relations (MVP):**
```lean4
inductive TemporalRelation where
  | before  : TemporalRelation
  | after   : TemporalRelation
  | upon    : TemporalRelation
  | during  : TemporalRelation

-- Temporal ordering predicate
axiom occurs_at : Prop → Timestamp → Prop
axiom occurs_after : Prop → Prop → Prop
axiom occurs_before : Prop → Prop → Prop
```

**Why this is MVP-essential:**

The MIT license depends on temporal events:
- When Alice licenses the Software under MIT → Alice **becomes** Licensor (constitutive event)
- When Bob obtains the Software → Bob **becomes** Licensee (constitutive event)
- When Bob distributes → notice obligation **activates** (conditional trigger)

These temporal relationships must be captured for proper scenario evaluation.

---

## 7. The Seven-Pass Transpiler Pipeline

### 7.1 Pipeline Overview

```
Input: document.md
         ↓
Pass 1: Taxonomy Resolution
         ↓
Pass 2: Rule Construction
         ↓
Pass 3: Tree Construction
         ↓
Pass 4: C-Correlative Generation
         ↓
Pass 5: Contradiction Detection
         ↓
Pass 6: Scenario Evaluation
         ↓
Pass 7: Output Generation
         ↓
Output: document.lean + report.md
```

---

### 7.2 Pass 1 — Taxonomy Resolution

**Purpose:** Resolve every `*italic*` term against all taxonomies.

**Taxonomies:**
1. LegalEntities
2. Role
3. Action
4. Object

**Algorithm:**
1. Extract all `*term*` markers from the document
2. For each term:
   - Search LegalEntities → if found, mark as LegalEntity
   - If not found, search Role → if found, mark as Role
   - If not found, search Action → if found, mark as Action
   - If not found, search Object → if found, mark as Object
   - If not found in any → **unresolved**

**Handling unresolved terms:**
- In **draft mode** → generate **sorry stub** with warning
- In **review/final mode** → generate **error**

**Output:** Term resolution table for Pass 2.

---

### 7.2.1 Taxonomy Resolution - Detailed Algorithm

**Critical principle:** Each term must be **unique across all taxonomies**. A term cannot exist in multiple taxonomies simultaneously.

#### Phase 1: Taxonomy Loading and Validation

Before resolving document terms, the transpiler validates taxonomies:

```rust
fn load_and_validate_taxonomies() -> Result<TaxonomySet, Error> {
    let mut legal_entities = load_taxonomy("LegalEntities")?;
    let mut roles = load_taxonomy("Role")?;
    let mut actions = load_taxonomy("Action")?;
    let mut objects = load_taxonomy("Object")?;
    
    // Check for duplicates across taxonomies
    let mut all_terms = HashSet::new();
    
    for term in legal_entities.all_terms() {
        if !all_terms.insert(term) {
            return Err(E101: "Term '{term}' appears in multiple taxonomies");
        }
    }
    
    // Repeat for roles, actions, objects...
    
    Ok(TaxonomySet { legal_entities, roles, actions, objects })
}
```

**Error E101:** Term exists in multiple taxonomies (ambiguous)

This validation ensures the resolution algorithm is deterministic.

#### Phase 2: Document Term Extraction

**Parse time - what happens during parsing:**

```rust
fn extract_terms_from_document(doc: &Document) -> Vec<(Term, Location)> {
    let mut terms = Vec::new();
    
    // Extract from rule lines
    for rule in doc.rules() {
        terms.push((rule.actor, rule.actor_location));
        for action in rule.actions {
            terms.push((action, action.location));
        }
        terms.push((rule.object, rule.object_location));
        terms.push((rule.counterparty, rule.counterparty_location));
    }
    
    // Extract from conditions
    for condition in doc.conditions() {
        terms.push((condition.subject, condition.subject_location));
        terms.push((condition.action, condition.action_location));
        terms.push((condition.object, condition.object_location));
    }
    
    // Extract from scenario facts
    for fact in doc.scenario_facts() {
        // ... extract terms from facts
    }
    
    terms
}
```

**Output:** List of (term, location) pairs for resolution.

#### Phase 3: Term Resolution Algorithm

**Check time - what happens during semantic analysis:**

```rust
fn resolve_term(term: &str, taxonomies: &TaxonomySet, mode: Mode) 
    -> Result<TermResolution, Error> {
    
    // Step 1: Try LegalEntities
    if let Some(entity) = taxonomies.legal_entities.lookup(term) {
        return Ok(TermResolution::LegalEntity {
            term: term.to_string(),
            entity,
            quantifier_form: QuantifierForm::Only, // Coerce via Only
        });
    }
    
    // Step 2: Try Role
    if let Some(role) = taxonomies.roles.lookup(term) {
        return Ok(TermResolution::Role {
            term: term.to_string(),
            role,
            quantifier_form: QuantifierForm::Direct, // Use directly
        });
    }
    
    // Step 3: Try Action
    if let Some(action) = taxonomies.actions.lookup(term) {
        return Ok(TermResolution::Action {
            term: term.to_string(),
            action,
        });
    }
    
    // Step 4: Try Object
    if let Some(object) = taxonomies.objects.lookup(term) {
        return Ok(TermResolution::Object {
            term: term.to_string(),
            object,
        });
    }
    
    // Step 5: Not found in any taxonomy
    match mode {
        Mode::Draft => {
            // Generate sorry stub with warning
            Ok(TermResolution::Unresolved {
                term: term.to_string(),
                sorry_stub: true,
                warning: format!("W200: Term '{}' not found in any taxonomy", term),
            })
        },
        Mode::Review | Mode::Final => {
            // Error and halt
            Err(E100: format!("Term '{}' not found in any taxonomy", term))
        }
    }
}
```

#### Phase 4: Quantifier Coercion

**Why coercion matters:**

```lean4
-- LegalEntity needs coercion
def Alice : LegalEntity := ...

-- In a rule, we need a Quantifier:
holds Privilege (Only Alice) use Software AnyOne
                 ↑ coercion via Only

-- Role is already a Quantifier:
def Licensee : Quantifier := ...
holds Privilege Licensee use Software AnyOne
                ↑ no coercion needed
```

**Coercion rules:**

| Taxonomy | Resolved Type | Quantifier Form | Example |
|---|---|---|---|
| LegalEntity | `LegalEntity` | `Only entity` | `Alice` → `Only Alice` |
| Role | `Quantifier` | Direct | `Licensee` → `Licensee` |
| Action | `Action` | N/A (not quantifier) | `distribute` → `distribute` |
| Object | `Object` | N/A (not quantifier) | `Software` → `Software` |

#### Phase 5: Resolution Context Validation

**Context-specific validation:**

```rust
fn validate_term_context(term: &str, resolution: &TermResolution, 
                         context: TermContext) -> Result<(), Error> {
    match (context, resolution) {
        // Actor position must be LegalEntity or Role
        (TermContext::Actor, TermResolution::LegalEntity(_)) => Ok(()),
        (TermContext::Actor, TermResolution::Role(_)) => Ok(()),
        (TermContext::Actor, _) => Err(E102: "Actor must be LegalEntity or Role"),
        
        // Action position must be Action
        (TermContext::Action, TermResolution::Action(_)) => Ok(()),
        (TermContext::Action, _) => Err(E103: "Expected Action, found {resolution.type_name()}"),
        
        // Object position must be Object
        (TermContext::Object, TermResolution::Object(_)) => Ok(()),
        (TermContext::Object, _) => Err(E104: "Expected Object, found {resolution.type_name()}"),
        
        // Counterparty must be LegalEntity or Role
        (TermContext::Counterparty, TermResolution::LegalEntity(_)) => Ok(()),
        (TermContext::Counterparty, TermResolution::Role(_)) => Ok(()),
        (TermContext::Counterparty, _) => Err(E105: "Counterparty must be LegalEntity or Role"),
    }
}
```

#### Complete Resolution Example

**Document term:**
```markdown
*Licensee* **must** *include* *the Copyright Notice* to *AnyOne*
```

**Resolution process:**

1. **Extract terms:**
   - `Licensee` (actor context)
   - `include` (action context)
   - `Copyright Notice` (object context)
   - `AnyOne` (counterparty context)

2. **Resolve each:**
   - `Licensee` → Try LegalEntities ❌ → Try Role ✓ → `TermResolution::Role`
   - `include` → Try LegalEntities ❌ → Try Role ❌ → Try Action ✓ → `TermResolution::Action`
   - `Copyright Notice` → ... → Try Object ✓ → `TermResolution::Object`
   - `AnyOne` → Try Role ✓ → `TermResolution::Role`

3. **Validate contexts:**
   - Actor=Role ✓
   - Action=Action ✓
   - Object=Object ✓
   - Counterparty=Role ✓

4. **Generate Lean:**
   ```lean4
   holds Duty Licensee include CopyrightNotice AnyOne
   -- Note: No "Only" for Licensee or AnyOne (they're Roles)
   ```

#### Error Codes Summary

| Code | Error | Resolution |
|---|---|---|
| **E100** | Term not found in any taxonomy | Add term to appropriate taxonomy or fix spelling |
| **E101** | Term appears in multiple taxonomies | Remove duplicate from one taxonomy |
| **E102** | Actor must be LegalEntity or Role | Use correct term type in actor position |
| **E103** | Expected Action in action position | Use Action taxonomy term |
| **E104** | Expected Object in object position | Use Object taxonomy term |
| **E105** | Counterparty must be LegalEntity or Role | Use correct term type in counterparty position |
| **W200** | Term unresolved (draft mode) | Add to taxonomy before moving to review |

#### Implementation Notes

**Performance optimization:**
- Build term lookup tables at taxonomy load time
- Cache resolutions for repeated terms
- Fail fast on first ambiguous term

**Debugging support:**
- Log each resolution step
- Report term location in source document
- Suggest similar terms if not found

---

### 7.3 Pass 2 — Rule Construction

**Purpose:** Convert each rule section into a structured Rule object.

**Algorithm:**
1. Extract title → generate RuleId
2. Extract description → convert to Lean comment
3. Extract H-keyword → determine Position
4. Extract actor, actions, object, counterparty
5. Extract `when` clause → build condition Prop
6. Validate preposition matches Position
7. Generate `holds()` signature for each action

**Output:** List of Rule objects.

**Example:**
```rust
struct Rule {
    id: RuleId,
    description: Option<String>,
    position: Position,
    actor: Quantifier,
    actions: Vec<Action>,
    object: Object,
    counterparty: Quantifier,
    condition: Option<Prop>,
    parent: Option<RuleId>,
    depth: usize,
}
```

---

### 7.4 Pass 3 — Tree Construction

**Purpose:** Build exception hierarchies and compute depth-based position flipping.

**Algorithm:**
1. Identify root rules (no `excepts` clause) → depth = 0
2. For each rule with `excepts #parent`:
   - Lookup parent rule
   - Set `depth = parent.depth + 1`
   - Compute position:
     - If depth is even → position = root_position
     - If depth is odd → position = O_pos(root_position)
3. Apply action filter if specified
4. Check Quantifier containment: `child.actor ⊆ parent.actor`
   - If incomparable → **sorry stub with warning**

**Output:** Tree of Rules with computed depths and positions.

**Example tree:**
```
#nemo-dat (depth 0, NoRight)
  └─ #bona-fide (depth 1, Right)  [O_pos(NoRight)]
      └─ #fraudulent (depth 2, NoRight)  [same as depth 0]
```

---

### 7.5 Pass 4 — C-Correlative Generation

**Purpose:** For every position held by actor A against counterparty B, generate the correlative position held by B against A.

**Correlative pairs:**
- Privilege(A → B) ⟺ NoRight(B → A)
- Duty(A → B) ⟺ Right(B → A)
- Right(A → B) ⟺ Duty(B → A)
- NoRight(A → B) ⟺ Privilege(B → A)
- Power(A → B) ⟺ Liability(B → A)
- Disability(A → B) ⟺ Immunity(B → A)
- Immunity(A → B) ⟺ Disability(B → A)

**Algorithm:**
1. For each Rule R:
   - Generate correlative position C_pos(R.position)
   - Swap actor and counterparty
   - Insert into correlative tree at same depth

**Output:** Expanded rule set with correlatives.

**Example:**
```markdown
### Base Grant
*Licensee* **has privilege to** *use*, *copy*, *distribute*, *sell* *the Software*

### Commercial Restriction
excepts #base-grant
actions *sell*
*NonCommercialUser* **has no right to** *sell* *the Software*
```
**Example:**
```markdown
*Licensor* **has privilege to** *distribute* *the Software* to *Licensee*
```
Generates:
```lean4
holds Privilege (Only Licensor) distribute Software (Only Licensee)
-- C-correlative:
holds NoRight (Only Licensee) (prevent distribute) Software (Only Licensor)
```

---

### 7.5.1 Correlative Generation - Edge Cases

**Purpose:** Handle special cases in correlative generation that require careful consideration.

#### Edge Case 1: AnyOne as Counterparty

**Question:** When counterparty is `AnyOne` (universal quantifier), should correlatives be generated?

**Example:**
```markdown
*Licensor* **has privilege to** *distribute* *the Software* to *AnyOne*
```

**Naive correlative generation:**
```lean4
holds Privilege Licensor distribute Software AnyOne

-- C-correlative:
holds NoRight AnyOne (prevent_distribute) Software Licensor
```

**Issue:** This generates a correlative for the universal quantifier `AnyOne`, which is semantically correct but potentially redundant (everyone has NoRight to prevent).

**Transpiler behavior:**

**Option A: Generate all correlatives (recommended for MVP)**
```lean4
-- Always generate correlatives, even for AnyOne
theorem grant_correlative : 
  holds Privilege Licensor distribute Software AnyOne →
  holds NoRight AnyOne (prevent_distribute) Software Licensor := by
  intro h
  exact correlative_privilege_noright h
```

**Why:** Mathematically complete, semantically correct, proves the Hohfeldian structure holds even for universal quantifiers.

**Option B: Skip AnyOne correlatives (optimization for post-MVP)**
```rust
fn should_generate_correlative(counterparty: &Quantifier) -> bool {
    match counterparty {
        Quantifier::AnyOne => false,  // Skip universal quantifier
        _ => true
    }
}
```

**Why:** Reduces generated code size, correlatives for AnyOne are usually implied.

**MVP Recommendation:** Use Option A (generate all). Completeness over optimization.

---

#### Edge Case 2: Self-Referential Positions

**Question:** What if actor and counterparty are the same quantifier?

**Example:**
```markdown
*Person* **has privilege to** *defend* *themselves* from *Person*
```

**Transpiles to:**
```lean4
holds Privilege Person defend Self Person
```

**Issue:** Actor and counterparty are both `Person`. Does the correlative make sense?

**C-correlative would be:**
```lean4
holds NoRight Person (prevent_defend) Self Person
```

**This means:** "Person has NoRight to prevent Person from defending Self" - which is logically sound (you can't prevent yourself from self-defense).

**Transpiler behavior:**

**Option A: Generate correlative (recommended)**
```lean4
-- Even for self-referential positions, generate correlative
theorem self_defense_correlative :
  holds Privilege Person defend Self Person →
  holds NoRight Person (prevent_defend) Self Person := by
  intro h
  exact correlative_privilege_noright h
```

**Why:** The correlative is still mathematically valid. "You cannot prevent yourself from defending yourself" is a tautology but not incorrect.

**Option B: Detect and skip self-referential correlatives**
```rust
fn should_generate_correlative(actor: &Quantifier, counterparty: &Quantifier) -> bool {
    if actor == counterparty {
        return false;  // Skip self-referential
    }
    true
}
```

**Why:** Avoids generating tautological statements.

**MVP Recommendation:** Use Option A. Let Lean's type system handle tautologies naturally.

---

#### Edge Case 3: Exception Correlatives

**Question:** Should correlatives be generated for exception rules?

**Example:**
```markdown
### Base Rule (depth 0)
*Transferor* **has no right to** *transfer* *Property* from *Transferee*

### Exception (depth 1)
excepts #base-rule
*bona_fide_purchaser* **has right to** *receive* *Property*
```

**Base correlative:**
```lean4
holds NoRight Transferor transfer Property Transferee
-- C-correlative:
holds Privilege Transferee (refuse_transfer) Property Transferor
```

**Exception correlative:**
```lean4
holds Right bona_fide_purchaser receive Property Transferor
-- C-correlative:
holds Duty Transferor (deliver) Property bona_fide_purchaser
```

**Transpiler behavior:**

**Correct approach: Generate correlatives at every depth**

```lean4
-- Depth 0 correlative
theorem base_correlative :
  holds NoRight Transferor transfer Property Transferee →
  holds Privilege Transferee refuse_transfer Property Transferor := by
  exact correlative_noright_privilege

-- Depth 1 correlative (exception)
theorem exception_correlative :
  holds Right bona_fide_purchaser receive Property Transferor →
  holds Duty Transferor deliver Property bona_fide_purchaser := by
  exact correlative_right_duty
```

**Why:** Exceptions create new legal relationships. Each relationship has a correlative. The exception at depth 1 doesn't cancel the base correlative at depth 0 - both coexist for different actors.

**Key insight:** Correlatives are **per-rule**, not per-tree. Each rule at each depth generates its own correlative. The defeasibility resolver determines which rule applies to which actor.

---

#### Edge Case 4: Multiple Actions with Correlatives

**Question:** When a rule has multiple actions, how are correlatives generated?

**Example:**
```markdown
*Licensor* **has privilege to** *use*, *copy*, *distribute* *the Software* to *AnyOne*
```

**Transpiles to:**
```lean4
holds Privilege Licensor use Software AnyOne ∧
holds Privilege Licensor copy Software AnyOne ∧
holds Privilege Licensor distribute Software AnyOne
```

**Correlatives:**
```lean4
-- Each action gets its own correlative
theorem use_correlative :
  holds Privilege Licensor use Software AnyOne →
  holds NoRight AnyOne prevent_use Software Licensor := by
  exact correlative_privilege_noright

theorem copy_correlative :
  holds Privilege Licensor copy Software AnyOne →
  holds NoRight AnyOne prevent_copy Software Licensor := by
  exact correlative_privilege_noright

theorem distribute_correlative :
  holds Privilege Licensor distribute Software AnyOne →
  holds NoRight AnyOne prevent_distribute Software Licensor := by
  exact correlative_privilege_noright
```

**Transpiler behavior:** Generate one correlative per action. Each action creates an independent legal relationship with its own correlative.

---

#### Edge Case 5: Conditional Rules

**Question:** Do correlatives apply before or after the condition is satisfied?

**Example:**
```markdown
Does *Bob* **has privilege to** distribute *the Software*
Does *Bob* **must** include *the Copyright Notice*
```

**Transpiles to:**
```lean4
holds Privilege Licensee distribute Software AnyOne →
holds Duty Licensee include Notice AnyOne
```

**Correlative:**
```lean4
theorem notice_correlative :
  (holds Privilege Licensee distribute Software AnyOne →
   holds Duty Licensee include Notice AnyOne) →
  (holds Privilege Licensee distribute Software AnyOne →
   holds Right AnyOne demand_include Notice Licensee) := by
  intro h dist
  exact correlative_duty_right (h dist)
```

**Key insight:** The correlative applies **after** the condition is satisfied. The conditional structure is preserved:

```
If condition then Duty
↓ (correlative)
If condition then Right
```

Both the Duty and its correlative Right are conditional.

---

#### Summary: Edge Case Handling

| Edge Case | MVP Behavior | Rationale |
|---|---|---|
| AnyOne counterparty | Generate correlative | Mathematical completeness |
| Self-referential | Generate correlative | Let Lean handle tautologies |
| Exception rules | Generate at every depth | Each depth = independent relationship |
| Multiple actions | One correlative per action | Each action = independent relationship |
| Conditional rules | Preserve condition in correlative | Condition applies to both sides |

**Implementation guideline:** When in doubt, generate the correlative. Lean's type system will catch logical issues. Completeness is more important than optimization for MVP.

---

### 7.6 Pass 5 — Contradiction Detection

**Purpose:** Detect when the same actor has contradictory positions on the same action toward the same object at the same depth.

**Contradiction definition:**
```
H(actor, action, object, counterparty, depth) ∧
O_pos(H)(actor, action, object, counterparty, depth)
```

**Common contradictions:**
- Privilege ∧ NoRight (may and has no right to)
- Duty ∧ Right (must and is entitled to — same actor, problematic)
- Power ∧ Disability (can and cannot)

**Algorithm:**
1. For each (actor, action, object, counterparty, depth) tuple:
   - Collect all positions held
   - Check if any position P and O_pos(P) both present
   - If found → **CONTRADICTION — reject document**

**Output:** Contradiction report or validation success.

**Example contradiction:**
```markdown
### Grant
*Licensee* **has privilege to** *distribute* *the Software*

### Restriction
*Licensee* **has no right to** *distribute* *the Software*
```
Same depth (both root), same actor, same action, same object → **E030: CONTRADICTION**.

---

### 7.7 Pass 6 — Scenario Evaluation

**Purpose:** Evaluate scenario questions against facts and rules.

**Algorithm:**
1. Load all `isa` facts → assert as axioms
2. Load all `has` facts → generate `holds Privilege` axioms
3. Load all `under` facts → generate `holds Power` and `licensed_under` axioms
4. Derive Role memberships from constitutive acts
5. For each Question:
   - If `Does X isa R` → check Role derivation
   - If `Does X H V O` → check if `holds H X V O AnyOne` is derivable
6. Return: HOLDS | DOES NOT HOLD | UNKNOWN | CONTRADICTION

**Output:** Scenario evaluation report.

---

### 7.8 Pass 7 — Output Generation

**Purpose:** Generate Lean 4 files and human-readable report.

**Outputs:**
1. **preamble.lean** — framework axioms
2. **definitions.lean** — term types and axioms
3. **document.lean** — rule `holds()` statements
4. **report.md** — human-readable verification report

**Report sections:**
- Summary statistics
- Resolved terms
- Fuzzy terms (with review triggers)
- Contradictions (if any)
- Sorry stub inventory
- Scenario evaluation results
- Recommendations

---

## 8. Lean Code Generation Patterns

### 8.1 Basic Rule Translation

**Surface syntax:**
```markdown
### Grant
*Licensee* **has privilege to** *use* *the Software* to *AnyOne*
```

**Generated Lean:**
```lean4
-- Rule: #grant
-- Position: Privilege
def grant_rule (licensee : Quantifier) (sw : Software) : Prop :=
  holds Privilege licensee use sw AnyOne

-- Automatically generated correlative:
theorem grant_correlative (licensee : Quantifier) (sw : Software) :
  grant_rule licensee sw →
  holds NoRight AnyOne (prevent use) sw licensee := by
  intro h
  exact correlative_privilege_noright h
```

---

### 8.2 Rule with Condition

**Surface syntax:**
```markdown
### Notice Obligation
*Licensee* **must** *include* *CopyrightNotice* to *AnyOne*
when *Licensee* has *distributed* *the Software*
```

**Generated Lean:**
```lean4
def notice_obligation (licensee : Quantifier) (sw : Software) : Prop :=
  holds Privilege licensee distribute sw AnyOne →
  holds Duty licensee include CopyrightNotice AnyOne

-- If licensee distributes, then licensee must include notice
```

---

### 8.3 Multiple Actions

**Surface syntax:**
```markdown
*Licensee* **has privilege to** *use*, *copy*, *distribute* *the Software*
```

**Generated Lean:**
```lean4
def grant_rule (licensee : Quantifier) (sw : Software) : Prop :=
  holds Privilege licensee use sw AnyOne ∧
  holds Privilege licensee copy sw AnyOne ∧
  holds Privilege licensee distribute sw AnyOne
```

---

### 8.4 Exception Hierarchy

**Surface syntax:**
```markdown
### Base Rule
*Transferor* **has no right to** *transfer* *Property*

### Exception
excepts #base-rule
*bona_fide_purchaser* **has right to** *receive* *Property*
```

**Generated Lean:**
```lean4
-- Depth 0 (root)
def base_rule (transferor : Quantifier) (transferee : Quantifier) : Prop :=
  holds NoRight transferor transfer Property transferee

-- Depth 1 (exception, position flipped)
def exception_rule (purchaser : Quantifier) (transferor : Quantifier) : Prop :=
  bona_fide_purchaser purchaser →
  holds Right purchaser receive Property transferor

-- Defeasibility resolution
def transfer_rights (person : Quantifier) (other : Quantifier) : Prop :=
  if bona_fide_purchaser person then
    exception_rule person other  -- depth 1 wins
  else
    base_rule person other  -- depth 0 applies
```

---

### 8.5 Fuzzy Terms → sorry Stubs

**Surface syntax (in Known Ambiguities):**
```markdown
- **substantial_portions** — no threshold defined
  **Review trigger:** contested in legal proceedings
```

**Generated Lean:**
```lean4
-- Fuzzy term: substantial_portions
-- Declared in MIT § Known Ambiguities
-- Review trigger: contested in legal proceedings
def substantial_portions_threshold : ℕ := by
  sorry  -- intentional flexibility, no formal definition

-- Usage in obligation:
def notice_obligation (licensee : Quantifier) (sw : Software) (portions : ℕ) : Prop :=
  portions ≥ substantial_portions_threshold →
  holds Duty licensee include CopyrightNotice AnyOne
```

**Sorry inventory entry:**
```
| Sorry | Plain Language | Human Action Required |
|-------|----------------|----------------------|
| `substantial_portions_threshold` | What percentage triggers notice obligation? | Legal judgment at dispute. Review trigger: contested in legal proceedings. |
```

---

## 9. Complete Example: MIT License

### 9.1 Source Document (mit.strict.md)

```markdown
# MIT License

**OpenNorm:** 0.1
**Package:** MIT
**Package-type:** ruling
**Version:** 2.0
**Status:** review
**Imports:**
- stdlib/frameworks/universal/core@2.0

---

### MIT Grant

> The licensor grants broad permissions to any recipient.
> [MIT License](https://opensource.org/licenses/MIT)

*Licensor* **has privilege to** *use*, *copy*, *modify*, *merge*,
  *publish*, *distribute*, *sublicense*, *sell*
  *the Software* to *AnyOne*
when *AnyOne* has *obtained* *the Software*

### MIT Notice Obligation

*Licensee* **must** *include* *the Copyright Notice* to *AnyOne*
when *Licensee* has *distributed* *the Software*

### MIT No Warranty

*Licensor* **has no right to** *warrant* *the Software* from *Licensee*

### MIT No Liability

*Licensor* **has immunity from** *claim* *damages* by *AnyOne*
when *AnyOne* has *used* *the Software*

### MIT Irrevocability

*Licensor* **has no power to** *revoke* *the License* over *Licensee*
when *Licensee* has *obtained* *the Software*
```

---

### 9.2 Generated Lean Code

```lean4
-- Transpiled from mit.strict.md
-- OpenNorm 2.0 Hohfeldian Syntax

import stdlib.frameworks.universal.core

namespace MIT

-- Rule: #mit-grant
-- Position: Privilege (First-order, Counterparty, Negative)
-- External: MIT License - https://opensource.org/licenses/MIT
def grant (licensor : Quantifier) (recipient : Quantifier) (sw : Software) : Prop :=
  holds Privilege recipient obtain sw licensor →
  (holds Privilege licensor use sw recipient ∧
   holds Privilege licensor copy sw recipient ∧
   holds Privilege licensor modify sw recipient ∧
   holds Privilege licensor merge sw recipient ∧
   holds Privilege licensor publish sw recipient ∧
   holds Privilege licensor distribute sw recipient ∧
   holds Privilege licensor sublicense sw recipient ∧
   holds Privilege licensor sell sw recipient)

-- Correlatives (auto-generated)
theorem grant_correlative_use (l : Quantifier) (r : Quantifier) (sw : Software) :
  grant l r sw →
  holds NoRight r (prevent use) sw l := by
  intro h
  exact correlative_privilege_noright (h.1)

-- [Similar correlatives for copy, modify, etc.]

-- Rule: #mit-notice-obligation
-- Position: Duty (First-order, Counterparty, Positive)
def notice_obligation (licensee : Quantifier) (sw : Software) : Prop :=
  holds Privilege licensee distribute sw AnyOne →
  holds Duty licensee include CopyrightNotice AnyOne

-- Correlative (auto-generated)
theorem notice_correlative (licensee : Quantifier) (sw : Software) :
  notice_obligation licensee sw →
  holds Right AnyOne (demand include) CopyrightNotice licensee := by
  intro h
  exact correlative_duty_right h

-- Rule: #mit-no-warranty
-- Position: NoRight (First-order, Holder, Negative)
def no_warranty (licensor : Quantifier) (licensee : Quantifier) (sw : Software) : Prop :=
  holds NoRight licensor warrant sw licensee

-- Correlative (auto-generated)
theorem no_warranty_correlative (licensor : Quantifier) (licensee : Quantifier) (sw : Software) :
  no_warranty licensor licensee sw →
  holds Privilege licensee (refuse warranty) sw licensor := by
  intro h
  exact correlative_noright_privilege h

-- Rule: #mit-no-liability
-- Position: Immunity (Second-order, Counterparty, Negative)
def no_liability (licensor : Quantifier) (user : Quantifier) (sw : Software) : Prop :=
  holds Privilege user use sw AnyOne →
  holds Immunity licensor claim_damages user

-- Correlative (auto-generated)
theorem no_liability_correlative (licensor : Quantifier) (user : Quantifier) (sw : Software) :
  no_liability licensor user sw →
  holds Disability user claim_damages licensor := by
  intro h
  exact correlative_immunity_disability h

-- Rule: #mit-irrevocability
-- Position: Disability (Second-order, Holder, Negative)
def irrevocability (licensor : Quantifier) (licensee : Quantifier) (sw : Software) : Prop :=
  holds Privilege licensee obtain sw licensor →
  holds Disability licensor revoke License licensee

-- Correlative (auto-generated)
theorem irrevocability_correlative (licensor : Quantifier) (licensee : Quantifier) (sw : Software) :
  irrevocability licensor licensee sw →
  holds Immunity licensee revoke License licensor := by
  intro h
  exact correlative_disability_immunity h

-- Consistency check: no contradictions
theorem no_contradictions : ∀ (l r : Quantifier) (sw : Software),
  ¬(grant l r sw ∧ ¬(grant l r sw)) := by
  intro l r sw
  exact deontic_consistency

end MIT
```

---

### 9.3 Scenario Example (mit.scenarios.md)

```markdown
## Scenario: Bob Distributes Without Notice

**Facts:**
*the Software* isa *Software*
*Alice* has licensed *the Software* under *MIT*
*Bob* has obtained *the Software* from *Alice*
*Bob* has distributed *the Software*

**Questions:**
Does *Alice* isa *Licensor*
Does *Bob* isa *Licensee*
Does *Bob* **has privilege to** distribute *the Software*
Does *Bob* **must** include *the Copyright Notice*
Does *Alice* **has immunity from** claim *damages*
```

---

### 9.4 Generated Scenario Evaluation

```lean4
-- Scenario: Bob Distributes Without Notice

-- Facts (axioms)
axiom software_is_software : Software (Only the_software)
axiom alice_licensed : licensed_under Alice the_software MIT
axiom bob_obtained : holds Privilege (Only Bob) obtain the_software (Only Alice)
axiom bob_distributed : holds Privilege (Only Bob) distribute the_software AnyOne

-- Role derivation
theorem alice_is_licensor : Licensor (Only Alice) := by
  apply licensing_constitutes_licensor
  exact alice_licensed

theorem bob_is_licensee : Licensee (Only Bob) := by
  apply obtained_constitutes_licensee
  exact bob_obtained

-- Query 1: Does Bob may distribute?
theorem bob_may_distribute : holds Privilege (Only Bob) distribute the_software AnyOne := by
  apply MIT.grant
  exact bob_obtained

-- Result: HOLDS ✓

-- Query 2: Does Bob must include notice?
theorem bob_must_include_notice : holds Duty (Only Bob) include CopyrightNotice AnyOne := by
  apply MIT.notice_obligation
  exact bob_distributed

-- Result: HOLDS ✓

-- Query 3: Does Alice is protected from claim damages?
theorem alice_protected : holds Immunity (Only Alice) claim_damages (Only Bob) := by
  apply MIT.no_liability
  sorry  -- Bob has used, but we only have "distributed" fact
        -- Need either: (1) distribute implies use, or (2) explicit use fact

-- Result: UNKNOWN (insufficient facts)
```

---

### 9.5 Verification Report

```markdown
# OpenNorm Verification Report

**Document:** MIT License
**Version:** 2.0
**Checked:** 2026-03-12T11:00:00Z
**OpenNorm:** 2.0
**Result:** ✅ VALID

---

## Summary

| Category | Count |
|---|---|
| ✅ Rules transpiled | 5 |
| ✅ Correlatives generated | 5 |
| ✅ Contradictions detected | 0 |
| ⚠️ Sorry stubs | 0 |
| ✅ Scenario queries | 5 |
| ✅ HOLDS | 4 |
| ⚠️ UNKNOWN | 1 |

---

## Rules

### #mit-grant (depth 0)
- **Position:** Privilege
- **Actor:** Licensor
- **Actions:** use, copy, modify, merge, publish, distribute, sublicense, sell
- **Object:** the Software
- **Counterparty:** AnyOne
- **Condition:** when AnyOne has obtained the Software
- **Correlative:** NoRight (AnyOne has no right to prevent Licensor from these actions)

### #mit-notice-obligation (depth 0)
- **Position:** Duty
- **Actor:** Licensee
- **Actions:** include
- **Object:** the Copyright Notice
- **Counterparty:** AnyOne
- **Condition:** when Licensee has distributed the Software
- **Correlative:** Right (AnyOne has right to demand Licensee include notice)

### #mit-no-warranty (depth 0)
- **Position:** NoRight
- **Actor:** Licensor
- **Actions:** warrant
- **Object:** the Software
- **Counterparty:** Licensee
- **Correlative:** Privilege (Licensee has privilege to refuse warranty)

### #mit-no-liability (depth 0)
- **Position:** Immunity
- **Actor:** Licensor
- **Actions:** claim damages
- **Counterparty:** AnyOne
- **Condition:** when AnyOne has used the Software
- **Correlative:** Disability (AnyOne has disability to claim damages from Licensor)

### #mit-irrevocability (depth 0)
- **Position:** Disability
- **Actor:** Licensor
- **Actions:** revoke
- **Object:** the License
- **Counterparty:** Licensee
- **Condition:** when Licensee has obtained the Software
- **Correlative:** Immunity (Licensee has immunity from Licensor revoking)

---

## Scenario Evaluation: Bob Distributes Without Notice

**Facts loaded:**
- the Software isa Software
- Alice has licensed the Software under MIT
- Bob has obtained the Software from Alice
- Bob has distributed the Software

**Query results:**

| Query | Result | Explanation |
|-------|--------|-------------|
| Does Alice isa Licensor | ✅ HOLDS | Derived from licensing_constitutes_licensor axiom |
| Does Bob isa Licensee | ✅ HOLDS | Derived from obtained_constitutes_licensee |
| Does Bob **has privilege to** distribute the Software | ✅ HOLDS | #mit-grant applies: Bob obtained → Bob may distribute |
| Does Bob **must** include the Copyright Notice | ✅ HOLDS | #mit-notice-obligation applies: Bob distributed → Bob must include notice |
| Does Alice **has immunity from** claim damages | ⚠️ UNKNOWN | Insufficient facts: need "Bob has used the Software" |

---

## Recommendations

1. **Scenario completeness:** To fully evaluate Alice's immunity from damages, add fact: `*Bob* has *used* *the Software*`

2. **Implicit action relationships:** Consider adding axiom: `distribute → use` (distribution implies use occurred)

---

*This report was generated by OpenNorm 2.0*
*The .md source document is the authoritative instrument.*
*Lean 4 output is a consistency verification aid.*
```

---

## 10. Grammar Extensions

### 10.1 Required pest Grammar Additions

The existing `opennorm.pest` grammar needs these extensions to support Hohfeldian syntax:

```pest
// ── H-Keywords (Hohfeldian Positions) ──────────────────────────
h_keyword = {
    "**has privilege to**" |
    "**must**" |
    "**has right to**" |
    "**has no right to**" |
    "**has power to**" |
    "**has no power to**" |
    "**is subject to**" |
    "**has immunity from**"
}

// ── Counterparty Prepositions ──────────────────────────────────
preposition = {
    "to" |
    "from" |
    "by" |
    "over"
}

// ── Rule Line (new format) ─────────────────────────────────────
rule_line = {
    actor ~ h_keyword ~ action_list ~ object ~ preposition ~ counterparty ~
    condition?
}

actor = { "*" ~ term_word ~ "*" }
action_list = { action ~ ("," ~ " "* ~ action)* }
action = { "*" ~ term_word ~ "*" }
object = { "*the " ~ term_word ~ "*" }
counterparty = { "*" ~ term_word ~ "*" }

// ── Conditions ─────────────────────────────────────────────────
condition = {
    "when" ~ " "+ ~ condition_subject ~ " "+ ~ "has" ~ " "+ ~
    condition_action ~ " "+ ~ condition_object ~ condition_counterparty?
}

condition_subject = { "*" ~ term_word ~ "*" }
condition_action = { "*" ~ term_word ~ "*" }
condition_object = { "*" ~ term_word ~ "*" }
condition_counterparty = { " "+ ~ preposition ~ " "+ ~ "*" ~ term_word ~ "*" }

// ── Exception Hierarchies ──────────────────────────────────────
excepts = {
    "excepts" ~ " "+ ~ "#" ~ rule_id
}

rule_id = @{ (ASCII_ALPHANUMERIC | "-")+ }

action_filter = {
    "actions" ~ " "+ ~ action_list
}

// ── Fuzzy Terms and Silence Annotations ───────────────────────
fuzzy_term = {
    "~~" ~ term_word ~ "~~"
}

silence_annotation = {
    "@silence"
}

// ── Scenario Blocks ────────────────────────────────────────────
scenario_section = {
    "##" ~ " "+ ~ "Scenario:" ~ " "+ ~ scenario_name ~ NEWLINE ~
    scenario_facts ~ scenario_questions
}

scenario_name = @{ (!NEWLINE ~ ANY)+ }

scenario_facts = {
    "Facts:" ~ NEWLINE ~ fact_statement+
}

scenario_questions = {
    "Questions:" ~ NEWLINE ~ question_statement+
}

// ── Fact Statements ────────────────────────────────────────────
fact_statement = {
    fact_isa | fact_has | fact_under
}

fact_isa = {
    "*" ~ term_word ~ "*" ~ " "+ ~ "isa" ~ " "+ ~ "*" ~ term_word ~ "*" ~ NEWLINE
}

fact_has = {
    "*" ~ term_word ~ "*" ~ " "+ ~ "has" ~ " "+ ~
    "*" ~ term_word ~ "*" ~ " "+ ~ "*" ~ term_word ~ "*" ~
    (preposition ~ " "+ ~ "*" ~ term_word ~ "*")? ~ NEWLINE
}

fact_under = {
    "*" ~ term_word ~ "*" ~ " "+ ~ "has licensed" ~ " "+ ~
    "*" ~ term_word ~ "*" ~ " "+ ~ "under" ~ " "+ ~ "*" ~ term_word ~ "*" ~ NEWLINE
}

// ── Question Statements ────────────────────────────────────────
question_statement = {
    question_isa | question_holds
}

question_isa = {
    "Does" ~ " "+ ~ "*" ~ term_word ~ "*" ~ " "+ ~ "isa" ~ " "+ ~
    "*" ~ term_word ~ "*" ~ NEWLINE
}

question_holds = {
    "Does" ~ " "+ ~ "*" ~ term_word ~ "*" ~ " "+ ~ h_keyword ~ " "+ ~
    "*" ~ term_word ~ "*" ~ " "+ ~ "*" ~ term_word ~ "*" ~
    (preposition ~ " "+ ~ "*" ~ term_word ~ "*")? ~ NEWLINE
}
```

---

### 10.2 AST Extensions

```rust
// New AST types for Hohfeldian syntax

#[derive(Debug, Clone, PartialEq)]
pub enum HKeyword {
    HasPrivilegeTo,     // Privilege
    Must,               // Duty
    HasRightTo,         // Right
    HasNoRightTo,       // NoRight
    HasPowerTo,         // Power
    HasNoPowerTo,       // Disability
    IsSubjectTo,        // Liability
    HasImmunityFrom,    // Immunity
}

#[derive(Debug, Clone, PartialEq)]
pub enum Preposition {
    To,
    From,
    By,
    Over,
}

#[derive(Debug, Clone)]
pub struct RuleLine {
    pub actor: Term,
    pub h_keyword: HKeyword,
    pub actions: Vec<Term>,
    pub object: Term,
    pub preposition: Preposition,
    pub counterparty: Term,
    pub condition: Option<Condition>,
}

#[derive(Debug, Clone)]
pub struct Condition {
    pub subject: Term,
    pub action: Term,
    pub object: Term,
    pub counterparty: Option<Term>,
}

#[derive(Debug, Clone)]
pub struct ExceptsClause {
    pub parent_rule_id: String,
    pub action_filter: Option<Vec<Term>>,
}

#[derive(Debug, Clone)]
pub enum FactStatement {
    Isa {
        entity: Term,
        entity_type: Term,
    },
    Has {
        subject: Term,
        action: Term,
        object: Term,
        counterparty: Option<Term>,
    },
    Under {
        licensor: Term,
        object: Term,
        license: Term,
    },
}

#[derive(Debug, Clone)]
pub enum QuestionStatement {
    Isa {
        entity: Term,
        role: Term,
    },
    Holds {
        actor: Term,
        h_keyword: HKeyword,
        action: Term,
        object: Term,
        counterparty: Option<Term>,
    },
}

#[derive(Debug, Clone)]
pub struct Scenario {
    pub name: String,
    pub facts: Vec<FactStatement>,
    pub questions: Vec<QuestionStatement>,
}
```

---

## Conclusion

This technical reference specifies the complete Hohfeldian syntax system for OpenNorm 2.0. All legal relationships are expressed through eight fundamental positions that transpile to the `holds()` predicate in Lean 4.

**Key takeaways:**

1. **Surface syntax → Lean mapping is deterministic** — every H-keyword has an exact Position representation
2. **Prepositions are semantic sugar** — they aid human readability but all map to counterparty
3. **Exception depth determines position flipping** — even depths preserve position, odd depths flip to opposite
4. **Correlatives are auto-generated** — every position implies its opposite for the counterparty
5. **Scenarios test derivation** — facts + rules → query evaluation
6. **Seven-pass pipeline** — taxonomy → construction → tree → correlatives → contradiction → evaluation → output

This system provides the formal foundation for machine-verifiable legal documents while maintaining human-readable surface syntax.

---

*OpenNorm 2.0 Hohfeldian Syntax Reference*
*Technical Specification for Transpiler Implementation*
*Version: 2.0.0*
*Last Updated: 2026-03-12*