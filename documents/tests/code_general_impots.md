# Code Général des Impôts - Impôt sur le Revenu

> Réglementation française de l'impôt sur le revenu basée sur le Code général des impôts (CGI).
> Ce document couvre les articles clés relatifs aux obligations fiscales,
> aux tranches d'imposition progressives, aux déductions et au système de quotient familial.
> 
> Basé sur les taux et seuils de 2024.

**OpenNorm:** 0.1
**Package:** CGI.ImpotsRevenu
**Package-type:** ruling
**Version:** 1.0
**Status:** review
**Lang:** FR
**Imports:**

---

## Taxonomies

### Entity Taxonomy

- EntitésJuridiques
  - Individu
  - Personne Morale
    - État
    - Société

### Role Taxonomy

- AnyRole
  - Role Fiscal
    - Contribuable
      - Employé
      - Travailleur Indépendant
      - Retraité
      - Étudiant
    - Foyer Fiscal
      - Parent Isolé
      - Couple Marié
      - Couple Pacsé
    - Administration Fiscale Française
    - Inspecteur des Impôts
    - Percepteur
    - Conseiller Fiscal
    - Expert-Comptable

### Action Taxonomy

- AnyAction
  - Économique
    - déclarer
    - payer
    - déposer
    - déduire
    - diviser
    - appliquer
    - imposer
    - contrôler
    - recouvrer
    - évaluer
    - rembourser
    - prélever

### Object Taxonomy

- Objet
  - Normatif
    - Document Fiscal
      - Impôt sur le Revenu
      - Revenu Imposable
      - Revenu Brut
      - Revenu Net
      - Revenu
      - Déclaration Annuelle
      - Avis d'Imposition
      - Avis d'Évaluation
    - Concept Fiscal
      - Quotient Familial
      - Tranche d'Imposition
      - Crédit d'Impôt
      - Déduction Fiscale
        - Déduction Forfaitaire
        - Frais Professionnels
      - Montant Fiscal
        - Revenu
          - revenu imposable annuel
        - Pourcentage
          - 10% du revenu brut
          - 11% du revenu imposable
          - 30% du revenu imposable
          - 41% du revenu imposable
          - 45% du revenu imposable
        - Quotient
          - 0,5 au quotient familial
        - Frais
          - frais professionnels réels
        - Déduction
          - 10% du revenu brut du Revenu Imposable
          - frais professionnels réels du Revenu Imposable
      - Sanction Fiscale
        - Pénalité
          - Pénalité de Retard
        - Majoration
          - majoration de 40%
          - majoration de 80%
    - Infraction Fiscale
      - Manquement
        - manquement délibéré
      - Fraude
        - abus de droit
        - manœuvres frauduleuses
        - dissimulation de prix
    - Condition
      - Condition de Résidence
        - domicile fiscal
      - Condition Professionnelle
        - frais professionnels
        - dépenses professionnelles
      - Condition Familiale
        - un enfant à charge
        - aucun enfant à charge
        - enfants à charge
      - Condition Temporelle
        - date limite de paiement
      - Condition Procédurale
        - soupçon raisonnable
    - Lieu
      - en France
    - Référence Légale
      - article L64 du livre des procédures fiscales
    - Quotient
      - quotient de 2,0

---

## Article 1 - Obligation de Résidence Fiscale

> Établit l'obligation fondamentale pour les résidents français de payer l'impôt sur le revenu.
> Réf: CGI Article 1

Le *Contribuable* **doit** *payer* un *Impôt sur le Revenu* à l'*Administration Fiscale Française* lorsque *Contribuable* a un *domicile fiscal* *en France*

## Article 13 - Déclaration des Revenus Imposables

> Définit l'obligation de déclarer toutes les sources de revenus.
> Réf: CGI Article 13

Le *Contribuable* **doit** *déclarer* son *Revenu Brut* à l'*Administration Fiscale Française*
lorsque le *Contribuable* a *reçu* un *Revenu*

## Article 197 - Barème Progressif (2024)

> Établit la structure progressive des taux d'imposition sur le revenu.
> Réf: CGI Article 197

### Tranche 1 - Exonération (0%)

Le *Contribuable* **n'a pas le droit de** *payer* d'*Impôt sur le Revenu* à l'*Administration Fiscale Française*
lorsque le *Contribuable* a un *revenu imposable annuel* *jusqu'à 10 777€*

