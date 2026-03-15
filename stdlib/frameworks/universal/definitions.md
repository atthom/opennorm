# stdlib / frameworks / universal / definitions

## Manifest

**OpenNorm:** 0.1
**Package:** frameworks.universal.definitions
**Package-type:** framework
**Version:** 2.0
**Implicit-import:** frameworks.universal.core
**Status:** review

> Comprehensive definitions for the universal normative framework.
> Contains 81 definitions covering persons, actions, objects,
> Hohfeldian positions, operators, licensing roles, and economic terms.
>
> These definitions provide the semantic foundation for the taxonomies
> defined in frameworks.universal.core.

---

## Definitions

### Person

**Free form:** Actor, Legal Entity, Party

**Meaning:** Any entity capable of holding a legal position. This includes
natural persons (individuals), legal persons (corporations, states), and
collective persons (groups defined by predicates such as shareholders,
citizens, treaty parties).

### Action

**Free form:** Act

**Meaning:** What a person performs. Actions are atomic primitives defined
in domain-specific stdlib packages (use, distribute, inform, comply, etc.).
Actions are invariant under the operators C, O, E — they are not legal
entities and do not participate in perspective shifts.

### Object

**Free form:** Subject Matter, Res

**Meaning:** What an action is performed on. Objects include physical items
(land, goods, money), digital artifacts (software, data, documents), and
normative constructs (contracts, relationships, capacities). Objects are
invariant under C, O, E.

### Quantifier

**Free form:** Scope Predicate

**Meaning:** A predicate on Person determining which persons a relation
holds against. Standard quantifiers include AnyOne (universal), NoOne
(empty), Only(p) (singleton), and Satisfying(f) (predicate-defined).
Quantifiers form a lattice under subset ordering with NoOne ⊆ Q ⊆ AnyOne.

### Position

**Free form:** Normative Position, Hohfeldian Relation

**Meaning:** The eight Hohfeldian normative positions encoded as a Z₂³
torsor. Each position is represented as a triple of values
(perspective, polarity, order):

- Perspective: whose position (Holder vs Counterparty)
- Polarity: presence vs absence (Positive vs Negative)
- Order: first-order (can/must do) vs second-order (can change positions) (First vs Second)

The eight positions are: Right, Duty, NoRight, Privilege, Power, Liability,
Disability, Immunity.

### Perspective

**Free form:** Viewpoint, Holder-Counterparty Dimension

**Meaning:** One of the three dimensions of the Z₂³ torsor, representing whose normative position is being described. The two values are:

- Holder: the party holding the position
- Counterparty: the party subject to the holder's position

Perspective forms a Z₂ group under the C operator.

### Polarity

**Free form:** Positive-Negative Dimension, Affirmative-Negative

**Meaning:** One of the three dimensions of the Z₂³ torsor, representing whether a position is affirmative or negative. The two values are:

- Positive: the presence of a normative relation (right, duty, power, liability)
- Negative: the absence of a normative relation (no-right, privilege, disability, immunity)

Polarity forms a Z₂ group under the O operator.

### Order

**Free form:** Level, First-Second Order

**Meaning:** One of the three dimensions of the Z₂³ torsor, representing whether a position concerns direct actions or the power to change positions. The two values are:

- First: first-order positions concerning what can or must be done (right, duty, no-right, privilege)
- Second: second-order positions concerning the power to change legal relations (power, liability, disability, immunity)

Order forms a Z₂ group under the E operator.

### C

**Free form:** Correlate, Perspective Flip

**Meaning:** The perspective automorphism in the Z₂³ group. C is an involution (self-inverse) that swaps Holder and Counterparty. When applied to a position, it produces the correlative position from the opposite perspective. For example, C(Right) = Duty.

### O

**Free form:** Opposite, Polarity Flip

**Meaning:** The polarity automorphism in the Z₂³ group. O is an involution (self-inverse) that swaps Positive and Negative. When applied to a position, it produces the opposite position. For example, O(Right) = NoRight.

### E

**Free form:** Elevate, Order Flip

