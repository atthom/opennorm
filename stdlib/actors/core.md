# stdlib / actors / core

> Defines the fundamental actor types used across all OpenNorm documents.
> An actor is any entity that can hold rights, bear obligations, or perform actions.

**OpenNorm:** 0.1
**Package:** actors.core
**Version:** 1.0
**Status:** review

---

## Manifest

> Surface forms recognized by the parser's term manifest index.
> Format: surface form → canonical term id

- "person"           → Person
- "any person"       → Person
- "individual"       → Person
- "natural person"   → Person
- "legal person"     → LegalPerson
- "entity"           → LegalPerson
- "organization"     → LegalPerson
- "institution"      → Institution
- "rights holder"    → RightsHolder
- "licensor"         → Licensor
- "licensee"         → Licensee
- "recipient"        → Recipient
- "sublicensee"      → Sublicensee

---

## Person

**Meaning:** Any natural or legal person capable of holding rights and bearing obligations.
**Includes:** *LegalPerson*, *NaturalPerson*

---

## NaturalPerson

**Meaning:** A human individual.

---

## LegalPerson

**Meaning:** An entity recognised by law as capable of holding rights: corporation, foundation, government body.

---

## Institution

**Meaning:** A formal organisation with persistent identity independent of its members.

---

## RightsHolder

**Meaning:** A *Person* who holds specific rights over a subject matter.

---

## Licensor

**Meaning:** A *RightsHolder* who grants a license.
**Precondition:** holds the rights being granted

---

## Licensee

**Meaning:** A *Person* who receives a license grant.
**Becomes:** *Recipient* upon obtaining a copy of the licensed subject matter

---

## Recipient

**Meaning:** A *Licensee* who has obtained a copy of the licensed subject matter.
**Trigger:** the moment of obtaining creates the relationship

---

## Sublicensee

**Meaning:** A *Person* to whom a *Recipient* grants further rights under authority of the original license.
**Bound by:** sublicense_bound axiom — rights granted cannot exceed rights held