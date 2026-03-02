# stdlib / actors / core

**OpenNorm:** 0.1
**Package:** actors.core
**Version:** 1.0
**Status:** review

> Defines the fundamental actor types used across all OpenNorm documents.
> An actor is any entity that can hold rights, bear obligations, or perform actions.

---

## Manifest

### Actor Traits

**CanHoldRights** — entities capable of holding rights and bearing obligations:
- Person
  - NaturalPerson
  - LegalPerson
    - Institution

**CanGrant** — entities that hold and grant rights:
- RightsHolder
  - Licensor

**CanReceive** — entities that receive and obtain rights:
- Licensee
  - Recipient
    - Sublicensee

---

## Person

**Meaning:** Any natural or legal person capable of holding rights and bearing obligations.
**Forms:** person, any person, individual

---

## NaturalPerson

**Meaning:** A human individual.
**Forms:** natural person

---

## LegalPerson

**Meaning:** An entity recognised by law as capable of holding rights: corporation, foundation, government body.
**Forms:** legal person, entity, organization

---

## Institution

**Meaning:** A formal organisation with persistent identity independent of its members.
**Forms:** institution

---

## RightsHolder

**Meaning:** A *Person* who holds specific rights over a subject matter.
**Forms:** rights holder

---

## Licensor

**Meaning:** A *RightsHolder* who grants a license.
**Forms:** licensor
**Precondition:** holds the rights being granted

---

## Licensee

**Meaning:** A *Person* who receives a license grant.
**Forms:** licensee
**Becomes:** *Recipient* upon obtaining a copy of the licensed subject matter

---

## Recipient

**Meaning:** A *Licensee* who has obtained a copy of the licensed subject matter.
**Forms:** recipient
**Trigger:** the moment of obtaining creates the relationship

---

## Sublicensee

**Meaning:** A *Person* to whom a *Recipient* grants further rights under authority of the original license.
**Forms:** sublicensee
**Bound by:** sublicense_bound axiom — rights granted cannot exceed rights held