# Article 156 du Code Général des Impôts - Déficits Agricoles

> Version en vigueur depuis le 21 février 2026
> Encodage OpenNorm - Module: Déficits Agricoles

## Manifest

**OpenNorm:** 0.1
**Package:** cgi.art156.deficits-agricoles
**Package-type:** regulation
**Version:** 3.0
**Status:** review
**Language:** FR
**Imports:**

- stdlib/frameworks/universal/core@2.0

---

## Taxonomies

### Role Taxonomy

- AnyRole
  - Exploitant
    - ExploitantAgricole
  - ChefExploitationAgricole
  - AdministrationFiscale

### Action Taxonomy

- AnyAction
  - déduire
  - imputer
  - reporter
  - calculer

---

## OpenNormTypes

### Object Taxonomy

- AnyThing
  - Units
    - Currency
      - EUR
    - Time
      - Duration
        - Années (alias: yr)
      - Date
    - Boolean
  - Concepts
    - Revenu
      - RevenuBrut
    - Déficit
      - DéficitAgricole
    - Charge
      - Prime
      - CotisationSociale
    - Montant
      - Seuil
  - OpenNormVariables
    - Constants
      - SeuilRevenuAutres = 127 677 *EUR*
      - DuréeReport = 6 *Années*
    - Parameters
      - RevenuAutresSources = *EUR* (required)
      - DéficitAgricole = *EUR*
      - BénéficeAgricoleAnnéeCourante = *EUR*
      - MontantPrimesL752_1_21 = *EUR*
      - MontantCotisationsGroupe = *EUR*
      - LimiteArt154bis0A = *EUR*
    - ComputedVariables
      - DéficitAgricoleImputable = *EUR*
      - ReportDéficitAgricole = *EUR*
      - PrimesAssurancesAgricoles = *EUR*
      - CotisationsAssuranceGroupeAgricole = *EUR*

---

## LAYER 1: NORMATIVE

### I.1° - Déficits agricoles avec seuil de revenus

> N'est pas autorisée l'imputation des déficits provenant d'exploitations agricoles 
> lorsque le total des revenus nets d'autres sources excède 127 677 € ; 
> ces déficits peuvent cependant être admis en déduction des bénéfices de même nature 
> des années suivantes jusqu'à la sixième inclusivement.

*ExploitantAgricole* **ne peut pas** *imputer* le *DéficitAgricole* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *RevenuAutresSources* > *SeuilRevenuAutres*
{#art156-I-1-interdiction-imputation}

*ExploitantAgricole* **a le droit de** *imputer* le *DéficitAgricole* à *AdministrationFiscale* envers *BénéficeAgricole*
lorsque *RevenuAutresSources* > *SeuilRevenuAutres*
{#art156-I-1-imputation-même-nature}

*ExploitantAgricole* **a le droit de** *reporter* le *DéficitAgricole* à *AdministrationFiscale* envers *SixAnnées*
{#art156-I-1-report-agricole}

---

### II.11° - Assurances accidents agricoles

> Les primes ou cotisations des contrats d'assurances conclus en application 
> des articles L. 752-1 à L. 752-21 du code rural et de la pêche maritime.
> Référence: Articles L. 752-1 à L. 752-21 CRPM

*ExploitantAgricole* **a le droit de** *déduire* la *Prime* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *ExploitantAgricole* a *ContratAssuranceL752_1_21*
{#art156-II-11-assurances-agricoles}

---

### II.13° - Assurances de groupe agricoles

> Les cotisations versées par les chefs d'exploitation ou d'entreprise agricole 
> au titre des contrats d'assurance de groupe.
> Référence: 2° de l'article L. 144-1 du code des assurances
> Limites: Article 154 bis-0 A

*ChefExploitationAgricole* **a le droit de** *déduire* la *CotisationSociale* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *ChefExploitationAgricole* a *ContratAssuranceGroupeL144_1*
et *MontantCotisationsGroupe* <= *LimiteArt154bis0A*
{#art156-II-13-assurances-groupe}

---

## LAYER 2: OPERATIONAL

### Déficit agricole avec seuil

## *DéficitAgricoleImputable*

> Calcul du déficit agricole imputable selon le seuil de revenus autres sources

Case:
  - *RevenuAutresSources* > *SeuilRevenuAutres*:
      0 EUR
  - Default:
      *DéficitAgricole*

---

## *ReportDéficitAgricole*

> Report du déficit agricole sur les bénéfices agricoles des années suivantes

Case:
  - *RevenuAutresSources* > *SeuilRevenuAutres*:
      min(*DéficitAgricole*, *BénéficeAgricoleAnnéeCourante*)
  - Default:
      0 EUR

---

### Charges déductibles agricoles

## *PrimesAssurancesAgricoles*

> Primes d'assurances accidents pour non-salariés agricoles

*PrimesAssurancesAgricoles* = *MontantPrimesL752_1_21*

---

## *CotisationsAssuranceGroupeAgricole*

> Cotisations d'assurance de groupe pour chefs d'exploitation agricole

*CotisationsAssuranceGroupeAgricole* = min(*MontantCotisationsGroupe*, *LimiteArt154bis0A*)

---

## Notes d'implémentation

### Domaine

Ce module encode les dispositions de l'Article 156 du CGI relatives aux déficits agricoles et aux charges déductibles spécifiques aux exploitants agricoles.

### Références légales

- **Code Général des Impôts, Article 156, I.1°** - Déficits agricoles
- **Code Général des Impôts, Article 156, II.11°** - Assurances accidents agricoles
- **Code Général des Impôts, Article 156, II.13°** - Assurances de groupe agricoles
- **Code Général des Impôts, Article 154 bis-0 A** - Limites de déduction
- **Code Rural et de la Pêche Maritime, Articles L. 752-1 à L. 752-21** - Assurances obligatoires
- **Code des Assurances, Article L. 144-1** - Contrats d'assurance de groupe

### Paramètres

- *SeuilRevenuAutres* = 127 677 *EUR* (révisé annuellement selon première tranche barème IR)
- *DuréeReportDéficitAgricole* = 6 *Années*

### Statut de vérification

- [ ] Vérification SMT (cohérence logique normative)
- [ ] Vérification exhaustiveness (procédures opérationnelles)
- [ ] Vérification type checking (unités et types)
- [ ] Vérification computation graph (pas de cycles)

### Changelog

**Version 3.0 (2026-05-05)**
- Extraction du module déficits agricoles depuis CGI.Art.156.opennorm.md
- Module autonome avec manifest complet
- Conservation de la cohérence norms/procédures