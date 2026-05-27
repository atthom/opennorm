# Déclaration des Droits de l'Homme et du Citoyen de 1789

> Version adoptée le 26 août 1789 par l'Assemblée nationale constituante
> Encodage OpenNorm - Document constitutionnel fondamental

## Manifeste

**OpenNorm:** 0.1
**Paquet:** ddhc.1789
**Type-paquet:** réglementation
**Version:** 1.0
**Statut:** final
**Langue:** FR
**Juridiction:** FR.Constitution
**Importations:**

- stdlib/frameworks/universal/core@2.0

---

## Vue d'ensemble

La Déclaration des Droits de l'Homme et du Citoyen de 1789 est un texte fondamental de la Révolution française qui énonce les droits naturels et imprescriptibles de l'homme. Elle constitue le préambule de la Constitution française et demeure une référence majeure pour les droits de l'homme.

**Principes fondamentaux:**

1. **Liberté et égalité** (Article 1) - Tous les hommes naissent libres et égaux en droits
2. **Droits naturels** (Article 2) - Liberté, propriété, sûreté, résistance à l'oppression
3. **Souveraineté nationale** (Article 3) - La souveraineté réside dans la Nation
4. **Liberté limitée** (Article 4) - La liberté s'arrête où commence celle d'autrui
5. **Légalité** (Articles 5-8) - Nul ne peut être contraint que par la loi
6. **Présomption d'innocence** (Article 9) - Tout homme est présumé innocent
7. **Liberté d'opinion et d'expression** (Articles 10-11) - Libre communication des pensées
8. **Force publique** (Article 12) - Garantie des droits nécessite une force publique
9. **Contribution publique** (Articles 13-14) - Nécessaire pour la force publique
10. **Responsabilité** (Article 15) - Droit de demander compte aux agents publics
11. **Séparation des pouvoirs** (Article 16) - Condition d'une constitution
12. **Propriété** (Article 17) - Droit inviolable et sacré

---

## Taxonomies

### Taxonomie des Rôles

- AnyRole
  - Homme
  - Citoyen
  - Nation
  - Société
  - AutoritéPublique
    - Législateur
    - AgentPublic
    - ForcePublique
  - Accusé
  - Propriétaire

### Taxonomie des Actions

- AnyAction
  - Droits
    - jouir (enjoy)
    - exercer (exercise)
    - naître (be born)
    - demeurer (remain)
  - Libertés
    - faire (do)
    - dire (say)
    - écrire (write)
    - imprimer (print)
    - communiquer (communicate)
    - manifester (manifest)
  - Participation
    - participer (participate)
    - concourir (contribute)
    - consentir (consent)
    - voter (vote)
  - Résistance
    - résister (resist)
    - s'opposer (oppose)
  - Contrainte
    - contraindre (constrain)
    - arrêter (arrest)
    - détenir (detain)
    - punir (punish)
    - accuser (accuse)
  - Propriété
    - posséder (possess)
    - priver (deprive)
    - exproprier (expropriate)
  - Gouvernance
    - établir (establish)
    - former (form)
    - demander_compte (demand accountability)

### Taxonomie des Objets

- AnyThing
  - Unités
    - Années (Durée)
  - DroitsNaturels
    - Liberté
    - Propriété
    - Sûreté
    - RésistanceOppression
  - ConceptsJuridiques
    - Loi
    - Constitution
    - VolontéGénérale
    - SouverainetéNationale
    - DistinctionSociale
    - UtilitéCommune
  - LibertésCiviles
    - LibertéOpinion
    - LibertéExpression
    - LibertéReligieuse
    - LibertéAction
  - ConceptsPénaux
    - PrésomptionInnocence
    - Arrestation
    - Détention
    - Peine
    - Accusation
  - ConceptsPublics
    - ForcePublique
    - ContributionPublique
    - AdministrationPublique
    - SéparationPouvoirs
  - ConceptsÉconomiques
    - BienPrivé
    - NécessitéPublique

---

## Définitions

### Loi

> La Loi est l'expression de la volonté générale. Elle doit être la même pour tous.

**Type:** ConceptJuridique

**Caractéristiques:**
- Expression de la *VolontéGénérale*
- Égalité d'application
- Seule source de contrainte légitime

### Liberté

> La liberté consiste à pouvoir faire tout ce qui ne nuit pas à autrui.

