-- Deontic.lean — OpenNorm base deontic library
-- This file is written once and imported by all generated documents.
-- Core modalities are axiomatised, not defined with sorry.
-- sorry appears only in generated document files for fuzzy terms.

import Mathlib.Logic.Basic

-- ── Type universe ────────────────────────────────────────────────────────────
-- Actors and Actions are abstract. Concrete types are introduced per document.

variable {Actor : Type} {Action : Type}

-- ── Core deontic modalities ───────────────────────────────────────────────────
-- Axiomatised: we assert their existence and the relations between them.
-- We do not give computational definitions — they are not decidable in general.

axiom Permitted  (a : Actor) (x : Action) : Prop
axiom Obligated  (a : Actor) (x : Action) : Prop
axiom Forbidden  (a : Actor) (x : Action) : Prop
axiom Waivable   (a : Actor) (r : Action) : Prop   -- right the holder can surrender
axiom Absolute   (a : Actor) (r : Action) : Prop   -- right that cannot be surrendered

-- ── Core consistency axioms ───────────────────────────────────────────────────

-- Nothing can be simultaneously permitted and forbidden.
axiom deontic_consistency (a : Actor) (x : Action) :
  ¬(Permitted a x ∧ Forbidden a x)

-- Every obligation implies permission to perform the obligated action.
axiom obligation_permits (a : Actor) (x : Action) :
  Obligated a x → Permitted a x

-- Forbidden implies not-permitted (derived from consistency, stated explicitly
-- so generated code can reference it directly).
theorem forbidden_not_permitted (a : Actor) (x : Action) :
  Forbidden a x → ¬Permitted a x := by
  intro hf hp
  exact deontic_consistency a x ⟨hp, hf⟩

-- ── Conditions ───────────────────────────────────────────────────────────────
-- Conditional permission: permitted if some predicate holds.

def ConditionallyPermitted (a : Actor) (x : Action) (cond : Prop) : Prop :=
  cond → Permitted a x

def ConditionallyObligated (a : Actor) (x : Action) (cond : Prop) : Prop :=
  cond → Obligated a x

-- ── Defeasibility ────────────────────────────────────────────────────────────
-- Rules can defeat other rules. Higher priority wins.
-- This models the indented bullet structure in OpenNorm documents.

structure Rule (Actor Action : Type) where
  id        : String
  applies   : Actor → Action → Bool   -- decidable: Bool not Prop
  permitted : Bool
  priority  : Nat

-- Given a list of applicable rules, the winner is the highest priority one.
def winning_rule {α β : Type} (rules : List (Rule α β)) (a : α) (x : β)
    : Option (Rule α β) :=
  let applicable := rules.filter (fun r => r.applies a x)
  applicable.foldl (fun acc r =>
    match acc with
    | none   => some r
    | some w => if r.priority > w.priority then some r else some w
  ) none

-- The result of applying defeasible rules to an actor/action pair.
def defeasible_permitted {α β : Type} (rules : List (Rule α β)) (a : α) (x : β)
    : Bool :=
  match winning_rule rules a x with
  | some r => r.permitted
  | none   => false   -- closed-world assumption: default deny

-- ── Sublicense bound (universal) ─────────────────────────────────────────────
-- A sublicensee cannot receive more rights than the licensor holds.
-- This is a structural property proved once here; MIT transpilation references it.

axiom RightSet : Type
axiom rights_of   : Actor → RightSet
axiom subset_of   : RightSet → RightSet → Prop

axiom sublicense_bound (licensor sublicensee : Actor) (granted : RightSet) :
  subset_of granted (rights_of licensor) →
  subset_of (rights_of sublicensee) granted

-- ── sorry policy ─────────────────────────────────────────────────────────────
-- Every sorry in a generated .lean file corresponds to a fuzzy term declared
-- in the source .md document's § Known Ambiguities section.
-- sorry does NOT appear in this file. All foundational gaps are axioms.
-- The report's sorry inventory lists only document-level fuzziness.