### Tranche 2 - Taux de 11%

Le *Contribuable* **doit** *payer* *11% du revenu imposable* à l'*Administration Fiscale Française*
lorsque le *Contribuable* a un *revenu imposable annuel* *entre 10 778€ et 27 478€*

### Tranche 3 - Taux de 30%

Le *Contribuable* **doit** *payer* *30% du revenu imposable* à l'*Administration Fiscale Française*
lorsque le *Contribuable* a un *revenu imposable annuel* *entre 27 479€ et 78 570€*

### Tranche 4 - Taux de 41%

Le *Contribuable* **doit** *payer* *41% du revenu imposable* à l'*Administration Fiscale Française* lorsque le *Contribuable* a un *revenu imposable annuel* *entre 78 571€ et 168 994€*

### Tranche 5 - Taux de 45%

Le *Contribuable* **doit** *payer* *45% du revenu imposable* à l'*Administration Fiscale Française* lorsque le *Contribuable* a un *revenu imposable annuel* *au-dessus de 168 994€*

## Article 156 - Déduction Forfaitaire

> Permet aux contribuables de déduire les frais professionnels.
> Réf: CGI Article 156

L'*Employé* **a le droit de** *déduire* *10% du revenu brut du Revenu Imposable* envers *Administration Fiscale Française* lorsque l'*Employé* a des *frais professionnels*

### Déduction pour Travailleur Indépendant

Le *Travailleur Indépendant* **a le droit de** *déduire* *frais professionnels réels du Revenu Imposable* envers *Administration Fiscale Française* lorsque le *Travailleur Indépendant* a *documenté* ses *dépenses professionnelles*

## Article 200 - Système du Quotient Familial

> Met en œuvre le système du quotient familial.
> Réf: CGI Article 200

### Quotient Parent Isolé

Le *Parent Isolé* **a le droit de** *diviser* son *Revenu Imposable* par un *quotient de 2,0* lorsque le *Parent Isolé* a *un enfant à charge*

### Quotient de Base Couple Marié

Le *Couple Marié* **a le droit de** *diviser* son *Revenu Imposable* par un *quotient de 2,0* lorsque le *Couple Marié* a *aucun enfant à charge*

### Quotient Enfant Supplémentaire

Le *Foyer Fiscal* **a le droit de** *ajouter* *0,5 au quotient familial* par *enfant à charge* lorsque le *Foyer Fiscal* a des *enfants à charge*

## Article 170 - Déclaration Annuelle

> Établit l'obligation de déposer une déclaration fiscale annuelle.
> Réf: CGI Article 170

Le *Contribuable* **doit** *déposer* une *Déclaration Annuelle* à l'*Administration Fiscale Française* lorsque l'*année fiscale* a *pris fin*

## Article 1727 - Pénalité de Retard

> Définit les pénalités pour paiement tardif des impôts.
> Réf: CGI Article 1727

L'*Administration Fiscale Française* **a le pouvoir de** *imposer* une *Pénalité de Retard* au *Contribuable* lorsque le *Contribuable* a *manqué* la *date limite de paiement*

## Article 1729 - Majorations pour Manquement Délibéré

> Les inexactitudes ou omissions dans une déclaration entraînent l'application de majorations.
> Réf: CGI Article 1729 (Version en vigueur depuis le 01 janvier 2009)

### Majoration de 40% - Manquement Délibéré

L'*Administration Fiscale Française* **a le pouvoir de** *imposer* une *majoration de 40%* au *Contribuable*
lorsque le *Contribuable* a commis un *manquement délibéré* dans sa *Déclaration Annuelle*

### Majoration de 80% - Abus de Droit

L'*Administration Fiscale Française* **a le pouvoir de** *imposer* une *majoration de 80%* au *Contribuable*
lorsque le *Contribuable* a commis un *abus de droit* selon l'*article L64 du livre des procédures fiscales*

### Majoration de 80% - Manœuvres Frauduleuses

L'*Administration Fiscale Française* **a le pouvoir de** *imposer* une *majoration de 80%* au *Contribuable*
lorsque le *Contribuable* a commis des *manœuvres frauduleuses* ou une *dissimulation de prix*
