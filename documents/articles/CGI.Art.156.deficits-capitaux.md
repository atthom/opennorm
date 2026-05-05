# Article 156 du Code Général des Impôts - Déficits Capitaux Mobiliers

> Version en vigueur depuis le 21 février 2026
> Encodage OpenNorm - Module: Déficits Capitaux Mobiliers

## Manifest

**OpenNorm:** 0.1
**Package:** cgi.art156.deficits-capitaux
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
  - Concepts
    - Déficit
      - DéficitCapitauxMobiliers
  - OpenNormVariables
    - Constants
      - DuréeReport = 6 *Années*
    - Parameters
      - DéficitCapitauxMobiliers = *EUR*
      - RevenuCapitauxMobiliersAnnéeCourante = *EUR*
    - ComputedVariables
      - DéficitCapitauxMobiliersImputable = *EUR*
      - ReportDéficitCapitauxMobiliers = *EUR*

---

## LAYER 1: NORMATIVE

### I.8° - Déficits de capitaux mobiliers

> Des déficits constatés dans la catégorie des revenus des capitaux mobiliers ; 
> ces déficits peuvent cependant être imputés sur les revenus de même nature 
> des six années suivantes.

*Contribuable* **ne peut pas** *imputer* le *DéficitCapitauxMobiliers* à *AdministrationFiscale* envers *RevenuGlobal*
{#art156-I-8-interdiction-capitaux}

*Contribuable* **a le droit de** *imputer* le *DéficitCapitauxMobiliers* à *AdministrationFiscale* envers *RevenuCapitauxMobiliers*
{#art156-I-8-imputation-capitaux}

*Contribuable* **a le droit de** *reporter* le *DéficitCapitauxMobiliers* à *AdministrationFiscale* envers *SixAnnées*
{#art156-I-8-report-capitaux}

---

## LAYER 2: OPERATIONAL

### Déficit capitaux mobiliers

## *DéficitCapitauxMobiliersImputable*

> Déficit de capitaux mobiliers non imputable sur le revenu global

*DéficitCapitauxMobiliersImputable* = 0 EUR

---

## *ReportDéficitCapitauxMobiliers*

> Report du déficit de capitaux mobiliers sur les revenus de même nature

*ReportDéficitCapitauxMobiliers* = min(*DéficitCapitauxMobiliers*, *RevenuCapitauxMobiliersAnnéeCourante*)

---

## Notes d'implémentation

### Domaine

Ce module encode les dispositions de l'Article 156 du CGI relatives aux déficits de capitaux mobiliers. Ces déficits ne peuvent jamais être imputés sur le revenu global, mais uniquement sur les revenus de capitaux mobiliers des années suivantes.

### Références légales

- **Code Général des Impôts, Article 156, I.8°** - Déficits de capitaux mobiliers

### Règles d'imputation

Les déficits de capitaux mobiliers suivent un régime strict:

1. **Interdiction d'imputation sur le revenu global**: Ces déficits ne peuvent jamais réduire le revenu global
2. **Imputation sur revenus de même nature**: Ils s'imputent uniquement sur les revenus de capitaux mobiliers
3. **Report sur 6 ans**: Les déficits non imputés peuvent être reportés sur les 6 années suivantes

### Paramètres

- *DuréeReportDéficitCapitauxMobiliers* = 6 *Années*

### Statut de vérification

- [ ] Vérification SMT (cohérence logique normative)
- [ ] Vérification exhaustiveness (procédures opérationnelles)
- [ ] Vérification type checking (unités et types)
- [ ] Vérification computation graph (pas de cycles)

### Changelog

**Version 3.0 (2026-05-05)**
- Extraction du module déficits capitaux mobiliers depuis CGI.Art.156.opennorm.md
- Module autonome avec manifest complet
- Conservation de la cohérence norms/procédures