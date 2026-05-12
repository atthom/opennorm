# Article 156 du Code Général des Impôts

> Version en vigueur depuis le 21 février 2026
> Encodage OpenNorm - Document Principal

## Manifest

**OpenNorm:** 0.1
**Package:** cgi.art156
**Package-type:** regulation
**Version:** 3.0
**Status:** review
**Language:** FR
**Imports:**

- stdlib/frameworks/universal/core@2.0
- CGI.Art.156.deficits-agricoles@3.0
- CGI.Art.156.deficits-bic@3.0
- CGI.Art.156.deficits-bnc@3.0
- CGI.Art.156.deficits-fonciers@3.0
- CGI.Art.156.deficits-capitaux@3.0
- CGI.Art.156.charges-deductibles@3.0

---

## Vue d'ensemble

L'Article 156 du Code Général des Impôts établit les règles de calcul du revenu imposable en définissant:

1. **Les déficits déductibles** (Section I) - Règles d'imputation et de report des déficits par catégorie
2. **Les charges déductibles** (Section II) - Charges pouvant être déduites du revenu global

Ce document principal orchestre l'ensemble des modules thématiques qui composent l'Article 156.

---

## Taxonomies

### Role Taxonomy

- AnyRole
  - FoyerFiscal
  - Contribuable
  - AdministrationFiscale
  - Exploitant
    - ExploitantAgricole
  - ChefExploitationAgricole
  - Propriétaire
    - PropriétaireMonumentHistorique
  - Loueur
    - LoueurMeublé
      - LoueurMeubléNonProfessionnel
  - TravailleurIndépendant
  - Mutualiste

### Action Taxonomy

- AnyAction
  - établir
  - calculer
  - déduire
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
    - Revenu
      - RevenuGlobal
      - RevenuImposable
    - Déficit
      - DéficitGénéral
      - DéficitAgricole
      - DéficitBIC
      - DéficitBNC
      - DéficitFoncier
      - DéficitCapitauxMobiliers
    - Charge
      - PensionAlimentaire
      - IntérêtEmprunt
      - ChargeFoncière
      - CotisationSociale
      - Prime
      - AvantageNature
  - OpenNormVariables
    - Constants
      - DuréeReport = 6 *Années*
    - Parameters
      - RevenuGlobal = *EUR* (required)
    - ComputedVariables
      - RevenuImposable = *EUR*
      - TotalDéficitsReportables = *EUR*

---

## LAYER 1: NORMATIVE

### Norme principale - Établissement de l'impôt

> L'impôt sur le revenu est établi d'après le montant total du revenu net annuel 
> dont dispose chaque foyer fiscal.

