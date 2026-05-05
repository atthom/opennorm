# Subsumption Contradiction Test

> This test document demonstrates hierarchical subsumption logic in OpenNorm.
> It contains two norms that contradict each other, but the contradiction
> only becomes apparent when considering the taxonomy hierarchy.
>
> The test verifies that the SMT solver correctly detects contradictions
> when a general permission (using parent terms) conflicts with a specific
> prohibition (using child terms).

## Manifest

**OpenNorm:** 0.1
**Package:** test.subsumption
**Package-type:** contract
**Version:** 1.0
**Status:** review
**Imports:**

- stdlib/frameworks/universal/core@2.0

---

## Test Norms

### General Permission

> This norm grants a general permission to all Employees to perform any
> Work action on any Project. Since Developer is a child of Employee,
> deploy is a child of Work, and Backend is a child of Project, this
> norm implicitly grants Developers the privilege to deploy the Backend.

*Employee* **may** *Work* the *Project* to *AnyOne*

### Specific Duty

> This norm explicitly requires Developers to deploy the Backend.
> This creates a contradiction with the general permission above, but
> only when considering the taxonomy hierarchy:
>
> - Developer ⊆ Employee (Developer is a specialization of Employee)
> - deploy ⊆ Work (deploy is a specialization of Work)
> - Backend ⊆ Project (Backend is a specialization of Project)
>
> Therefore, the general permission says "Developer may deploy Backend" (Privilege)
> while this norm says "Developer must deploy Backend" (Duty) - a contradiction!
> Privilege and Duty are Hohfeldian opposites.

*Developer* **must** *deploy* the *Backend* to *AnyOne*

---

## Expected Behavior

When this document is processed by the SMT solver, it should:

1. **Detect a contradiction** between the two norms
2. **Report the contradiction** with details:
   - Norm 1: general-permission (Privilege)
   - Norm 2: specific-prohibition (Disability)
   - Relationship: Privilege and Disability are opposites
   - Subsumption: The specific prohibition is a specialization of the general permission

3. **Explain the hierarchy**:
   - Developer is a child of Employee
   - deploy is a child of Work
   - Backend is a child of Project

## Test Variations

To further test subsumption logic, consider these variations:

1. **Partial Subsumption**: Only some terms are hierarchical
   - *Developer* **may** *Work* the *Backend* to *AnyOne*
   - *Developer* **cannot** *deploy* the *Backend* to *AnyOne*
   - (Only action is specialized)

2. **Multiple Levels**: Deep hierarchy
   - *Employee* **may** *Work* the *Project* to *AnyOne*
   - *Developer* **cannot** *code* the *Backend* to *AnyOne*
   - (Two levels of specialization)

3. **No Subsumption**: Unrelated terms
   - *Manager* **may** *review* the *Frontend* to *AnyOne*
   - *Developer* **cannot** *deploy* the *Backend* to *AnyOne*
   - (No contradiction - different terms)