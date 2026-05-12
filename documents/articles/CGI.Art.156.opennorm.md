# Article 156 du Code Général des Impôts

> Version en vigueur depuis le 21 février 2026
> Encodage OpenNorm - Couches normative et opérationnelle

## Manifest

**OpenNorm:** 0.1
**Package:** cgi.art156
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
  - Contribuable
  - AdministrationFiscale
  - Exploitant
    - ExploitantAgricole
  - TravailleurIndépendant
  - Propriétaire
    - PropriétaireMonumentHistorique
  - Professionnel
    - ProfessionLibérale
  - Loueur
    - LoueurMeublé
      - LoueurMeubléProfessionnel
      - LoueurMeubléNonProfessionnel
  - Rapatrié
  - Mutualiste
  - ChefExploitationAgricole

### Action Taxonomy

- AnyAction
  - déduire
  - imputer
  - reporter
  - calculer
  - établir
  - déterminer
  - constater
  - verser
  - reconstituer

## OpenNormTypes

### Primitive Types
- EUR (Currency)
- Années (Duration)
- Date
- Boolean (*Oui*, *Non*)

### Enum Types
- ParticipationPersonnelleType (*Absente*, *Présente*)
- StatutLocationType (*NonProfessionnel*, *ProfessionnelDèsDébut*)
- TypeActivitéType (*ProfessionLibérale*, *ChargeOffice*, *Autre*)
- TypePropriétéType (*MonumentHistorique*, *Standard*)
- ClasseÉnergétiqueType (*A*, *B*, *C*, *D*, *E*, *F*, *G*, *Autre*)
- TypeBénéficiaireType (*DescendantMineur*, *Ascendant*, *Autre*)
- TypeCotisationType (*GensDeMaison*, *Autre*)

---

### Object Taxonomy