**Meaning:** The order automorphism in the Z₂³ group. E is an involution (self-inverse) that swaps First and Second order. When applied to a position, it elevates or reduces the order. For example, E(Right) = Power.

### holds

**Free form:** Hold

**Meaning:** The primitive normative predicate. `holds H actor action object q`
means that position H holds for actor performing action on object against
persons satisfying quantifier q. This is the bridge between ontology and
normative structure.

### Individual

**Free form:** Natural Person, Human

**Meaning:** A single human being. The most basic type of legal actor with inherent legal capacity.

### LegalPerson

**Free form:** Juridical Person, Legal Entity

**Meaning:** An entity created by law that has legal personality distinct from its members, such as corporations, states, and organizations.

### Corporation

**Free form:** Company, Corporate Entity

**Meaning:** A legal person organized for business purposes with shareholders, limited liability, and perpetual existence.

### State

**Free form:** Government, Sovereign Entity, Nation-State

**Meaning:** A political organization with sovereignty over a territory and its people, having supreme legal authority within its jurisdiction.

### Organization

**Free form:** Association, Institution

**Meaning:** A structured group of people formed for a specific purpose, having legal personality separate from its members.

### Collective

**Free form:** Group, Class of Persons

**Meaning:** A set of persons defined by a predicate rather than enumeration, such as shareholders of a class or citizens of a country.

### ShareholderClass

**Free form:** Class of Shareholders

**Meaning:** All persons holding shares of a particular class in a corporation, forming a collective with specific rights.

### CitizensOfFrance

**Free form:** French Citizens

**Meaning:** Example collective: all persons holding French citizenship, demonstrating predicate-defined groups in law.

### TreatyParties

**Free form:** Signatories, Contracting Parties

**Meaning:** The collective of states or entities that are parties to an international treaty or agreement.

### AnyOne

**Free form:** Universal Quantifier, All Persons

**Meaning:** The universal quantifier encompassing all persons. Represents the broadest scope of a legal relation.

### NoOne

**Free form:** Empty Quantifier, Null Set

**Meaning:** The empty quantifier representing no persons. The bottom element in the quantifier lattice.

### Only

**Free form:** Singleton Quantifier, Specific Person

**Meaning:** A quantifier restricting scope to a single identified person, used for exclusive rights or duties.

### Satisfying

**Free form:** Predicate Quantifier, Those Who

**Meaning:** A quantifier defined by a predicate function, selecting all persons who satisfy the given condition.

### IntellectualProperty

**Free form:** IP Actions

**Meaning:** Category of actions involving intellectual property rights, including use, copying, modification, and distribution of creative works.

### use

**Free form:** Utilize, Exercise

**Meaning:** To employ or exercise something for its intended purpose without creating copies or modifications.

### copy

**Free form:** Reproduce, Duplicate

**Meaning:** To create an identical or substantially similar reproduction of an object, particularly relevant for digital artifacts and creative works.

### modify

**Free form:** Alter, Adapt, Derivative Work

**Meaning:** To change, transform, or create derivative works from an original object.

### distribute

**Free form:** Convey, Disseminate, Transfer

**Meaning:** To make available to others, whether by sale, gift, license, or other means of transfer.

### Economic

**Free form:** Commercial Actions, Financial Transactions

**Meaning:** Category of actions involving economic exchange and commercial relationships.

### buy

**Free form:** Purchase, Acquire

**Meaning:** To acquire ownership or rights through payment of consideration.

### sell

**Free form:** Vend, Dispose

**Meaning:** To transfer ownership or rights in exchange for consideration.

### transfer

**Free form:** Convey, Assign

**Meaning:** To pass ownership, rights, or obligations from one party to another.

### lease

**Free form:** Rent, Let

**Meaning:** To grant temporary possession and use of property in exchange for periodic payments.

### Employment

**Free form:** Labor Actions, Work Relations

**Meaning:** Category of actions related to employment relationships and labor arrangements.

### hire

**Free form:** Employ, Engage

**Meaning:** To enter into an employment relationship, engaging someone to perform work for compensation.

### terminate

**Free form:** Dismiss, End Employment

**Meaning:** To end an employment relationship, either by the employer or employee.

