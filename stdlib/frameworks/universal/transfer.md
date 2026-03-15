# Universal Transfer Framework

**OpenNorm:** 0.1
**Package:** universal.transfer
**Package-type:** stdlib
**Version:** 1.0
**Status:** stable

> Fundamental constraints on property transfer based on the nemo dat principle ("no one can give what they don't have") and its bona fide purchaser exception.

---

## Overview

This framework establishes the foundational rules for property transfer:

1. **Nemo Dat Rule** (root): You cannot transfer what you don't possess
2. **Bona Fide Exception** (depth 1): Good faith purchasers for value acquire valid title

These rules form a minimal exception hierarchy demonstrating:
- O_pos position flipping (NoRight → Right at odd depth)
- Taxonomy-based defeasibility (bona_fide_purchaser ⊆ Transferee)
- Practical legal reasoning through formal exception structure

---

## Rules

### Nemo Dat Rule

> No one can transfer better title than they possess.
> See: Common law principle
> [Nemo Dat Quod Non Habet](https://en.wikipedia.org/wiki/Nemo_dat_quod_non_habet)

*Transferor* **has no right to** *transfer* *Property* from *Transferee*

---

### Bona Fide Purchaser Exception

> A purchaser who acts in good faith, without notice of adverse claims, and pays value acquires good title even from one who lacks it.

excepts #nemo-dat-rule

*bona_fide_purchaser* **is entitled to** *receive* *Property* from *Transferor*

---

## Taxonomy Requirements

This framework requires the following taxonomy entries:

### Role: bona_fide_purchaser

**Parent:** Transferee

**Definition:** A transferee who:
1. Acts in good faith (without notice of defects in title)
2. Provides valuable consideration
3. Acquires possessory interest in the property

**Lean type:**
```lean4
def bona_fide_purchaser (e : LegalEntity) : Prop :=
  Transferee e ∧ good_faith e ∧ provided_value e ∧ acquired_possession e
```

---

## Generated Lean Code

```lean4
namespace UniversalTransfer

-- Rule: #nemo-dat-rule (depth 0)
-- Position: NoRight (First-order, Holder, Negative)
def nemo_dat (transferor : Quantifier) (transferee : Quantifier) (prop : Property) : Prop :=
  holds NoRight transferor transfer prop transferee

-- Correlative (auto-generated)
theorem nemo_dat_correlative (transferor : Quantifier) (transferee : Quantifier) (prop : Property) :
  nemo_dat transferor transferee prop →
  holds Privilege transferee refuse_transfer prop transferor := by
  intro h
  exact correlative_noright_privilege h

-- Rule: #bona-fide-purchaser-exception (depth 1)
-- Position: Right (auto-computed: O_pos(NoRight) at odd depth)
def bona_fide_exception (purchaser : Quantifier) (transferor : Quantifier) (prop : Property) : Prop :=
  bona_fide_purchaser purchaser →
  holds Right purchaser receive prop transferor

-- Correlative (auto-generated)
theorem bona_fide_correlative (purchaser : Quantifier) (transferor : Quantifier) (prop : Property) :
  bona_fide_exception purchaser transferor prop →
  holds Duty transferor deliver prop purchaser := by
  intro h
  exact correlative_right_duty h

-- Defeasibility resolution
def transfer_rights (person : LegalEntity) (transferor : LegalEntity) (prop : Property) : Prop :=
  if bona_fide_purchaser person then
    -- Depth 1: exception applies - purchaser GETS the right
    holds Right person receive prop (Only transferor)
  else if Transferee person then
    -- Depth 0: base nemo dat applies - no right to demand transfer
    holds NoRight (Only transferor) transfer prop person
  else
    false

-- Validation: bona_fide_purchaser ⊆ Transferee
theorem bfp_is_transferee : ∀ e, bona_fide_purchaser e → Transferee e := by
  intro e h
  exact h.1  -- Extract Transferee from conjunction

end UniversalTransfer
```

---

## Example Scenario

```markdown
## Scenario: Stolen Property Sale

**Facts:**
*the Painting* isa *Property*
*Alice* isa *Owner*
*Thief* has *stolen* *the Painting* from *Alice*
*Bob* has *purchased* *the Painting* from *Thief*
*Bob* isa *bona_fide_purchaser*

**Questions:**
Does *Thief* **has no right to** *transfer* *the Painting* from *Bob*
Does *Bob* **is entitled to** *receive* *the Painting* from *Thief*
```

**Expected Results:**
- Thief has no right to transfer: **HOLDS** (nemo dat applies)
- Bob is entitled to receive: **HOLDS** (bona fide exception applies at depth 1)

**Key insight:** Both can be true simultaneously because:
- Thief lacks the right to transfer (depth 0, NoRight)
- But Bob gains the right to receive (depth 1, Right) as a bona fide purchaser
- The exception at odd depth flips the position: NoRight → Right

---

## Legal Significance

This demonstrates core OpenNorm capabilities:

1. **Exception hierarchies model legal reasoning**: The bona fide purchaser exception defeats the general nemo dat rule through depth-based defeasibility

2. **Position flipping reflects legal structure**: 
   - Depth 0 (even): NoRight - general prohibition
   - Depth 1 (odd): Right - exception creates affirmative entitlement
   - The O_pos operator captures the legal transformation

3. **Taxonomy subsumption drives specificity**: 
   - `bona_fide_purchaser ⊆ Transferee` (definitional through conjunction)
   - More specific type wins automatically
   - No manual priority needed

4. **Practical utility**: These rules underpin property law across jurisdictions and apply to contracts, sales, secured transactions, and more

---

*Universal Transfer Framework*
*Part of stdlib/frameworks/universal*
*OpenNorm Foundation Package*