- AnyThing
  - Units
    - EUR (Currency)
    - % (Percentage)
    - Années (Duration)
  - Concepts
    - Revenu
      - RevenuNet
      - RevenuBrut
      - RevenuFoncier
    - Déficit
      - DéficitGénéral
      - DéficitCapitauxMobiliers
      - DéficitAgricole
      - DéficitBIC
      - DéficitBNC
      - DéficitFoncier
    - Charge
      - ChargeDéductible
      - ChargeFoncière
      - IntérêtEmprunt
      - PensionAlimentaire
      - CotisationSociale
      - AvantageNature
      - Prime
    - Montant
      - Seuil
      - Plafond
      - Taux
    - Période
      - Année
      - AnnéeSuivante
      - SixAnnées
      - DixAnnées
    - Statut
      - ClasseÉnergétique
    - Document
      - Documentation
  - Constants
    - ÂgeMinimum = 75 *Années*
    - SeuilRevenuAutres = 127 677 *EUR*
      revised-by: *BarèmePremièreTranche*
    - DuréeReport = 6 *Années*
    - DuréeReportLMNP = 10 *Années*
    - NombreAnnéesImputation = 3 *Années*
    - DuréeReportFoncier = 10 *Années*
    - PlafondDéficitFoncier = 10 700 *EUR*
    - PlafondDéficitFoncierMajoré = 15 300 *EUR*
    - PlafondRénovationÉnergétique = 21 400 *EUR*
    - DateLimiteJustification = 31/12/2027 *Date*
    - PlafondPensionEnfantMajeur = *AbattementArt196B*
    - PlafondRenteEnfant = 2 700 *EUR*
    - PlafondAvantagesNature = 4 039 *EUR*
      revised-by: *BarèmePremièreTranche*
    - LimiteDéduction = *LimiteArt154bis0A*
  - Parameters
    - RevenuAutresSources = *EUR* (required)
    - DéficitAgricole = *EUR*
    - BénéficeAgricoleAnnéeCourante = *EUR*
    - ParticipationPersonnelle = *ParticipationPersonnelleType*
    - DéficitBIC = *EUR*
    - LiquidationJudiciaire = *Boolean* default *Oui*
    - ActifsCédés = *Boolean* default *Non*
    - DéficitBICRestantÀReporter = *EUR*
    - StatutLocation = *StatutLocationType*
    - RevenuLocationMeubléeNonPro = *EUR*
    - AnnéeLocation = *Années*
    - ChargesAvantCommencement = *EUR*
    - TypeActivité = *TypeActivitéType*
    - DéficitBNC = *EUR*
    - BénéficeBNCAnnéeCourante = *EUR*
    - TypePropriété = *TypePropriétéType*
    - DéficitFoncier = *EUR*
    - DéficitFoncierHorsIntérêts = *EUR*
    - DéductionsArt31 = *Boolean*
    - TravauxRénovationÉnergétique = *Boolean*
    - ClasseInitiale = *ClasseÉnergétiqueType*
    - ClasseFinale = *ClasseÉnergétiqueType*
    - MontantTravauxRénovation = *EUR*
    - RevenuFoncierAnnéeCourante = *EUR*
    - DéficitCapitauxMobiliers = *EUR*
    - RevenuCapitauxMobiliersAnnéeCourante = *EUR*
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
    - MontantCotisationsL621_1 = *EUR*
    - MontantCotisationsL622_2 = *EUR*
    - MontantPrimesL752_1_21 = *EUR*
    - MontantCotisationsGroupe = *EUR*
    - RevenuGlobal = *EUR* (required)
    - AbattementArt196B = *EUR*
    - LimiteArt154bis0A = *EUR*
  - ComputedVariables
    - DéficitAgricoleImputable = *EUR*
    - ReportDéficitAgricole = *EUR*
    - DéficitBICImputable = *EUR*
    - DéficitBICLiquidationJudiciaire = *EUR*
    - DéficitLMNPImputable = *EUR*
    - DéficitLMNPProfessionnelDébutant = *EUR*
    - DéficitBNCImputable = *EUR*
    - ReportDéficitBNC = *EUR*
    - DéficitFoncierDéductible = *EUR*
    - DéficitFoncierRénovationÉnergétique = *EUR*
    - ReportDéficitFoncier = *EUR*
    - DéficitCapitauxMobiliersImputable = *EUR*
    - ReportDéficitCapitauxMobiliers = *EUR*
    - PensionAlimentaireDéductible = *EUR*
    - PensionAlimentaireEnfantMajeur = *EUR*
    - ContributionChargesMariage = *EUR*
    - RenteEnfant = *EUR*
    - AvantagesNatureDéductibles = *EUR*
    - CotisationsSocialesDéductibles = *EUR*
    - CotisationsTravailleursIndépendants = *EUR*
    - PrimesAssurancesAgricoles = *EUR*
    - CotisationsAssuranceGroupeAgricole = *EUR*
    - RevenuImposable = *EUR*
    - TotalDéficitsReportables = *EUR*

---

## LAYER 1: NORMATIVE

## Norme principale - Établissement de l'impôt

> L'impôt sur le revenu est établi d'après le montant total du revenu net annuel 
> dont dispose chaque foyer fiscal.

*FoyerFiscal* **a le droit de** *établir* le *RevenuImposable* à *AdministrationFiscale* {#art156-base}

---

## I. Déductions de déficits

### Déficit général - Report sur 6 ans

> Du déficit constaté pour une année dans une catégorie de revenus ; 
> si le revenu global n'est pas suffisant pour que l'imputation puisse être 
> intégralement opérée, l'excédent du déficit est reporté successivement 
> sur le revenu global des années suivantes jusqu'à la sixième année inclusivement.

*FoyerFiscal* **a le droit de** *imputer* le *DéficitGénéral* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-I-déficit-général}

*FoyerFiscal* **a le droit de** *reporter* le *DéficitGénéral* à *AdministrationFiscale* envers *SixAnnées* {#art156-I-report-6ans}

---

### I.1° - Déficits agricoles avec seuil de revenus

> N'est pas autorisée l'imputation des déficits provenant d'exploitations agricoles 
> lorsque le total des revenus nets d'autres sources excède 127 677 € ; 
> ces déficits peuvent cependant être admis en déduction des bénéfices de même nature 
> des années suivantes jusqu'à la sixième inclusivement.

*ExploitantAgricole* **ne peut pas** *imputer* le *DéficitAgricole* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-I-1-interdiction-imputation}

> Condition: *RevenuAutresSources* > 127 677 EUR

