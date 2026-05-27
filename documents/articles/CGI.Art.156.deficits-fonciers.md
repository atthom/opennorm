# Article 156 du Code Général des Impôts - Déficits Fonciers

> Version en vigueur depuis le 21 février 2026
> Encodage OpenNorm - Module: Déficits Fonciers

## Manifeste

**OpenNorm:** 0.1
**Paquet:** cgi.art156.deficits-fonciers
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
  - Propriétaire
  - AdministrationFiscale

### Taxonomie des Actions

- AnyAction
  - Fiscal
    - imputer
    - reporter
    - déduire
    - reconstituer

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
    - Temps
      - Date
    - Booléen
    - TypePropriétéType (*MonumentHistorique*, *Standard*)
    - ClasseÉnergétiqueType (*A*, *B*, *C*, *D*, *E*, *F*, *G*, *Autre*)
  - Concepts
    - Revenu
      - RevenuFoncier
      - RevenuImposable
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
      - DéductionsArt31 = *Booléen*
      - TravauxRénovationÉnergétique = *Booléen*
      - ClasseInitiale = *ClasseÉnergétiqueType*
      - ClasseFinale = *ClasseÉnergétiqueType*
      - MontantTravauxRénovation = *EUR*
      - RevenuFoncierAnnéeCourante = *EUR*
    - ComputedVariables
      - DéficitFoncierDéductible = *EUR*
      - DéficitFoncierRénovationÉnergétique = *EUR*
      - ReportDéficitFoncier = *EUR*

---

## COUCHE 1 : NORMATIVE

### I.3° - Déficits fonciers avec plafond de 10 700 € {art156-i-3-deficits-fonciers-plafond-10700-eur}

> Des déficits fonciers, lesquels s'imputent exclusivement sur les revenus fonciers 
> des dix années suivantes. L'imputation exclusive sur les revenus fonciers n'est pas 
> applicable aux déficits fonciers résultant de dépenses autres que les intérêts d'emprunt. 
> L'imputation est limitée à 10 700 €.

*Propriétaire* **a le droit de** *reporter* le *DéficitFoncier* envers *AdministrationFiscale*
exception de art156-norme-principale

---

### I.3° - Plafond majoré pour rénovation énergétique {art156-i-3-plafond-majore-renovation-energetique}

> La limite est rehaussée, sans pouvoir excéder 21 400 € par an, à concurrence 
> du montant des dépenses déductibles de travaux de rénovation énergétique 
> permettant à un bien de passer d'une classe énergétique E, F ou G à une classe 
> de performance énergétique A, B, C ou D, au plus tard le 31 décembre 2027.

*Propriétaire* **doit** *reconstituer* le *RevenuImposable* à *AdministrationFiscale*
lorsque *TravauxRénovationÉnergétique* = *Oui*
et *Propriétaire* n'a pas *JustificationClassement*
et *DateCourante* > *DateLimiteJustification*
exception de art156-i-3-report-foncier

*Propriétaire* **doit** *reconstituer* le *RevenuImposable* à *AdministrationFiscale*
lorsque *CessationLocation* = *Oui*
et *DuréeLocation* < 3 *Années*
et non (*Invalidité* = *Oui* ou *Licenciement* = *Oui* ou *Décès* = *Oui*)

---

## COUCHE 2 : OPÉRATIONNELLE

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

