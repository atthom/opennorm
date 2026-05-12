# stdlib / frameworks / universal / core

## Manifest

**OpenNorm:** 0.1
**Package:** frameworks.universal.core
**Package-type:** framework
**Version:** 2.0
**Implicit-import:** frameworks.universal.definitions
**Status:** review

> The universal normative core. These definitions form the foundation
> of all OpenNorm documents, providing common taxonomies for legal entities,
> roles, actions, and objects.
>
> This framework is domain-agnostic: it applies to any normative system
> (contracts, regulations, licenses, policies, bylaws, etc.)
>
> Review threshold: highest in the entire stdlib.
> A change here potentially affects every document that imports it.

---

## Taxonomies

### LegalEntities Taxonomy

- AnyOne
  - Individual
  - LegalPerson
    - Corporation
    - State
    - Organization
    - Institution
    - CollectiveBody
      - TreatyBody
      - ClassActionGroup

### Role Taxonomy

- AnyRole
  - LicensingRole
    - RightsHolder
    - Licensor
    - Licensee
  - EmploymentRole
    - Employer
    - Employee
      - Manager
      - Developer
      - Designer
    - Contractor

### Action Taxonomy

- AnyAction
  - IntellectualProperty
    - use
    - copy
    - modify
    - merge
    - publish
    - distribute
    - sublicense
    - sell
  - Administrative
    - include
    - provide
    - notify
    - inform
  - Legal
    - warrant
    - claim
    - revoke
  - Economic
    - buy
    - sell
    - transfer
    - compensate
  - Employment
    - hire
    - terminate
    - compensate
  - Work
    - code
    - review
    - deploy
    - design
  - Tax
    - declare
    - pay
    - file
    - deduct
    - apply
    - impose
    - audit
    - collect
    - assess
    - refund
    - withhold
    - impute
    - carryforward
    - calculate
    - establish
    - determine
    - ascertain
    - remit
    - reconstitute

### Object Taxonomy

- AnyThing
  - Units
    - EUR (Currency)
    - USD (Currency)
    - Années (Duration)
    - Date
    - Boolean (*Oui*, *Non*, *True*, *False*)
  - Physical
    - Land
    - Goods
    - Money
  - Digital
    - Software
    - Data
    - Documents
  - Normative
    - Contracts
    - Relationships
    - Capacities
  - Legal
    - Copyright Notice
    - License
    - Patent
    - Trademark
    - damages
  - Project
    - Backend
    - Frontend
    - Database

---

## Notes

This framework provides the common vocabulary for OpenNorm documents.
Domain-specific taxonomies should extend these base taxonomies rather
than redefining them.

For example, a tax regulation document would:
1. Import this core framework
2. Extend the Role taxonomy 
3. Extend the Action taxonomy 
4. Extend the Object taxonomy

This ensures consistency across documents while allowing domain-specific
customization.