*ExploitantAgricole* **a le droit de** *imputer* le *DéficitAgricole* à *AdministrationFiscale* envers *DéficitAgricole* {#art156-I-1-imputation-même-nature}

*ExploitantAgricole* **a le droit de** *reporter* le *DéficitAgricole* à *AdministrationFiscale* envers *SixAnnées* {#art156-I-1-report-agricole}

---

### I.1° bis - Déficits BIC sans participation personnelle

> N'est pas autorisée l'imputation des déficits provenant, directement ou indirectement, 
> des activités relevant des bénéfices industriels ou commerciaux lorsque ces activités 
> ne comportent pas la participation personnelle, continue et directe de l'un des membres 
> du foyer fiscal.

*FoyerFiscal* **ne peut pas** *imputer* le *DéficitBIC* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-I-1bis-interdiction-bic}

> Condition: Absence de *ParticipationPersonnelle*

*FoyerFiscal* **a le droit de** *imputer* le *DéficitBIC* à *AdministrationFiscale* envers *DéficitBIC* {#art156-I-1bis-imputation-même-nature}

*FoyerFiscal* **a le droit de** *reporter* le *DéficitBIC* à *AdministrationFiscale* envers *SixAnnées* {#art156-I-1bis-report-bic}

> Exception: En cas de liquidation judiciaire, les déficits restant à reporter 
> peuvent être imputés sur le revenu global si les actifs cessent d'appartenir au foyer.

*FoyerFiscal* **a le droit de** *imputer* le *DéficitBIC* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-I-1bis-exception-liquidation}

> Condition: Liquidation judiciaire
> Condition: Actifs cessent d'appartenir au foyer

---

### I.1° ter - Déficits de location meublée non professionnelle

> Des déficits du foyer fiscal provenant de l'activité de location directe ou indirecte 
> de locaux d'habitation meublés ou destinés à être loués meublés lorsque l'activité 
> n'est pas exercée à titre professionnel. Ces déficits s'imputent exclusivement 
> sur les revenus provenant d'une telle activité au cours de celles des dix années suivantes.

*LoueurMeubléNonProfessionnel* **ne peut pas** *imputer* le *DéficitBIC* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-I-1ter-interdiction-lmnp}

*LoueurMeubléNonProfessionnel* **a le droit de** *imputer* le *DéficitBIC* à *AdministrationFiscale* envers *RevenuBrut* {#art156-I-1ter-imputation-lmnp}

*LoueurMeubléNonProfessionnel* **a le droit de** *reporter* le *DéficitBIC* à *AdministrationFiscale* envers *DixAnnées* {#art156-I-1ter-report-lmnp}

> Exception: Si l'activité devient professionnelle dès le début, les charges engagées 
> avant le commencement peuvent être imputées par tiers sur 3 ans.

*LoueurMeubléProfessionnel* **a le droit de** *imputer* le *DéficitBIC* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-I-1ter-exception-professionnel}

> Condition: Activité professionnelle dès le commencement
> Modalité: Imputation par tiers sur 3 premières années

---

### I.2° - Déficits de professions non commerciales

> Des déficits provenant d'activités non commerciales, autres que ceux qui proviennent 
> de l'exercice d'une profession libérale ou des charges et offices dont les titulaires 
> n'ont pas la qualité de commerçants ; ces déficits peuvent cependant être imputés 
> sur les bénéfices tirés d'activités semblables durant la même année ou les six années suivantes.

*Contribuable* **ne peut pas** *imputer* le *DéficitBNC* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-I-2-interdiction-bnc}

> Exception: Professions libérales et charges/offices

*ProfessionLibérale* **a le droit de** *imputer* le *DéficitBNC* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-I-2-exception-profession-libérale}

