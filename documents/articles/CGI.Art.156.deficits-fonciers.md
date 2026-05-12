# Article 156 du Code Général des Impôts - Déficits Fonciers

> Version en vigueur depuis le 21 février 2026
> Encodage OpenNorm - Module: Déficits Fonciers

## Manifest

**OpenNorm:** 0.1
**Package:** cgi.art156.deficits-fonciers
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
  - Propriétaire
    - PropriétaireMonumentHistorique
  - AdministrationFiscale

### Action Taxonomy

- AnyAction
  - imputer
  - reporter
  - déduire
  - reconstituer

---

## OpenNormTypes

### Object Taxonomy

- AnyThing
  - Units
    - EUR (Currency)
    - Années (Duration)
    - Date
    - Boolean (*Oui*, *Non*)
    - TypePropriétéType (*MonumentHistorique*, *Standard*)
    - ClasseÉnergétiqueType (*A*, *B*, *C*, *D*, *E*, *F*, *G*, *Autre*)
  - Concepts
    - Revenu
      - RevenuFoncier
    - Déficit
      - DéficitFoncier
    - Charge
      - ChargeFoncière
      - IntérêtEmprunt
  - OpenNormVariables
    - Constants
      - DuréeReportFoncier = 10 *Années*
      - PlafondDéficitFoncier = 10 700 *EUR*
      - PlafondDéficitFoncierMajoré = 15 300 *EUR*
      - PlafondRénovationÉnergétique = 21 400 *EUR*
      - DateLimiteJustification = 31/12/2027 *Date*
    - Parameters
      - TypePropriété = *TypePropriétéType*
      - DéficitFoncier = *EUR*
      - DéficitFoncierHorsIntérêts = *EUR*
      - DéductionsArt31 = *Boolean*
      - TravauxRénovationÉnergétique = *Boolean*
      - ClasseInitiale = *ClasseÉnergétiqueType*
      - ClasseFinale = *ClasseÉnergétiqueType*
      - MontantTravauxRénovation = *EUR*
      - RevenuFoncierAnnéeCourante = *EUR*
    - ComputedVariables
      - DéficitFoncierDéductible = *EUR*
      - DéficitFoncierRénovationÉnergétique = *EUR*
      - ReportDéficitFoncier = *EUR*

---

## LAYER 1: NORMATIVE

### I.3° - Déficits fonciers avec plafond de 10 700 €

> Des déficits fonciers, lesquels s'imputent exclusivement sur les revenus fonciers 
> des dix années suivantes. L'imputation exclusive sur les revenus fonciers n'est pas 
> applicable aux déficits fonciers résultant de dépenses autres que les intérêts d'emprunt. 
> L'imputation est limitée à 10 700 €.

