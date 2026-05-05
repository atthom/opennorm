# Article 156 du Code Général des Impôts - Charges Déductibles

> Version en vigueur depuis le 21 février 2026
> Encodage OpenNorm - Module: Charges Déductibles

## Manifest

**OpenNorm:** 0.1
**Package:** cgi.art156.charges-deductibles
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
  - Rapatrié
  - Mutualiste

### Action Taxonomy

- AnyAction
  - déduire

---

## OpenNormTypes

### Object Taxonomy

- AnyThing
  - Units
    - EUR (Currency)
    - Années (Duration)
    - Date
    - Boolean (*Oui*, *Non*)
    - TypeBénéficiaireType (*DescendantMineur*, *Ascendant*, *Autre*)
    - TypeCotisationType (*GensDeMaison*, *Autre*)
  - Concepts
    - Charge
      - IntérêtEmprunt
      - PensionAlimentaire
      - CotisationSociale
      - AvantageNature
  - OpenNormVariables
    - Constants
      - ÂgeMinimum = 75 *Années*
      - PlafondPensionEnfantMajeur = *AbattementArt196B*
      - PlafondRenteEnfant = 2 700 *EUR*
      - PlafondAvantagesNature = 4 039 *EUR*
        revised-by: *BarèmePremièreTranche*
    - Parameters
      - TypeBénéficiaire = *TypeBénéficiaireType*
      - PrisEnCompteQuotientFamilial = *Boolean*
      - ApplicationArt199Sexdecies = *Boolean*
      - MontantPensionAlimentaire = *EUR*
      - EnfantMarié = *Boolean*
      - ParticipationSeule = *Boolean*
      - ImpositionSéparée = *Boolean*
      - MontantContribution = *EUR*
      - VersementsRente = *EUR*
      - ÂgeBénéficiaire = *Années*
      - VitSousToitContribuable = *Boolean*
      - RevenuImposableBénéficiaire = *EUR*
      - PlafondASPA = *EUR*
      - MontantAvantagesNature = *EUR*
      - TypeCotisation = *TypeCotisationType*
      - MontantCotisations = *EUR*
      - AbattementArt196B = *EUR*
    - ComputedVariables
      - PensionAlimentaireDéductible = *EUR*
      - PensionAlimentaireEnfantMajeur = *EUR*
      - ContributionChargesMariage = *EUR*
      - RenteEnfant = *EUR*
      - AvantagesNatureDéductibles = *EUR*
      - CotisationsSocialesDéductibles = *EUR*

---

## LAYER 1: NORMATIVE

### II.1° - Intérêts d'emprunts historiques

> Intérêts des emprunts contractés antérieurement au 1er novembre 1959 pour faire 
> un apport en capital à une entreprise industrielle ou commerciale ou à une exploitation agricole.