**Type:** DroitNaturel

**Limites:**
- Déterminées par la *Loi*
- Respect des droits d'autrui

### Société

> Association d'individus unis par des lois communes et une volonté générale.

**Type:** Role

**Fonction:**
- Garantir les droits naturels
- Établir la force publique

---

## COUCHE 1 : NORMATIVE

### Article 1 - Liberté et égalité en droits {ddhc-art1-liberte-egalite}

> Les hommes naissent et demeurent libres et égaux en droits.
> Les distinctions sociales ne peuvent être fondées que sur l'utilité commune.

*Homme* **a le droit de** *naître*, *demeurer* *Liberté*, *ÉgalitéDroits* envers *Société*

*Société* **ne peut pas** *établir* *DistinctionSociale* envers *Homme*
exception de *UtilitéCommune*

---

### Article 2 - Droits naturels et imprescriptibles {ddhc-art2-droits-naturels}

> Le but de toute association politique est la conservation des droits naturels
> et imprescriptibles de l'Homme. Ces droits sont la liberté, la propriété,
> la sûreté, et la résistance à l'oppression.

*Homme* **a le droit de** *jouir* *Liberté* envers *Société*

*Homme* **a le droit de** *jouir* *Propriété* envers *Société*

*Homme* **a le droit de** *jouir* *Sûreté* envers *Société*

*Homme* **a le droit de** *exercer* *RésistanceOppression* envers *AutoritéPublique*

---

### Article 3 - Principe de souveraineté nationale {ddhc-art3-souverainete}

> Le principe de toute Souveraineté réside essentiellement dans la Nation.
> Nul corps, nul individu ne peut exercer d'autorité qui n'en émane expressément.

*Nation* **a le pouvoir de** *exercer* *SouverainetéNationale* sur *Citoyen*

*AutoritéPublique* **ne peut pas** *exercer* *Autorité* sur *Citoyen*

---

### Article 4 - Limites de la liberté {ddhc-art4-limites-liberte}

> La liberté consiste à pouvoir faire tout ce qui ne nuit pas à autrui :
> ainsi, l'exercice des droits naturels de chaque homme n'a de bornes que
> celles qui assurent aux autres Membres de la Société la jouissance de ces mêmes droits.
> Ces bornes ne peuvent être déterminées que par la Loi.

*Homme* **a le droit de** *faire* *LibertéAction* envers *Société*

*Législateur* **a le pouvoir de** *établir* *Loi* sur *Homme*

---

### Article 5 - Domaine de la loi {ddhc-art5-domaine-loi}

> La Loi n'a le droit de défendre que les actions nuisibles à la Société.
> Tout ce qui n'est pas défendu par la Loi ne peut être empêché,
> et nul ne peut être contraint à faire ce qu'elle n'ordonne pas.

*Législateur* **ne peut pas** *interdire* *Action* sur *Citoyen*

*Citoyen* **a le droit de** *faire* *Action* envers *Société*

*AutoritéPublique* **ne peut pas** *contraindre* *Citoyen* envers *Action*

---

### Article 6 - Égalité devant la loi {ddhc-art6-egalite-loi}

> La Loi est l'expression de la volonté générale. Tous les Citoyens ont droit
> de concourir personnellement, ou par leurs Représentants, à sa formation.
> Elle doit être la même pour tous, soit qu'elle protège, soit qu'elle punisse.
> Tous les Citoyens étant égaux à ses yeux sont également admissibles à toutes
> dignités, places et emplois publics, selon leur capacité, et sans autre
> distinction que celle de leurs vertus et de leurs talents.

*Citoyen* **a le droit de** *participer* *FormationLoi* envers *Législateur*

*Loi* **doit** *appliquer* *Égalité* envers *Citoyen*

*Citoyen* **a le droit de** *accéder* *EmploiPublic* envers *Société*

---

### Article 7 - Légalité des arrestations {ddhc-art7-legalite-arrestations}

> Nul homme ne peut être accusé, arrêté ni détenu que dans les cas déterminés
> par la Loi, et selon les formes qu'elle a prescrites. Ceux qui sollicitent,
> expédient, exécutent ou font exécuter des ordres arbitraires, doivent être punis ;
> mais tout citoyen appelé ou saisi en vertu de la Loi doit obéir à l'instant :
> il se rend coupable par la résistance.

