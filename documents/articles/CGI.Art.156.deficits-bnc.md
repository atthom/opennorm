# Article 156 du Code Général des Impôts - Déficits BNC

> Version en vigueur depuis le 21 février 2026
> Encodage OpenNorm - Module: Déficits BNC (Bénéfices Non Commerciaux)

## Manifeste

**OpenNorm:** 0.1
**Paquet:** cgi.art156.deficits-bnc
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
  - Professionnel
    - ProfessionLibérale
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

## COUCHE 1 : NORMATIVE

### I.2° - Déficits de professions non commerciales {art156-i-2-deficits-professions-non-commerciales}

> Des déficits provenant d'activités non commerciales, autres que ceux qui proviennent 
> de l'exercice d'une profession libérale ou des charges et offices dont les titulaires 
> n'ont pas la qualité de commerçants ; ces déficits peuvent cependant être imputés 
> sur les bénéfices tirés d'activités semblables durant la même année ou les six années suivantes.

*Contribuable* **a le droit de** *reporter* le *DéficitBNC* envers *AdministrationFiscale*
exception de art156-norme-principale

---

## COUCHE 2 : OPÉRATIONNELLE

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