### compensate

**Free form:** Pay, Remunerate

**Meaning:** To provide payment or other consideration for work performed or services rendered.

### Physical

**Free form:** Tangible Property, Corporeal Things

**Meaning:** Category of objects that have physical existence and can be touched or possessed.

### Land

**Free form:** Real Property, Real Estate

**Meaning:** Physical territory including the surface, subsurface, and airspace, traditionally the foundation of property law.

### Goods

**Free form:** Chattels, Personal Property, Movables

**Meaning:** Tangible movable property, distinct from land and intangibles.

### Money

**Free form:** Currency, Legal Tender

**Meaning:** A medium of exchange recognized as payment for debts and obligations.

### Digital

**Free form:** Intangible Digital Assets, Virtual Objects

**Meaning:** Category of objects existing in digital form without physical embodiment.

### Software

**Free form:** Computer Programs, Code

**Meaning:** Instructions for computers, including source code and executable programs, protected by copyright and patent law.

### Data

**Free form:** Information, Digital Records

**Meaning:** Structured or unstructured information in digital form, distinct from the software that processes it.

### Documents

**Free form:** Digital Files, Electronic Documents

**Meaning:** Digital representations of text, images, or other content, whether contracts, licenses, or general documents.

### Normative

**Free form:** Legal Constructs, Juridical Objects

**Meaning:** Category of objects that are legal relationships or capacities rather than physical or digital things.

### Contracts

**Free form:** Agreements, Binding Arrangements

**Meaning:** Legally enforceable agreements between parties creating mutual rights and obligations.

### Relationships

**Free form:** Legal Relations, Status

**Meaning:** Ongoing legal connections between parties, such as employment, agency, or fiduciary relationships.

### Capacities

**Free form:** Legal Powers, Authorities

**Meaning:** The legal ability to perform acts with legal effect, such as the capacity to contract or sue.

### Right

**Free form:** Claim-Right, Entitlement

**Meaning:** First-order, positive, holder perspective position. A claim-right held by one party imposing a correlative duty on another.

### Duty

**Free form:** Obligation, Correlative Duty

**Meaning:** First-order, positive, counterparty perspective position. The correlative of a right, requiring performance or forbearance.

### NoRight

**Free form:** No-Right, Absence of Claim

**Meaning:** First-order, negative, holder perspective position. The absence of a right, correlative to a privilege.

### Privilege

**Free form:** Liberty, Permission

**Meaning:** First-order, negative, counterparty perspective position. Freedom from duty, the correlative of no-right.

### Power

**Free form:** Legal Power, Authority to Change

**Meaning:** Second-order, positive, holder perspective position. The ability to change legal relations by an act of will.

### Liability

**Free form:** Subjection, Exposure to Power

**Meaning:** Second-order, positive, counterparty perspective position. Being subject to another's power to change one's legal position.

### Disability

**Free form:** No-Power, Lack of Authority

**Meaning:** Second-order, negative, holder perspective position. The absence of power to effect legal change.

### Immunity

**Free form:** Freedom from Power, Protection

**Meaning:** Second-order, negative, counterparty perspective position. Freedom from another's power, correlative to disability.

### Operator

**Free form:** Transformation, Automorphism

**Meaning:** A function that transforms positions in the Hohfeldian structure, forming the Z₂³ group.

### Holder

**Free form:** Right-Holder, Position-Holder

**Meaning:** The perspective of the party who holds the normative position, one of two values in the Perspective dimension.

### Counterparty

**Free form:** Obligor, Subject of Position

**Meaning:** The perspective of the party against whom the position is held, the other value in the Perspective dimension.

### Positive

**Free form:** Affirmative, Present

**Meaning:** The affirmative value in the Polarity dimension, indicating the presence of a normative relation.

### Negative

**Free form:** Negative, Absent

**Meaning:** The negative value in the Polarity dimension, indicating the absence of a normative relation.

### First

**Free form:** First-Order, Direct Action

**Meaning:** The first-order value in the Order dimension, concerning what can or must be done directly.

### Second

**Free form:** Second-Order, Power Level

