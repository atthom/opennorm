# Article 156 du Code Général des Impôts - Déficits Capitaux Mobiliers

> Version en vigueur depuis le 21 février 2026
> Encodage OpenNorm - Module: Déficits Capitaux Mobiliers

## Manifeste

**OpenNorm:** 0.1
**Paquet:** cgi.art156.deficits-capitaux
**Type-paquet:** réglementation
**Version:** 3.0
**Statut:** révision
**Langue:** FR
**Juridiction:** FR.Loi
**Importations:**

- stdlib/frameworks/universal/core@2.0

---

## Taxonomies

### Taxonomie des Rôles

- AnyRole
  - Contribuable
  - AdministrationFiscale

### Taxonomie des Actions

- AnyAction
  - Fiscal
    - imputer
    - reporter

---

## TypesOpenNorm

### Taxonomie des Objets

- AnyThing
  - Unités
    - Devise
      - EUR
    - Temps
      - Durée
        - Années (alias: yr)
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

## COUCHE 1 : NORMATIVE

### I.8° - Déficits de capitaux mobiliers {art156-i-8-deficits-capitaux-mobiliers}

> Des déficits constatés dans la catégorie des revenus des capitaux mobiliers ; 
> ces déficits peuvent cependant être imputés sur les revenus de même nature 
> des six années suivantes.

---

## COUCHE 2 : OPÉRATIONNELLE

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