*AutoritéPublique* **ne peut pas** *arrêter*, *détenir* *Homme* envers *Société*

*AgentPublic* **doit** *être_puni* envers *Société*

*Citoyen* **doit** *obéir* *Arrestation* envers *AutoritéPublique*

---

### Article 8 - Légalité et proportionnalité des peines {ddhc-art8-legalite-peines}

> La Loi ne doit établir que des peines strictement et évidemment nécessaires,
> et nul ne peut être puni qu'en vertu d'une Loi établie et promulguée
> antérieurement au délit, et légalement appliquée.

*Législateur* **ne peut pas** *établir* *PeineExcessive* sur *Citoyen*

*AutoritéPublique* **ne peut pas** *punir* *Homme* envers *Société*

---

### Article 9 - Présomption d'innocence {ddhc-art9-presomption-innocence}

> Tout homme étant présumé innocent jusqu'à ce qu'il ait été déclaré coupable,
> s'il est jugé indispensable de l'arrêter, toute rigueur qui ne serait pas
> nécessaire pour s'assurer de sa personne doit être sévèrement réprimée par la loi.

*Homme* **a le droit de** *présomption_innocence* envers *Société*

*AutoritéPublique* **ne peut pas** *exercer* *RigueurExcessive* envers *Accusé*

---

### Article 10 - Liberté d'opinion et de religion {ddhc-art10-liberte-opinion}

> Nul ne doit être inquiété pour ses opinions, même religieuses, pourvu que
> leur manifestation ne trouble pas l'ordre public établi par la Loi.

*Homme* **a le droit de** *avoir*, *manifester* *Opinion*, *OpinionReligieuse* envers *Société*

*AutoritéPublique* **ne peut pas** *inquiéter* *Homme* envers *Société*

---

### Article 11 - Liberté d'expression et de communication {ddhc-art11-liberte-expression}

> La libre communication des pensées et des opinions est un des droits les plus
> précieux de l'Homme : tout Citoyen peut donc parler, écrire, imprimer librement,
> sauf à répondre de l'abus de cette liberté dans les cas déterminés par la Loi.

*Citoyen* **a le droit de** *dire*, *écrire*, *imprimer* *Pensée*, *Opinion* envers *Société*

*Citoyen* **doit** *répondre* *AbusDeLiberté* envers *Société*

---

### Article 12 - Nécessité de la force publique {ddhc-art12-force-publique}

> La garantie des droits de l'Homme et du Citoyen nécessite une force publique :
> cette force est donc instituée pour l'avantage de tous, et non pour l'utilité
> particulière de ceux auxquels elle est confiée.

*Société* **doit** *établir* *ForcePublique* envers *Citoyen*

*ForcePublique* **doit** *servir* *AvantageCommun* envers *Société*

*ForcePublique* **ne peut pas** *servir* *UtilitéParticulière* envers *AgentPublic*

---

### Article 13 - Nécessité de la contribution publique {ddhc-art13-contribution-publique}

> Pour l'entretien de la force publique, et pour les dépenses d'administration,
> une contribution commune est indispensable : elle doit être également répartie
> entre tous les citoyens, en raison de leurs facultés.

*Société* **doit** *établir* *ContributionPublique* envers *Citoyen*

*Société* **doit** *répartir* *ContributionPublique* envers *Citoyen*

---

### Article 14 - Consentement à l'impôt {ddhc-art14-consentement-impot}

> Tous les Citoyens ont le droit de constater, par eux-mêmes ou par leurs
> représentants, la nécessité de la contribution publique, de la consentir
> librement, d'en suivre l'emploi, et d'en déterminer la quotité, l'assiette,
> le recouvrement et la durée.

*Citoyen* **a le droit de** *constater* *NécessitéContribution* envers *Législateur*

*Citoyen* **a le droit de** *consentir* *ContributionPublique* envers *Législateur*

*Citoyen* **a le droit de** *suivre* *EmploiContribution* envers *AdministrationPublique*

*Citoyen* **a le droit de** *déterminer* *QuotitéContribution* envers *Législateur*

---

### Article 15 - Responsabilité des agents publics {ddhc-art15-responsabilite}

> La Société a le droit de demander compte à tout Agent public de son administration.

*Société* **a le droit de** *demander_compte* *Administration* de *AgentPublic*