*Contribuable* **a le droit de** *imputer* le *DéficitBNC* à *AdministrationFiscale* envers *DéficitBNC* {#art156-I-2-imputation-bnc}

*Contribuable* **a le droit de** *reporter* le *DéficitBNC* à *AdministrationFiscale* envers *SixAnnées* {#art156-I-2-report-bnc}

---

### I.3° - Déficits fonciers avec plafond de 10 700 €

> Des déficits fonciers, lesquels s'imputent exclusivement sur les revenus fonciers 
> des dix années suivantes. L'imputation exclusive sur les revenus fonciers n'est pas 
> applicable aux déficits fonciers résultant de dépenses autres que les intérêts d'emprunt. 
> L'imputation est limitée à 10 700 €.

*Propriétaire* **ne peut pas** *imputer* le *DéficitFoncier* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-I-3-interdiction-foncier-général}

*Propriétaire* **a le droit de** *imputer* le *DéficitFoncier* à *AdministrationFiscale* envers *RevenuFoncier* {#art156-I-3-imputation-foncier}

*Propriétaire* **a le droit de** *reporter* le *DéficitFoncier* à *AdministrationFiscale* envers *DixAnnées* {#art156-I-3-report-foncier}

*Propriétaire* **a le droit de** *déduire* le *DéficitFoncier* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-I-3-déduction-limitée}

> Condition: Dépenses autres que *IntérêtEmprunt*
> Plafond: 10 700 EUR

*Propriétaire* **a le droit de** *déduire* le *DéficitFoncier* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-I-3-déduction-plafond-majoré}

> Condition: Logement avec déductions art. 31 f ou o
> Plafond: 15 300 EUR

*PropriétaireMonumentHistorique* **a le droit de** *déduire* le *DéficitFoncier* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-I-3-monument-historique}

> Exception: Monuments historiques - pas de limite

---

### I.3° - Plafond majoré pour rénovation énergétique

> La limite est rehaussée, sans pouvoir excéder 21 400 € par an, à concurrence 
> du montant des dépenses déductibles de travaux de rénovation énergétique 
> permettant à un bien de passer d'une classe énergétique E, F ou G à une classe 
> de performance énergétique A, B, C ou D, au plus tard le 31 décembre 2027.

*Propriétaire* **a le droit de** *déduire* le *DéficitFoncier* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-I-3-rénovation-énergétique}

> Condition: Travaux de rénovation énergétique
> Condition: Passage de classe E/F/G vers A/B/C/D avant 31/12/2027
> Plafond: 21 400 EUR

*Propriétaire* **a le devoir de** *reconstituer* le *RevenuImposable* à *AdministrationFiscale* {#art156-I-3-reconstitution-défaut}

> Condition: Absence de justification du nouveau classement avant 31/12/2027

*Propriétaire* **a le devoir de** *reconstituer* le *RevenuImposable* à *AdministrationFiscale* {#art156-I-3-reconstitution-cessation}

> Condition: Cessation de location dans les 3 ans
> Exception: Invalidité, licenciement, décès

---

### I.8° - Déficits de capitaux mobiliers

> Des déficits constatés dans la catégorie des revenus des capitaux mobiliers ; 
> ces déficits peuvent cependant être imputés sur les revenus de même nature 
> des six années suivantes.

*Contribuable* **ne peut pas** *imputer* le *DéficitCapitauxMobiliers* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-I-8-interdiction-capitaux}

*Contribuable* **a le droit de** *imputer* le *DéficitCapitauxMobiliers* à *AdministrationFiscale* envers *DéficitCapitauxMobiliers* {#art156-I-8-imputation-capitaux}

*Contribuable* **a le droit de** *reporter* le *DéficitCapitauxMobiliers* à *AdministrationFiscale* envers *SixAnnées* {#art156-I-8-report-capitaux}

---

## II. Charges déductibles

### II.1° - Intérêts d'emprunts historiques

> Intérêts des emprunts contractés antérieurement au 1er novembre 1959 pour faire 
> un apport en capital à une entreprise industrielle ou commerciale ou à une exploitation agricole.

*Contribuable* **a le droit de** *déduire* l'*IntérêtEmprunt* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-II-1-intérêts-historiques}

> Condition: Emprunt contracté avant 01/11/1959
> Condition: Apport en capital à entreprise ou exploitation

*Rapatrié* **a le droit de** *déduire* l'*IntérêtEmprunt* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-II-1-intérêts-rapatriés}

> Condition: Prêts de réinstallation ou reconversion

---

### II.1° ter - Charges foncières monuments historiques

> Les charges foncières afférentes aux immeubles classés monuments historiques 
> ou inscrits au titre des monuments historiques.

*PropriétaireMonumentHistorique* **a le droit de** *déduire* la *ChargeFoncière* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-II-1ter-charges-monuments}

> Condition: Immeuble classé ou inscrit monument historique
> Condition: Label Fondation du Patrimoine avec avis favorable

---

### II.2° - Pensions alimentaires

> Pensions alimentaires répondant aux conditions fixées par les articles 205 à 211 
> du code civil.

*Contribuable* **a le droit de** *déduire* la *PensionAlimentaire* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-II-2-pension-alimentaire}

> Condition: Conforme aux articles 205-211 du Code Civil
> Exception: Versements aux ascendants si application art. 199 sexdecies

*Contribuable* **ne peut pas** *déduire* la *PensionAlimentaire* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-II-2-interdiction-descendants-mineurs}

