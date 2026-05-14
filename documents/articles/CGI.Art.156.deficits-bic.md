# Article 156 du Code Général des Impôts - Déficits BIC

> Version en vigueur depuis le 21 février 2026
> Encodage OpenNorm - Module: Déficits BIC et Location Meublée

## Manifest

**OpenNorm:** 0.1
**Package:** cgi.art156.deficits-bic
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
  - FoyerFiscal
  - TravailleurIndépendant
  - Loueur
    - LoueurMeublé
      - LoueurMeubléProfessionnel
      - LoueurMeubléNonProfessionnel
  - AdministrationFiscale

### Action Taxonomy

- AnyAction
  - imputer
  - reporter
  - déduire

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
    - Boolean
    - ParticipationPersonnelleType (*Absente*, *Présente*)
    - StatutLocationType (*NonProfessionnel*, *ProfessionnelDèsDébut*)
  - Concepts
    - Revenu
      - RevenuBrut
    - Déficit
      - DéficitBIC
    - Charge
      - CotisationSociale
  - OpenNormVariables
    - Constants
      - DuréeReport = 6 *Années*
      - DuréeReportLMNP = 10 *Années*
      - NombreAnnéesImputation = 3 *Années*
    - Parameters
      - ParticipationPersonnelle = *ParticipationPersonnelleType*
      - DéficitBIC = *EUR*
      - LiquidationJudiciaire = *Boolean* default *Oui*
      - ActifsCédés = *Boolean* default *Non*
      - DéficitBICRestantÀReporter = *EUR*
      - StatutLocation = *StatutLocationType*
      - RevenuLocationMeubléeNonPro = *EUR*
      - AnnéeLocation = *Années*
      - ChargesAvantCommencement = *EUR*
      - MontantCotisationsL621_1 = *EUR*
      - MontantCotisationsL622_2 = *EUR*
    - ComputedVariables
      - DéficitBICImputable = *EUR*
      - DéficitBICLiquidationJudiciaire = *EUR*
      - DéficitLMNPImputable = *EUR*
      - DéficitLMNPProfessionnelDébutant = *EUR*
      - CotisationsTravailleursIndépendants = *EUR*

---

## LAYER 1: NORMATIVE

### I.1° bis - Déficits BIC sans participation personnelle

> N'est pas autorisée l'imputation des déficits provenant, directement ou indirectement, 
> des activités relevant des bénéfices industriels ou commerciaux lorsque ces activités 
> ne comportent pas la participation personnelle, continue et directe de l'un des membres 
> du foyer fiscal.

