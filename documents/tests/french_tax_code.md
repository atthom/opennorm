# Code Général des Impôts - Income Tax

> French Income Tax regulations based on the Code général des impôts (CGI).
> This document covers key articles related to income tax obligations,
> progressive tax brackets, deductions, and family quotient system.
> 
> Based on 2024 tax rates and thresholds.

**OpenNorm:** 0.1
**Package:** CGI.IncomeTax
**Package-type:** ruling
**Version:** 1.0
**Status:** review
**Imports:**

- stdlib/frameworks/universal/core@2.0

---

## Taxonomies

### LegalEntities Taxonomy

- LegalEntities
  - Individual
    - Taxpayer
      - Employee
      - SelfEmployed
      - Retiree
      - Student
    - HouseholdTaxpayer
      - SingleParent
      - MarriedCouple
      - CivilUnionCouple
  - LegalPerson
    - State
      - FrenchTaxAuthority
    - Corporation
      - CorporateTaxpayer

### Role Taxonomy

- Role
  - TaxRole
    - TaxInspector
    - TaxCollector
    - TaxAdvisor
    - TaxAccountant

### Action Taxonomy

- Action
  - Economic
    - declare
    - pay
    - file
    - deduct
    - divide
    - apply
    - impose
    - audit
    - collect
    - assess
    - refund
    - withhold

### Object Taxonomy

- Object
  - Normative
    - TaxDocument
      - IncomeTax
      - TaxableIncome
      - GrossIncome
      - NetIncome
      - AnnualTaxReturn
      - TaxNotice
      - TaxAssessment
    - TaxConcept
      - FamilyQuotient
      - TaxBracket
      - TaxCredit
      - TaxDeduction
        - StandardDeduction
        - ProfessionalExpenses

---

## Article 1 - Tax Residence Obligation

> Establishes the fundamental obligation for French residents to pay income tax.
> Ref: CGI Article 1

*Taxpayer* **must** *pay* *IncomeTax* to *FrenchTaxAuthority*
when *Taxpayer* has *fiscal domicile* *in France*

## Article 13 - Taxable Income Declaration

> Defines the obligation to declare all sources of income.
> Ref: CGI Article 13

*Taxpayer* **must** *declare* *GrossIncome* to *FrenchTaxAuthority*
when *Taxpayer* has *received* *Income*

## Article 197 - Progressive Tax Brackets (2024)

> Establishes the progressive income tax rate structure.
> Ref: CGI Article 197

### Bracket 1 - Tax Free (0%)

*Taxpayer* **has no right to** *pay* *IncomeTax* to *FrenchTaxAuthority*
when *Taxpayer* has *annual taxable income* *up to €10,777*

### Bracket 2 - 11% Rate

*Taxpayer* **must** *pay* *11% of taxable income* to *FrenchTaxAuthority*
when *Taxpayer* has *annual taxable income* *between €10,778 and €27,478*

### Bracket 3 - 30% Rate

*Taxpayer* **must** *pay* *30% of taxable income* to *FrenchTaxAuthority*
when *Taxpayer* has *annual taxable income* *between €27,479 and €78,570*

### Bracket 4 - 41% Rate

*Taxpayer* **must** *pay* *41% of taxable income* to *FrenchTaxAuthority*
when *Taxpayer* has *annual taxable income* *between €78,571 and €168,994*

### Bracket 5 - 45% Rate

*Taxpayer* **must** *pay* *45% of taxable income* to *FrenchTaxAuthority*
when *Taxpayer* has *annual taxable income* *above €168,994*

## Article 156 - Standard Deduction

> Allows taxpayers to deduct professional expenses.
> Ref: CGI Article 156

*Employee* **has right to** *deduct* *10% of gross income* from *TaxableIncome*
when *Employee* has *professional expenses*

### Self-Employed Deduction

*SelfEmployed* **has right to** *deduct* *actual professional expenses* from *TaxableIncome*
when *SelfEmployed* has *documented* *business expenses*

## Article 200 - Family Quotient System

> Implements the family quotient (quotient familial) system.
> Ref: CGI Article 200

### Single Parent Quotient

*SingleParent* **has right to** *divide* *TaxableIncome* by *quotient of 2.0*
when *SingleParent* has *one dependent child*

### Married Couple Base Quotient

*MarriedCouple* **has right to** *divide* *TaxableIncome* by *quotient of 2.0*
when *MarriedCouple* has *no dependent children*

### Additional Child Quotient

*HouseholdTaxpayer* **has right to** *add* *0.5 to family quotient* per *dependent child*
when *HouseholdTaxpayer* has *dependent children*

## Article 170 - Annual Tax Return

> Establishes the obligation to file an annual tax return.
> Ref: CGI Article 170

*Taxpayer* **must** *file* *AnnualTaxReturn* to *FrenchTaxAuthority*
when *tax year* has *ended*

## Article 1727 - Late Payment Penalty

> Defines penalties for late tax payments.
> Ref: CGI Article 1727

*FrenchTaxAuthority* **has power to** *impose* *LatePaymentPenalty* on *Taxpayer*
when *Taxpayer* has *missed* *payment deadline*

## Article 1729 - Tax Audit Power

> Grants tax authority the power to audit taxpayers.
> Ref: CGI Article 1729

*TaxInspector* **has power to** *audit* *AnnualTaxReturn* of *Taxpayer*
when *TaxInspector* has *reasonable suspicion* *of error*
