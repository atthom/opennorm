# Article 156 du Code Général des Impôts - Déficits BIC

> Version en vigueur depuis le 21 février 2026
> Encodage OpenNorm - Module: Déficits BIC et Location Meublée

## Manifeste

**OpenNorm:** 0.1
**Paquet:** cgi.art156.deficits-bic
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
  - Foyer Fiscal
  - Travailleur Indépendant
  - Loueur
    - Loueur Meublé
      - Loueur Meublé Professionnel
      - Loueur Meublé Non Professionnel
  - Administration Fiscale

### Taxonomie des Actions

- AnyAction
  - Fiscal
    - imputer
    - reporter
    - déduire

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
    - Booléen
    - ParticipationPersonnelleType (*Absente*, *Présente*)
    - StatutLocationType (*NonProfessionnel*, *ProfessionnelDèsDébut*)
  - Concepts
    - Revenu
      - Revenu Brut
    - Déficit
      - Déficit BIC
    - Charge
      - Cotisation Sociale
  - OpenNormVariables
    - Constants
      - Durée Report = 6 *Années*
      - Durée Report LMNP = 10 *Années*
      - Nombre Années Imputation = 3 *Années*
    - Parameters
      - Participation Personnelle = *ParticipationPersonnelleType*
      - Déficit BIC = *EUR*
      - Liquidation Judiciaire = *Booléen* default *Oui*
      - Actifs Cédés = *Booléen* default *Non*
      - Déficit BIC Restant À Reporter = *EUR*
      - Statut Location = *StatutLocationType*
      - Revenu Location Meublée Non Pro = *EUR*
      - Année Location = *Années*
      - Charges Avant Commencement = *EUR*
      - Montant Cotisations L621_1 = *EUR*
      - Montant Cotisations L622_2 = *EUR*
    - ComputedVariables
      - Déficit BIC Imputable = *EUR*
      - Déficit BIC Liquidation Judiciaire = *EUR*
      - Déficit LMNP Imputable = *EUR*
      - Déficit LMNP Professionnel Débutant = *EUR*
      - Cotisations Travailleurs Indépendants = *EUR*

---

## COUCHE 1 : NORMATIVE

### I.1° bis - Déficits BIC sans participation personnelle {art156-i-1bis-deficits-bic-sans-participation}

> N'est pas autorisée l'imputation des déficits provenant, directement ou indirectement, 
> des activités relevant des bénéfices industriels ou commerciaux lorsque ces activités 
> ne comportent pas la participation personnelle, continue et directe de l'un des membres 
> du foyer fiscal.

Le *Foyer Fiscal* **a le droit de** *reporter* le *Déficit BIC* envers l'*Administration Fiscale*
lorsque sa *Participation Personnelle* = *Absente*
exception de art156-norme-principale
---

### I.1° ter - Déficits de location meublée non professionnelle {art156-i-1ter-deficits-location-meublee-non-pro}

> Des déficits du foyer fiscal provenant de l'activité de location directe ou indirecte 
> de locaux d'habitation meublés ou destinés à être loués meublés lorsque l'activité 
> n'est pas exercée à titre professionnel. Ces déficits s'imputent exclusivement 
> sur les revenus provenant d'une telle activité au cours de celles des dix années suivantes.

Le *Loueur Meublé Non Professionnel* **a le droit de** *reporter* le *Déficit BIC* envers l'*Administration Fiscale*
lorsque son *Statut Location* = *Non Professionnel*
exception de art156-norme-principale
---

## COUCHE 2 : OPÉRATIONNELLE

### Déficit BIC sans participation

## *Déficit BIC Imputable*

> Déficit BIC imputable selon la participation personnelle du foyer fiscal

Case:
  - *Participation Personnelle* = *Absente*:
      0 EUR
  - *Participation Personnelle* = *Présente*:
      *Déficit BIC*
  - Default: 0 EUR

---

## *Déficit BIC Liquidation Judiciaire*

> Exception liquidation judiciaire - déficit BIC imputable sur revenu global

Case:
  - *Liquidation Judiciaire* = *Oui* AND *Actifs Cédés* = *Oui*:
      *Déficit BIC Restant À Reporter*
  - Default: 0 EUR

---

### Déficit LMNP

## *Déficit LMNP Imputable*

> Déficit de location meublée non professionnelle imputable

Case:
  - *Statut Location* = *Non Professionnel*:
      min(*Déficit BIC*, *Revenu Location Meublée Non Pro*)
  - Default: 0 EUR

---

## *Déficit LMNP Professionnel Débutant*

> Imputation par tiers des charges avant commencement pour activité professionnelle dès le début

Case:
  - *Statut Location* = *Professionnel Dès Début* AND *Année Location* <= *Nombre Années Imputation*:
      *Charges Avant Commencement* / 3
  - Default: 0 EUR

---

### Cotisations travailleurs indépendants

## *Cotisations Travailleurs Indépendants*

> Cotisations des travailleurs indépendants (articles L. 621-1 et L. 622-2 CSS)

*Cotisations Travailleurs Indépendants* = *Montant Cotisations L621_1* + *Montant Cotisations L622_2*

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