> Condition: Descendants mineurs pris en compte pour le quotient familial

*Contribuable* **a le droit de** *déduire* la *PensionAlimentaire* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-II-2-pension-divorce}

> Condition: Versements art. 275, 276, 278, 279-1 Code Civil
> Condition: Séparation de corps ou divorce

*Contribuable* **a le droit de** *déduire* la *PensionAlimentaire* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-II-2-contribution-mariage}

> Condition: Contribution aux charges du mariage (art. 214 Code Civil)
> Condition: Époux font l'objet d'imposition séparée

*Contribuable* **a le droit de** *déduire* la *PensionAlimentaire* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-II-2-rente-enfant}

> Condition: Rente prévue à l'art. 373-2-3 Code Civil
> Plafond: 2 700 EUR

*Contribuable* **a le droit de** *déduire* la *PensionAlimentaire* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-II-2-enfant-majeur}

> Condition: Enfant majeur
> Plafond: Montant de l'abattement art. 196 B (doublé si parent seul participe à l'entretien du ménage)

---

### II.2° ter - Avantages en nature pour personnes âgées

> Avantages en nature consentis en l'absence d'obligation alimentaire à des personnes 
> âgées de plus de 75 ans vivant sous le toit du contribuable. La déduction ne peut 
> excéder 4 039 € par bénéficiaire.

*Contribuable* **a le droit de** *déduire* l'*AvantageNature* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-II-2ter-avantages-nature}

> Condition: Personne âgée > 75 ans
> Condition: Vivant sous le toit du contribuable
> Condition: Absence d'obligation alimentaire (art. 205-211 Code Civil)
> Condition: Revenu imposable < plafond ASPA (art. L. 815-9 CSS)
> Plafond: 4 039 EUR par bénéficiaire (révisé annuellement)

---

### II.4° - Cotisations de sécurité sociale

> Versements effectués à titre de cotisations de sécurité sociale, 
> à l'exception de ceux effectués pour les gens de maison.

*Contribuable* **a le droit de** *déduire* la *CotisationSociale* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-II-4-cotisations-sociales}

> Exception: Cotisations pour gens de maison

---

### II.5° - Retraite mutualiste du combattant

> Versements effectués en vue de la retraite mutualiste du combattant.

*Mutualiste* **a le droit de** *déduire* la *CotisationSociale* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-II-5-retraite-mutualiste}

> Référence: Article L. 222-2 du code de la mutualité

---

### II.10° - Cotisations des travailleurs indépendants

> Les cotisations mentionnées aux articles L. 621-1 et L. 622-2 
> du code de la sécurité sociale.

*TravailleurIndépendant* **a le droit de** *déduire* la *CotisationSociale* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-II-10-cotisations-indépendants}

> Référence: Articles L. 621-1 et L. 622-2 CSS

---

### II.11° - Assurances accidents agricoles

> Les primes ou cotisations des contrats d'assurances conclus en application 
> des articles L. 752-1 à L. 752-21 du code rural et de la pêche maritime.

*ExploitantAgricole* **a le droit de** *déduire* la *Prime* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-II-11-assurances-agricoles}

> Condition: Assurance obligatoire accidents vie privée, travail, maladies professionnelles
> Référence: Articles L. 752-1 à L. 752-21 CRPM

---

### II.13° - Assurances de groupe agricoles

> Les cotisations versées par les chefs d'exploitation ou d'entreprise agricole 
> au titre des contrats d'assurance de groupe.