*Propriétaire* **ne peut pas** *imputer* le *DéficitFoncier* à *AdministrationFiscale* envers *RevenuGlobal*
{#art156-I-3-interdiction-foncier-général}

*Propriétaire* **a le droit de** *imputer* le *DéficitFoncier* à *AdministrationFiscale* envers *RevenuFoncier*
{#art156-I-3-imputation-foncier}

*Propriétaire* **a le droit de** *reporter* le *DéficitFoncier* à *AdministrationFiscale* envers *DixAnnées*
{#art156-I-3-report-foncier}

*Propriétaire* **a le droit de** *déduire* le *DéficitFoncier* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *DéficitFoncierHorsIntérêts* <= *PlafondDéficitFoncier*
{#art156-I-3-déduction-limitée}

*Propriétaire* **a le droit de** *déduire* le *DéficitFoncier* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *DéductionsArt31* = *Oui*
et *DéficitFoncierHorsIntérêts* <= *PlafondDéficitFoncierMajoré*
sauf #art156-I-3-déduction-limitée
{#art156-I-3-déduction-plafond-majoré}

*PropriétaireMonumentHistorique* **a le droit de** *déduire* le *DéficitFoncier* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *TypePropriété* = *MonumentHistorique*
sauf #art156-I-3-déduction-limitée
{#art156-I-3-monument-historique}

---

### I.3° - Plafond majoré pour rénovation énergétique

> La limite est rehaussée, sans pouvoir excéder 21 400 € par an, à concurrence 
> du montant des dépenses déductibles de travaux de rénovation énergétique 
> permettant à un bien de passer d'une classe énergétique E, F ou G à une classe 
> de performance énergétique A, B, C ou D, au plus tard le 31 décembre 2027.

*Propriétaire* **a le droit de** *déduire* le *DéficitFoncier* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *TravauxRénovationÉnergétique* = *Oui*
et (*ClasseInitiale* = *E* ou *ClasseInitiale* = *F* ou *ClasseInitiale* = *G*)
et (*ClasseFinale* = *A* ou *ClasseFinale* = *B* ou *ClasseFinale* = *C* ou *ClasseFinale* = *D*)
et *DéficitFoncierHorsIntérêts* <= *PlafondRénovationÉnergétique*
sauf #art156-I-3-déduction-limitée
{#art156-I-3-rénovation-énergétique}

*Propriétaire* **doit** *reconstituer* le *RevenuImposable* à *AdministrationFiscale*
lorsque *TravauxRénovationÉnergétique* = *Oui*
et *Propriétaire* n'a pas *JustificationClassement*
et *DateCourante* > *DateLimiteJustification*
{#art156-I-3-reconstitution-défaut}

*Propriétaire* **doit** *reconstituer* le *RevenuImposable* à *AdministrationFiscale*
lorsque *CessationLocation* = *Oui*
et *DuréeLocation* < 3 *Années*
et non (*Invalidité* = *Oui* ou *Licenciement* = *Oui* ou *Décès* = *Oui*)
{#art156-I-3-reconstitution-cessation}

---

### II.1° ter - Charges foncières monuments historiques

> Les charges foncières afférentes aux immeubles classés monuments historiques 
> ou inscrits au titre des monuments historiques.

*PropriétaireMonumentHistorique* **a le droit de** *déduire* la *ChargeFoncière* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque (*ImmeubleClasséMonumentHistorique* = *Oui* ou *ImmeubleInscritMonumentHistorique* = *Oui*)
et (*LabelFondationPatrimoine* = *Oui* et *AvisFavorable* = *Oui*)
{#art156-II-1ter-charges-monuments}

---

## LAYER 2: OPERATIONAL

### Déficit foncier

## *DéficitFoncierDéductible*

> Déficit foncier déductible avec plafonds selon le type de propriété

Case:
  - *TypePropriété* = *MonumentHistorique*:
      *DéficitFoncier*
  - *DéductionsArt31* = *Oui*:
      min(*DéficitFoncierHorsIntérêts*, *PlafondDéficitFoncierMajoré*)
  - Default:
      min(*DéficitFoncierHorsIntérêts*, *PlafondDéficitFoncier*)

---

## *DéficitFoncierRénovationÉnergétique*

> Plafond majoré pour travaux de rénovation énergétique

Case:
  - *TravauxRénovationÉnergétique* = *Oui* AND *ClasseInitiale* = *E* OR *ClasseInitiale* = *F* OR *ClasseInitiale* = *G*:
      Case:
        - *ClasseFinale* = *A* OR *ClasseFinale* = *B* OR *ClasseFinale* = *C* OR *ClasseFinale* = *D*:
            min(
              *DéficitFoncierHorsIntérêts*,
              *PlafondDéficitFoncier* + min(*MontantTravauxRénovation*, *PlafondRénovationÉnergétique* - *PlafondDéficitFoncier*)
            )
        - Default: 0 EUR
  - Default: 0 EUR

---

## *ReportDéficitFoncier*

> Report du déficit foncier sur les revenus fonciers des années suivantes

*ReportDéficitFoncier* = min(*DéficitFoncier*, *RevenuFoncierAnnéeCourante*)

---

## Notes d'implémentation

### Domaine

Ce module encode les dispositions de l'Article 156 du CGI relatives aux déficits fonciers, incluant les règles spécifiques pour les monuments historiques et la rénovation énergétique.

### Références légales

- **Code Général des Impôts, Article 156, I.3°** - Déficits fonciers
- **Code Général des Impôts, Article 31** - Déductions spécifiques (f et o)

### Règles de plafonnement

1. **Plafond standard**: 10 700 EUR pour les déficits hors intérêts d'emprunt
2. **Plafond majoré**: 15 300 EUR pour logements avec déductions art. 31 f ou o
3. **Plafond rénovation énergétique**: Jusqu'à 21 400 EUR pour travaux permettant passage de classe E/F/G vers A/B/C/D (avant 31/12/2027)
4. **Monuments historiques**: Pas de plafond

### Obligations de reconstitution

Le contribuable doit reconstituer le revenu imposable si:
- Absence de justification du nouveau classement énergétique avant le 31/12/2027
- Cessation de location dans les 3 ans (sauf invalidité, licenciement, décès)

### Paramètres

- *PlafondDéficitFoncier* = 10 700 *EUR*
- *PlafondDéficitFoncierMajoré* = 15 300 *EUR*
- *PlafondRénovationÉnergétique* = 21 400 *EUR*
- *DuréeReportDéficitFoncier* = 10 *Années*
- *DateLimiteRénovationÉnergétique* = 31/12/2027

### Statut de vérification

- [ ] Vérification SMT (cohérence logique normative)
- [ ] Vérification exhaustiveness (procédures opérationnelles)
- [ ] Vérification type checking (unités et types)
- [ ] Vérification computation graph (pas de cycles)

### Changelog

**Version 3.0 (2026-05-05)**
- Extraction du module déficits fonciers depuis CGI.Art.156.opennorm.md
- Module autonome avec manifest complet
- Conservation de la cohérence norms/procédures
- Inclusion des règles de rénovation énergétique et monuments historiques