*FoyerFiscal* **a le droit de** *établir* le *RevenuImposable* à *AdministrationFiscale*
{#art156-base}

---

### I. Déductions de déficits

#### Déficit général - Report sur 6 ans

> Du déficit constaté pour une année dans une catégorie de revenus ; 
> si le revenu global n'est pas suffisant pour que l'imputation puisse être 
> intégralement opérée, l'excédent du déficit est reporté successivement 
> sur le revenu global des années suivantes jusqu'à la sixième année inclusivement.

*FoyerFiscal* **a le droit de** *imputer* le *DéficitGénéral* à *AdministrationFiscale* envers *RevenuGlobal*
{#art156-I-déficit-général}

*FoyerFiscal* **a le droit de** *reporter* le *DéficitGénéral* à *AdministrationFiscale* envers *SixAnnées*
lorsque *DéficitGénéral* > *RevenuGlobal*
{#art156-I-report-6ans}

---

## LAYER 2: OPERATIONAL

### Calcul du revenu imposable

## *RevenuImposable*

> Calcul du revenu imposable après déduction de tous les déficits et charges

*RevenuImposable* = *RevenuGlobal*
                    - *DéficitAgricoleImputable*
                    - *DéficitBICImputable*
                    - *DéficitBICLiquidationJudiciaire*
                    - *DéficitLMNPImputable*
                    - *DéficitLMNPProfessionnelDébutant*
                    - *DéficitBNCImputable*
                    - *DéficitFoncierDéductible*
                    - *DéficitFoncierRénovationÉnergétique*
                    - *DéficitCapitauxMobiliersImputable*
                    - *PensionAlimentaireDéductible*
                    - *PensionAlimentaireEnfantMajeur*
                    - *ContributionChargesMariage*
                    - *RenteEnfant*
                    - *AvantagesNatureDéductibles*
                    - *CotisationsSocialesDéductibles*
                    - *CotisationsTravailleursIndépendants*
                    - *PrimesAssurancesAgricoles*
                    - *CotisationsAssuranceGroupeAgricole*

---

## *TotalDéficitsReportables*

> Agrégation de tous les déficits reportables sur les années suivantes

*TotalDéficitsReportables* = sum(
  *ReportDéficitAgricole*,
  *DéficitBICRestantÀReporter*,
  *ReportDéficitBNC*,
  *ReportDéficitFoncier*,
  *ReportDéficitCapitauxMobiliers*
)

---

## Structure modulaire

L'Article 156 est organisé en modules thématiques indépendants:

### 1. Déficits Agricoles
**Package:** `cgi.art156.deficits-agricoles@3.0`
- Déficits agricoles avec seuil de revenus (I.1°)
- Assurances accidents agricoles (II.11°)
- Assurances de groupe agricoles (II.13°)

### 2. Déficits BIC
**Package:** `cgi.art156.deficits-bic@3.0`
- Déficits BIC sans participation personnelle (I.1° bis)
- Déficits location meublée non professionnelle (I.1° ter)
- Cotisations travailleurs indépendants (II.10°)

### 3. Déficits BNC
**Package:** `cgi.art156.deficits-bnc@3.0`
- Déficits professions non commerciales (I.2°)
- Règles spécifiques professions libérales

### 4. Déficits Fonciers
**Package:** `cgi.art156.deficits-fonciers@3.0`
- Déficits fonciers avec plafonds (I.3°)
- Rénovation énergétique
- Monuments historiques (II.1° ter)

### 5. Déficits Capitaux Mobiliers
**Package:** `cgi.art156.deficits-capitaux@3.0`
- Déficits capitaux mobiliers (I.8°)

### 6. Charges Déductibles
**Package:** `cgi.art156.charges-deductibles@3.0`
- Intérêts d'emprunts historiques (II.1°)
- Pensions alimentaires (II.2°)
- Avantages en nature personnes âgées (II.2° ter)
- Cotisations de sécurité sociale (II.4°)
- Retraite mutualiste du combattant (II.5°)

---

## Notes d'implémentation

### Architecture

Ce document principal sert d'orchestrateur pour l'ensemble des modules de l'Article 156. Chaque module est autonome avec:
- Son propre manifest
- Ses taxonomies spécifiques
- Ses normes (Layer 1) et procédures (Layer 2) cohérentes
- Sa documentation intégrée

### Références légales

- **Code Général des Impôts, Article 156**
- Version en vigueur depuis le 21 février 2026
- Modifié par LOI n°2026-103 du 19 février 2026 - art. 47 (V)
- Modifié par LOI n°2026-103 du 19 février 2026 - art. 53

### Références croisées

- Articles 205-211 du Code Civil (obligations alimentaires)
- Articles 275, 276, 278, 279-1 du Code Civil (pensions divorce)
- Article 214 du Code Civil (contribution charges mariage)
- Article 373-2-3 du Code Civil (rente enfant)
- Article L. 815-9 CSS (plafond ASPA)
- Articles L. 621-1 et L. 622-2 CSS (cotisations indépendants)
- Articles L. 752-1 à L. 752-21 CRPM (assurances agricoles)
- Article L. 144-1 du code des assurances (assurances groupe)
- Article 154 bis-0 A CGI (limites cotisations)
- Article 155 CGI (statut professionnel location meublée)
- Article 196 B CGI (abattement pension enfant majeur)
- Article 199 sexdecies CGI (crédit impôt ascendants)
