# stdlib / economics / core

> Defines economic terms used in license grants and contracts.

**OpenNorm:** 0.1
**Package:** economics.core
**Version:** 1.0
**Status:** review

---

## Manifest

- "free of charge"         → free_of_charge
- "at no cost"             → free_of_charge
- "without charge"         → free_of_charge
- "gratis"                 → free_of_charge
- "for consideration"      → consideration
- "for payment"            → consideration
- "royalty"                → royalty
- "royalty-free"           → royalty_free
- "compensation"           → consideration

---

## free_of_charge

**Meaning:** No monetary or equivalent consideration is required to exercise
the granted rights.
**Applies to:** the grant itself, not to services built on top

> A company may charge for support, hosting, or integration services
> for MIT-licensed software. The *free_of_charge* term governs only the
> permission grant, not downstream commercial activity.

---

## consideration

**Meaning:** Something of value exchanged between parties.
**Includes:** money, services, other licenses, reciprocal obligations
**Relevance:** licenses are unilateral grants and typically do not require
consideration; contracts do.

---

## royalty

**Meaning:** A recurring payment to a rights holder for the right to exercise
a licensed right.

---

## royalty_free

**Meaning:** A grant for which no royalty payment is required.
**Distinct from:** *free_of_charge* — royalty-free still permits a one-time
upfront fee; free_of_charge permits no fee at any stage.