*FoyerFiscal* **ne peut pas** *imputer* le *DéficitBIC* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *ParticipationPersonnelle* = *Absente*
{#art156-I-1bis-interdiction-bic}

*FoyerFiscal* **a le droit de** *imputer* le *DéficitBIC* à *AdministrationFiscale* envers *BénéficeBIC*
lorsque *ParticipationPersonnelle* = *Absente*
{#art156-I-1bis-imputation-même-nature}

*FoyerFiscal* **a le droit de** *reporter* le *DéficitBIC* à *AdministrationFiscale* envers *SixAnnées*
lorsque *ParticipationPersonnelle* = *Absente*
{#art156-I-1bis-report-bic}

*FoyerFiscal* **a le droit de** *imputer* le *DéficitBIC* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *LiquidationJudiciaire* = *Oui*
et *ActifsCédés* = *Oui*
sauf #art156-I-1bis-interdiction-bic
{#art156-I-1bis-exception-liquidation}

---

### I.1° ter - Déficits de location meublée non professionnelle

> Des déficits du foyer fiscal provenant de l'activité de location directe ou indirecte 
> de locaux d'habitation meublés ou destinés à être loués meublés lorsque l'activité 
> n'est pas exercée à titre professionnel. Ces déficits s'imputent exclusivement 
> sur les revenus provenant d'une telle activité au cours de celles des dix années suivantes.

*LoueurMeubléNonProfessionnel* **ne peut pas** *imputer* le *DéficitBIC* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *StatutLocation* = *NonProfessionnel*
{#art156-I-1ter-interdiction-lmnp}

*LoueurMeubléNonProfessionnel* **a le droit de** *imputer* le *DéficitBIC* à *AdministrationFiscale* envers *RevenuLocationMeublée*
lorsque *StatutLocation* = *NonProfessionnel*
{#art156-I-1ter-imputation-lmnp}

*LoueurMeubléNonProfessionnel* **a le droit de** *reporter* le *DéficitBIC* à *AdministrationFiscale* envers *DixAnnées*
lorsque *StatutLocation* = *NonProfessionnel*
{#art156-I-1ter-report-lmnp}

*LoueurMeubléProfessionnel* **a le droit de** *imputer* les *ChargesAvantCommencement* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *StatutLocation* = *ProfessionnelDèsDébut*
et *AnnéeLocation* <= *NombreAnnéesImputation*
sauf #art156-I-1ter-interdiction-lmnp
{#art156-I-1ter-exception-professionnel}

---

### II.10° - Cotisations des travailleurs indépendants

> Les cotisations mentionnées aux articles L. 621-1 et L. 622-2 
> du code de la sécurité sociale.
> Référence: Articles L. 621-1 et L. 622-2 CSS

*TravailleurIndépendant* **a le droit de** *déduire* la *CotisationSociale* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *TravailleurIndépendant* a *CotisationsL621_1* ou *TravailleurIndépendant* a *CotisationsL622_2*
{#art156-II-10-cotisations-indépendants}

---

## LAYER 2: OPERATIONAL

### Déficit BIC sans participation

## *DéficitBICImputable*

> Déficit BIC imputable selon la participation personnelle du foyer fiscal

Case:
  - *ParticipationPersonnelle* = *Absente*:
      0 EUR
  - *ParticipationPersonnelle* = *Présente*:
      *DéficitBIC*
  - Default: 0 EUR

---

## *DéficitBICLiquidationJudiciaire*

> Exception liquidation judiciaire - déficit BIC imputable sur revenu global

Case:
  - *LiquidationJudiciaire* = *Oui* AND *ActifsCédés* = *Oui*:
      *DéficitBICRestantÀReporter*
  - Default: 0 EUR

---

### Déficit LMNP

## *DéficitLMNPImputable*

> Déficit de location meublée non professionnelle imputable

Case:
  - *StatutLocation* = *NonProfessionnel*:
      min(*DéficitBIC*, *RevenuLocationMeubléeNonPro*)
  - Default: 0 EUR

---

## *DéficitLMNPProfessionnelDébutant*

> Imputation par tiers des charges avant commencement pour activité professionnelle dès le début

Case:
  - *StatutLocation* = *ProfessionnelDèsDébut* AND *AnnéeLocation* <= *NombreAnnéesImputation*:
      *ChargesAvantCommencement* / 3
  - Default: 0 EUR

---

### Cotisations travailleurs indépendants

## *CotisationsTravailleursIndépendants*

> Cotisations des travailleurs indépendants (articles L. 621-1 et L. 622-2 CSS)

*CotisationsTravailleursIndépendants* = *MontantCotisationsL621_1* + *MontantCotisationsL622_2*

---

## Notes d'implémentation

### Domaine

Ce module encode les dispositions de l'Article 156 du CGI relatives aux déficits des bénéfices industriels et commerciaux (BIC), incluant les règles spécifiques pour la location meublée non professionnelle (LMNP) et les cotisations des travailleurs indépendants.

### Références légales

- **Code Général des Impôts, Article 156, I.1° bis** - Déficits BIC sans participation personnelle
- **Code Général des Impôts, Article 156, I.1° ter** - Déficits location meublée non professionnelle
- **Code Général des Impôts, Article 156, II.10°** - Cotisations travailleurs indépendants
- **Code Général des Impôts, Article 155** - Statut professionnel location meublée
- **Code de la Sécurité Sociale, Articles L. 621-1 et L. 622-2** - Cotisations obligatoires

### Paramètres

- *DuréeReportDéficitBIC* = 6 *Années*
- *DuréeReportDéficitLMNP* = 10 *Années*
- *NombreAnnéesImputation* = 3 *Années* (pour LMNP professionnel dès le début)

### Statut de vérification

- [ ] Vérification SMT (cohérence logique normative)
- [ ] Vérification exhaustiveness (procédures opérationnelles)
- [ ] Vérification type checking (unités et types)
- [ ] Vérification computation graph (pas de cycles)

### Changelog

**Version 3.0 (2026-05-05)**
- Extraction du module déficits BIC depuis CGI.Art.156.opennorm.md
- Module autonome avec manifest complet
- Conservation de la cohérence norms/procédures
- Inclusion des règles LMNP et cotisations travailleurs indépendants