*AgentPublic* **doit** *rendre_compte* *Administration* envers *Société*

---

### Article 16 - Séparation des pouvoirs {ddhc-art16-separation-pouvoirs}

> Toute Société dans laquelle la garantie des Droits n'est pas assurée,
> ni la séparation des Pouvoirs déterminée, n'a point de Constitution.

*Société* **doit** *assurer* *GarantieDroits* envers *Citoyen*

*Société* **doit** *établir* *SéparationPouvoirs* envers *Citoyen*

---

### Article 17 - Droit de propriété {ddhc-art17-propriete}

> La propriété étant un droit inviolable et sacré, nul ne peut en être privé,
> si ce n'est lorsque la nécessité publique, légalement constatée, l'exige
> évidemment, et sous la condition d'une juste et préalable indemnité.

*Propriétaire* **a le droit de** *posséder* *Propriété* envers *Société*

*AutoritéPublique* **ne peut pas** *priver* *Propriétaire* de *Propriété*

*AutoritéPublique* **a le pouvoir de** *exproprier* *Propriété* sur *Propriétaire*
exception de *JusteIndemnité*

---

## Notes d'implémentation

### Contexte historique

La Déclaration des Droits de l'Homme et du Citoyen a été adoptée le 26 août 1789 par l'Assemblée nationale constituante. Elle s'inspire des déclarations des droits américaines et de la philosophie des Lumières.

### Portée juridique

- **Valeur constitutionnelle** : Reconnue par le Conseil constitutionnel en 1971
- **Application directe** : Les principes sont directement invocables devant les juridictions
- **Hiérarchie des normes** : Supérieure aux lois ordinaires

### Références légales

- **Déclaration des Droits de l'Homme et du Citoyen du 26 août 1789**
- **Préambule de la Constitution de 1958**
- **Décision n° 71-44 DC du 16 juillet 1971** (valeur constitutionnelle)

### Références croisées

- Constitution française de 1958
- Convention européenne des droits de l'homme (1950)
- Déclaration universelle des droits de l'homme (1948)
- Charte des droits fondamentaux de l'Union européenne (2000)

### Principes fondamentaux encodés

1. **Liberté** : Droit naturel, limité par la loi et les droits d'autrui
2. **Égalité** : En droits, devant la loi, dans l'accès aux emplois publics
3. **Propriété** : Droit inviolable, sauf nécessité publique avec indemnité
4. **Sûreté** : Protection contre l'arbitraire, présomption d'innocence
5. **Résistance à l'oppression** : Droit de s'opposer à l'autorité illégitime
6. **Souveraineté nationale** : Réside dans la Nation, source de toute autorité
7. **Légalité** : Seule la loi peut contraindre, principe de non-rétroactivité
8. **Liberté d'opinion et d'expression** : Droits fondamentaux avec responsabilité
9. **Consentement à l'impôt** : Participation citoyenne aux décisions fiscales
10. **Séparation des pouvoirs** : Condition d'existence d'une constitution
11. **Responsabilité publique** : Droit de demander compte aux agents publics

### Architecture OpenNorm

Ce document utilise exclusivement la **Couche 1 (Normative)** car la DDHC établit des principes juridiques fondamentaux sans procédures de calcul. Les droits et devoirs sont exprimés en termes hohfeldiens :

- **Droits** (has right to) : Droits naturels, participation politique, propriété
- **Devoirs** (must) : Obéissance à la loi, contribution publique, responsabilité
- **Pouvoirs** (has power to) : Souveraineté nationale, établissement de la loi
- **Privilèges** (has privilege to) : Libertés d'action, d'opinion, d'expression
- **Immunités** (has immunity from) : Protection contre l'arbitraire, présomption d'innocence

### Modélisation des exceptions

Les exceptions sont encodées avec la clause `exception de` pour représenter les limites légitimes aux droits :

- Liberté limitée par les droits d'autrui (Art. 4)
- Distinctions sociales limitées à l'utilité commune (Art. 1)
- Liberté d'expression limitée par l'abus (Art. 11)
- Propriété limitée par la nécessité publique (Art. 17)

### Validation formelle

Ce document peut être validé par le système OpenNorm pour :
- Vérifier la cohérence interne des droits et devoirs
- Détecter les contradictions potentielles
- Analyser les hiérarchies d'exceptions
- Générer des graphes de dépendances entre articles