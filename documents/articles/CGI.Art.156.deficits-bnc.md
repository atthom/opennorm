# Article 156 du Code Général des Impôts - Déficits BNC

> Version en vigueur depuis le 21 février 2026
> Encodage OpenNorm - Module: Déficits BNC (Bénéfices Non Commerciaux)

## Manifest

**OpenNorm:** 0.1
**Package:** cgi.art156.deficits-bnc
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
  - Contribuable
  - Professionnel
    - ProfessionLibérale

### Action Taxonomy

- AnyAction
  - imputer
  - reporter

---

## OpenNormTypes

### Object Taxonomy

- AnyThing
  - Units
    - EUR (Currency)
    - Années (Duration)
    - TypeActivitéType (*ProfessionLibérale*, *ChargeOffice*, *Autre*)
  - Concepts
    - Déficit
      - DéficitBNC
  - OpenNormVariables
    - Constants
      - DuréeReport = 6 *Années*
    - Parameters
      - TypeActivité = *TypeActivitéType*
      - DéficitBNC = *EUR*
      - BénéficeBNCAnnéeCourante = *EUR*
    - ComputedVariables
      - DéficitBNCImputable = *EUR*
      - ReportDéficitBNC = *EUR*

---

## LAYER 1: NORMATIVE

### I.2° - Déficits de professions non commerciales

> Des déficits provenant d'activités non commerciales, autres que ceux qui proviennent 
> de l'exercice d'une profession libérale ou des charges et offices dont les titulaires 
> n'ont pas la qualité de commerçants ; ces déficits peuvent cependant être imputés 
> sur les bénéfices tirés d'activités semblables durant la même année ou les six années suivantes.

*Contribuable* **ne peut pas** *imputer* le *DéficitBNC* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque non (*TypeActivité* = *ProfessionLibérale* ou *TypeActivité* = *ChargeOffice*)
{#art156-I-2-interdiction-bnc}

*ProfessionLibérale* **a le droit de** *imputer* le *DéficitBNC* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *TypeActivité* = *ProfessionLibérale*
sauf #art156-I-2-interdiction-bnc
{#art156-I-2-exception-profession-libérale}

*Contribuable* **a le droit de** *imputer* le *DéficitBNC* à *AdministrationFiscale* envers *BénéficeBNC*
{#art156-I-2-imputation-bnc}

*Contribuable* **a le droit de** *reporter* le *DéficitBNC* à *AdministrationFiscale* envers *SixAnnées*
{#art156-I-2-report-bnc}

---

## LAYER 2: OPERATIONAL

### Déficit BNC

## *DéficitBNCImputable*

> Déficit BNC imputable selon le type d'activité

Case:
  - *TypeActivité* = *ProfessionLibérale*:
      *DéficitBNC*
  - *TypeActivité* = *ChargeOffice*:
      *DéficitBNC*
  - Default: 0 EUR

---

## *ReportDéficitBNC*

> Report du déficit BNC sur les bénéfices BNC des années suivantes

*ReportDéficitBNC* = min(*DéficitBNC*, *BénéficeBNCAnnéeCourante*)

---

## Notes d'implémentation

### Domaine

Ce module encode les dispositions de l'Article 156 du CGI relatives aux déficits des bénéfices non commerciaux (BNC), avec les règles spécifiques pour les professions libérales et les charges et offices.

### Références légales

- **Code Général des Impôts, Article 156, I.2°** - Déficits de professions non commerciales

### Règles d'imputation

Les déficits BNC suivent des règles différentes selon le type d'activité:

1. **Professions libérales**: Les déficits sont imputables sur le revenu global
2. **Charges et offices** (titulaires non commerçants): Les déficits sont imputables sur le revenu global
3. **Autres activités non commerciales**: Les déficits ne sont imputables que sur les bénéfices de même nature

### Paramètres

- *DuréeReportDéficitBNC* = 6 *Années*

### Statut de vérification

- [ ] Vérification SMT (cohérence logique normative)
- [ ] Vérification exhaustiveness (procédures opérationnelles)
- [ ] Vérification type checking (unités et types)
- [ ] Vérification computation graph (pas de cycles)

### Changelog

**Version 3.0 (2026-05-05)**
- Extraction du module déficits BNC depuis CGI.Art.156.opennorm.md
- Module autonome avec manifest complet
- Conservation de la cohérence norms/procédures