# Article 156 du Code Général des Impôts - Déficits Agricoles

> Version en vigueur depuis le 21 février 2026
> Encodage OpenNorm - Module: Déficits Agricoles

## Manifeste

**OpenNorm:** 0.1
**Paquet:** cgi.art156.deficits-agricoles
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
  - Exploitant
    - ExploitantAgricole
  - ChefExploitationAgricole
  - AdministrationFiscale

### Taxonomie des Actions

- AnyAction
  - Fiscal
    - déduire
    - imputer
    - reporter
    - calculer

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
      - Date
    - Booléen
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

## COUCHE 1 : NORMATIVE

### I.1° - Déficits agricoles avec seuil de revenus {art156-i-1-deficits-agricoles-seuil}

> N'est pas autorisée l'imputation des déficits provenant d'exploitations agricoles 
> lorsque le total des revenus nets d'autres sources excède 127 677 € ; 
> ces déficits peuvent cependant être admis en déduction des bénéfices de même nature 
> des années suivantes jusqu'à la sixième inclusivement.

*ExploitantAgricole* **a le droit de** *reporter* le *DéficitAgricole* envers *AdministrationFiscale*
lorsque *RevenuAutresSources* <= *SeuilRevenuAutres*
exception de art156-norme-principale
---

## COUCHE 2 : OPÉRATIONNELLE

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