*Contribuable* **a le droit de** *déduire* l'*IntérêtEmprunt* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *DateEmprunt* < 01/11/1959
et (*ApportEntrepriseIndustrielle* = *Oui* ou *ApportEntrepriseCommerciale* = *Oui* ou *ApportExploitationAgricole* = *Oui*)
{#art156-II-1-intérêts-historiques}

*Rapatrié* **a le droit de** *déduire* l'*IntérêtEmprunt* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *PrêtRéinstallation* = *Oui* ou *PrêtReconversion* = *Oui*
{#art156-II-1-intérêts-rapatriés}

---

### II.2° - Pensions alimentaires

> Pensions alimentaires répondant aux conditions fixées par les articles 205 à 211 
> du code civil.

*Contribuable* **a le droit de** *déduire* la *PensionAlimentaire* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *Contribuable* a *ObligationAlimentaireArt205_211*
et non (*TypeBénéficiaire* = *Ascendant* et *ApplicationArt199Sexdecies* = *Oui*)
{#art156-II-2-pension-alimentaire}

*Contribuable* **ne peut pas** *déduire* la *PensionAlimentaire* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *TypeBénéficiaire* = *DescendantMineur*
et *PrisEnCompteQuotientFamilial* = *Oui*
{#art156-II-2-interdiction-descendants-mineurs}

*Contribuable* **a le droit de** *déduire* la *PensionAlimentaire* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque (*VersementArt275* = *Oui* ou *VersementArt276* = *Oui* ou *VersementArt278* = *Oui* ou *VersementArt279_1* = *Oui*)
et (*SéparationCorps* = *Oui* ou *Divorce* = *Oui*)
{#art156-II-2-pension-divorce}

*Contribuable* **a le droit de** *déduire* la *PensionAlimentaire* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *ContributionChargesMariageArt214* = *Oui*
et *ImpositionSéparée* = *Oui*
{#art156-II-2-contribution-mariage}

*Contribuable* **a le droit de** *déduire* la *PensionAlimentaire* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *RenteArt373_2_3* = *Oui*
et *VersementsRente* <= *PlafondRenteEnfant*
{#art156-II-2-rente-enfant}

*Contribuable* **a le droit de** *déduire* la *PensionAlimentaire* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *TypeBénéficiaire* = *EnfantMajeur*
et *MontantPensionAlimentaire* <= *PlafondPensionEnfantMajeur*
{#art156-II-2-enfant-majeur}

---

### II.2° ter - Avantages en nature pour personnes âgées

> Avantages en nature consentis en l'absence d'obligation alimentaire à des personnes 
> âgées de plus de 75 ans vivant sous le toit du contribuable. La déduction ne peut 
> excéder 4 039 € par bénéficiaire.

*Contribuable* **a le droit de** *déduire* l'*AvantageNature* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *ÂgeBénéficiaire* > *ÂgeMinimum*
et *VitSousToitContribuable* = *Oui*
et non *Contribuable* a *ObligationAlimentaireArt205_211*
et *RevenuImposableBénéficiaire* < *PlafondASPA*
et *MontantAvantagesNature* <= *PlafondAvantagesNature*
{#art156-II-2ter-avantages-nature}

---

### II.4° - Cotisations de sécurité sociale

> Versements effectués à titre de cotisations de sécurité sociale, 
> à l'exception de ceux effectués pour les gens de maison.

*Contribuable* **a le droit de** *déduire* la *CotisationSociale* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque non (*TypeCotisation* = *GensDeMaison*)
{#art156-II-4-cotisations-sociales}

---

### II.5° - Retraite mutualiste du combattant

> Versements effectués en vue de la retraite mutualiste du combattant.
> Référence: Article L. 222-2 du code de la mutualité

*Mutualiste* **a le droit de** *déduire* la *CotisationSociale* à *AdministrationFiscale* envers *RevenuGlobal*
lorsque *Mutualiste* a *RetraiteMutualisteL222_2*
{#art156-II-5-retraite-mutualiste}

---

## LAYER 2: OPERATIONAL

### Pensions alimentaires

## *PensionAlimentaireDéductible*

> Pension alimentaire déductible avec exclusions pour descendants mineurs et ascendants

Case:
  - *TypeBénéficiaire* = *DescendantMineur* AND *PrisEnCompteQuotientFamilial* = *Oui*:
      0 EUR
  - *TypeBénéficiaire* = *Ascendant* AND *ApplicationArt199Sexdecies* = *Oui*:
      0 EUR
  - Default:
      *MontantPensionAlimentaire*

---

## *PensionAlimentaireEnfantMajeur*

> Pension alimentaire pour enfant majeur avec plafond

Case:
  - *EnfantMarié* = *Oui* AND *ParticipationSeule* = *Oui*:
      min(*MontantPensionAlimentaire*, *PlafondPensionEnfantMajeur* × 2)
  - *EnfantMarié* = *Oui*:
      min(*MontantPensionAlimentaire*, *PlafondPensionEnfantMajeur*)
  - Default:
      min(*MontantPensionAlimentaire*, *PlafondPensionEnfantMajeur*)

---

## *ContributionChargesMariage*

> Contribution aux charges du mariage déductible en cas d'imposition séparée

Case:
  - *ImpositionSéparée* = *Oui*:
      *MontantContribution*
  - Default: 0 EUR

---

## *RenteEnfant*

> Rente versée pour constitution du capital prévu à l'article 373-2-3 du Code Civil

*RenteEnfant* = min(*VersementsRente*, *PlafondRenteEnfant*)

---

### Avantages en nature

## *AvantagesNatureDéductibles*

> Avantages en nature pour personnes âgées de plus de 75 ans

Case:
  - *ÂgeBénéficiaire* > *ÂgeMinimum* AND *VitSousToitContribuable* = *Oui* AND *RevenuImposableBénéficiaire* < *PlafondASPA*:
      min(*MontantAvantagesNature*, *PlafondAvantagesNature*)
  - Default: 0 EUR

---

### Cotisations sociales

## *CotisationsSocialesDéductibles*

> Cotisations de sécurité sociale déductibles (hors gens de maison)

Case:
  - *TypeCotisation* = *GensDeMaison*:
      0 EUR
  - Default:
      *MontantCotisations*

---

## Notes d'implémentation

### Domaine

Ce module encode les dispositions de l'Article 156 du CGI relatives aux charges déductibles du revenu global, incluant les pensions alimentaires, avantages en nature, et cotisations sociales.

### Références légales

- **Code Général des Impôts, Article 156, II.1°** - Intérêts d'emprunts historiques
- **Code Général des Impôts, Article 156, II.2°** - Pensions alimentaires
- **Code Général des Impôts, Article 156, II.2° ter** - Avantages en nature personnes âgées
- **Code Général des Impôts, Article 156, II.4°** - Cotisations de sécurité sociale
- **Code Général des Impôts, Article 156, II.5°** - Retraite mutualiste du combattant
- **Code Général des Impôts, Article 196 B** - Abattement pension enfant majeur
- **Code Général des Impôts, Article 199 sexdecies** - Crédit d'impôt ascendants
- **Code Civil, Articles 205-211** - Obligations alimentaires
- **Code Civil, Articles 214, 275, 276, 278, 279-1** - Contributions et pensions
- **Code Civil, Article 373-2-3** - Rente enfant
- **Code de la Sécurité Sociale, Article L. 815-9** - Plafond ASPA
- **Code de la Mutualité, Article L. 222-2** - Retraite mutualiste

### Règles de déduction

#### Pensions alimentaires
1. **Descendants mineurs**: Non déductibles s'ils sont pris en compte pour le quotient familial
2. **Ascendants**: Non déductibles si application de l'art. 199 sexdecies
3. **Enfants majeurs**: Plafond = abattement art. 196 B (doublé si parent seul)
4. **Rente enfant**: Plafond de 2 700 EUR

#### Avantages en nature
Conditions cumulatives:
- Bénéficiaire > 75 ans
- Vivant sous le toit du contribuable
- Pas d'obligation alimentaire
- Revenu imposable < plafond ASPA
- Plafond: 4 039 EUR par bénéficiaire

#### Cotisations sociales
Déductibles sauf cotisations pour gens de maison

### Paramètres

- *ÂgeMinimum* = 75 *Années*
- *PlafondAvantagesNature* = 4 039 *EUR* (révisé annuellement)
- *PlafondRenteEnfant* = 2 700 *EUR*
- *PlafondPensionEnfantMajeur* = *AbattementArt196B*

### Statut de vérification

- [ ] Vérification SMT (cohérence logique normative)
- [ ] Vérification exhaustiveness (procédures opérationnelles)
- [ ] Vérification type checking (unités et types)
- [ ] Vérification computation graph (pas de cycles)

### Changelog

**Version 3.0 (2026-05-05)**
- Extraction du module charges déductibles depuis CGI.Art.156.opennorm.md
- Module autonome avec manifest complet
- Conservation de la cohérence norms/procédures
- Inclusion de toutes les charges déductibles (II.1° à II.5°)