**Meaning:** The second-order value in the Order dimension, concerning the power to change legal relations.

### Institution

**Free form:** Institution

**Meaning:** A formal organisation with persistent identity independent of its members. A type of LegalPerson.

### LicensingRole

**Free form:** Licensing Role

**Meaning:** Category of persons defined by their role in a licensing relationship, including rights holders and licensees.

### RightsHolder

**Free form:** Rights Holder

**Meaning:** A Person who holds specific rights over a subject matter. Actor trait: **CanGrant** — entities that hold and grant rights.

### Licensor

**Free form:** Licensor

**Meaning:** A RightsHolder who grants a license. Precondition: holds the rights being granted. A type of RightsHolder with the **CanGrant** trait.

### Licensee

**Free form:** Licensee

**Meaning:** A Person who receives a license grant. Becomes Recipient upon obtaining a copy of the licensed subject matter. Actor trait: **CanReceive** — entities that receive and obtain rights.

### Recipient

**Free form:** Recipient

**Meaning:** A Licensee who has obtained a copy of the licensed subject matter. Trigger: the moment of obtaining creates the relationship. A type of Licensee with the **CanReceive** trait.

### Sublicensee

**Free form:** Sublicensee

**Meaning:** A Person to whom a Recipient grants further rights under authority of the original license. Bound by sublicense_bound axiom — rights granted cannot exceed rights held. A type of Recipient with the **CanReceive** trait.

### merge

**Free form:** Merge, Combine, Incorporate

**Meaning:** To combine the Software with other software into a unified codebase or executable, where the boundary between components may not be preserved. Distinction from distribute: merge describes the act of combination; distribute describes subsequent sharing of the combined work. The legal significance of merge in license compatibility analysis is contested. When combining software under different licenses, the merge operation is the point at which compatibility must hold. Fuzzy boundary: where incorporate ends and merge begins in dynamic linking. Review trigger: appellate ruling on dynamic linking as derivative work.

### publish

**Free form:** Publish, Make Public, Release

**Meaning:** To make the Software available to the public, whether or not copies are transferred. Includes posting to a public repository, making accessible via network. Relation to distribute: publish does not require physical transfer of a copy; distribute does. In practice many licenses treat them equivalently. The distinction between publish and distribute is relevant in jurisdictions where "making available" is a separate right under copyright law (e.g. EU Copyright Directive Art. 3). In US copyright law the "distribution right" requires actual transfer; "making available" is arguably a separate right under the public display and performance provisions. Fuzzy boundary: when does a private repository become public publication. Review trigger: when contested in legal proceedings.

### sublicense

**Free form:** Sublicense, Relicense

**Meaning:** To grant a third party rights under a license that is itself derived from the original grant. Bound by sublicense_bound — the sublicensee cannot receive rights exceeding those held by the licensor at point of sublicensing. Requires the original license must permit sublicensing.

### deal

**Free form:** Deal, Deal In

**Meaning:** To engage in any transaction involving the Software without restriction. Scope: broader than any single enumerated action; used as a catch-all grant. Note: "deal in the Software without restriction" in the original MIT text is the operative grant from which the enumerated rights are derived. When all enumerated rights are listed, deal is redundant but preserved for completeness.

### free_of_charge

**Free form:** Free of Charge, At No Cost, Without Charge, Gratis

**Meaning:** No monetary or equivalent consideration is required to exercise the granted rights. Applies to the grant itself, not to services built on top. A company may charge for support, hosting, or integration services for MIT-licensed software. The free_of_charge term governs only the permission grant, not downstream commercial activity.

### consideration

**Free form:** For Consideration, For Payment, Compensation

**Meaning:** Something of value exchanged between parties. Includes money, services, other licenses, reciprocal obligations. Licenses are unilateral grants and typically do not require consideration; contracts do.

### royalty

**Free form:** Royalty

**Meaning:** A recurring payment to a rights holder for the right to exercise a licensed right.

### royalty_free

**Free form:** Royalty-Free

**Meaning:** A grant for which no royalty payment is required. Distinct from free_of_charge — royalty-free still permits a one-time upfront fee; free_of_charge permits no fee at any stage.