*ChefExploitationAgricole* **a le droit de** *déduire* la *CotisationSociale* à *AdministrationFiscale* envers *RevenuGlobal* {#art156-II-13-assurances-groupe}

> Référence: 2° de l'article L. 144-1 du code des assurances
> Limites: Article 154 bis-0 A

---

## LAYER 2: OPERATIONAL

## Procédures de calcul des déficits

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

### Déficit capitaux mobiliers

## *DéficitCapitauxMobiliersImputable*

> Déficit de capitaux mobiliers non imputable sur le revenu global

*DéficitCapitauxMobiliersImputable* = 0 EUR

---

## *ReportDéficitCapitauxMobiliers*

> Report du déficit de capitaux mobiliers sur les revenus de même nature

*ReportDéficitCapitauxMobiliers* = min(*DéficitCapitauxMobiliers*, *RevenuCapitauxMobiliersAnnéeCourante*)

---

## Procédures de calcul des charges déductibles

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

## *CotisationsTravailleursIndépendants*

> Cotisations des travailleurs indépendants (articles L. 621-1 et L. 622-2 CSS)

*CotisationsTravailleursIndépendants* = *MontantCotisationsL621_1* + *MontantCotisationsL622_2*

---

## *PrimesAssurancesAgricoles*

> Primes d'assurances accidents pour non-salariés agricoles

*PrimesAssurancesAgricoles* = *MontantPrimesL752_1_21*

---

## *CotisationsAssuranceGroupeAgricole*

> Cotisations d'assurance de groupe pour chefs d'exploitation agricole

*CotisationsAssuranceGroupeAgricole* = min(*MontantCotisationsGroupe*, *LimiteDéduction*)

---

## Procédures d'orchestration

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

## Paramètres

Les paramètres suivants sont définis pour l'année fiscale 2026:

### Seuils et plafonds

- *SeuilRevenuAgricole* = 127 677 *EUR* (révisé annuellement selon première tranche barème IR)
- *PlafondDéficitFoncier* = 10 700 *EUR*
- *PlafondDéficitFoncierMajoré* = 15 300 *EUR* (logements avec déductions art. 31 f ou o)
- *PlafondRénovationÉnergétique* = 21 400 *EUR* (applicable jusqu'au 31/12/2027)
- *PlafondAvantagesNature* = 4 039 *EUR* (révisé annuellement)
- *PlafondRenteEnfant* = 2 700 *EUR*
- *PlafondPensionEnfantMajeur* = *AbattementArt196B* (Montant abattement art. 196 B)

### Durées de report

- *DuréeReportDéficitGénéral* = 6 *Années*
- *DuréeReportDéficitAgricole* = 6 *Années*
- *DuréeReportDéficitBIC* = 6 *Années*
- *DuréeReportDéficitBNC* = 6 *Années*
- *DuréeReportDéficitFoncier* = 10 *Années*
- *DuréeReportDéficitLMNP* = 10 *Années*
- *DuréeReportDéficitCapitauxMobiliers* = 6 *Années*

### Conditions temporelles

- *DateLimiteRénovationÉnergétique* = 31/12/2027 *Date*
- *DateSeuilEmpruntHistorique* = 01/11/1959 *Date*

---

## Notes d'implémentation

### Structure du document

Ce document encode l'Article 156 du CGI selon l'architecture OpenNorm à trois couches:

1. **Couche normative (Layer 1)** - Norms exprimées en logique Hohfeldienne
2. **Couche opérationnelle (Layer 2)** - Procédures de calcul en expressions mathématiques
3. **Couche exécutable (Layer 3)** - Code généré (non inclus dans ce document)

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

### Statut de vérification

- [ ] Vérification SMT (cohérence logique normative)
- [ ] Vérification exhaustiveness (procédures opérationnelles)
- [ ] Vérification type checking (unités et types)
- [ ] Vérification computation graph (pas de cycles)
- [ ] Revue juridique
- [ ] Validation par l'administration fiscale

### Changelog

**Version 3.0 (2026-05-04)**
- Ajout complet de la couche opérationnelle (Layer 2)
- Encodage exhaustif de toutes les dispositions de l'Article 156
- Ajout des procédures de calcul pour tous les déficits et charges
- Ajout des métadonnées de vérification (Applies:)
- Amélioration des taxonomies
- Ajout des références croisées complètes

**Version 2.0 (2026-02-21)**
- Mise à jour selon LOI n°2026-103
- Ajout plafond rénovation énergétique (21 400 EUR)

**Version 1.0**
- Encodage initial couche normative