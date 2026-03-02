# OpenNorm — Project Documentation v0.2

> A formal notation for writing governance documents that can be read by humans
> and verified by machines, applicable at any scale from a software license
> to a regulatory compliance framework.

---

## Table of Contents

1. [Vision and Strategic Context](#1-vision-and-strategic-context)
2. [Core Design Philosophy](#2-core-design-philosophy)
3. [Architecture Overview](#3-architecture-overview)
4. [The OpenNorm Document Format](#4-the-opennorm-document-format)
5. [The Stdlib](#5-the-stdlib)
6. [The Parser — Rust + pest](#6-the-parser--rust--pest)
7. [The Checker](#7-the-checker)
8. [The Transpiler — Lean 4](#8-the-transpiler--lean-4)
9. [The Report](#9-the-report)
10. [The LSP — Live Drafting](#10-the-lsp--live-drafting)
11. [The Query Layer](#11-the-query-layer)
12. [CLI Interface](#12-cli-interface)
13. [MVP — MIT License in OpenNorm](#13-mvp--mit-license-in-opennorm)
14. [Phase 2 — GDPR Compliance for Business Processes](#14-phase-2--gdpr-compliance-for-business-processes)
15. [Known Limitations and Honest Boundaries](#15-known-limitations-and-honest-boundaries)
16. [Roadmap](#16-roadmap)

---

## 1. Vision and Strategic Context

### 1.1 The Problem with Legal and Governance Documents

Legal documents — licenses, contracts, charters, regulatory frameworks — share a
structural failure: they are written once, usually under pressure, by a small group,
with no formal mechanism to detect internal contradictions, no versioning system,
no automated testing, and no way to check whether a new clause conflicts with an
existing one.

The consequences are severe:

- **Ambiguity accumulates.** Terms like "distribute" or "reasonable" are left
  undefined. Courts resolve them decades later, inconsistently across jurisdictions.
- **Crisis-driven drafting.** Most governance documents are written under time
  pressure. They solve the immediate problem and leave the next one's attack
  surface wide open.
- **No contradiction detection.** A document can simultaneously grant and prohibit
  the same action, and nobody notices until a court case forces a ruling.
- **Fuzziness is invisible.** Intentional flexibility and accidental gaps look
  identical in natural language. There is no mechanism to distinguish them.
- **Compliance is manual.** Verifying that a business process complies with a
  regulation requires expensive, point-in-time, non-reproducible human review
  that expires the moment anything changes.

### 1.2 The Open Source Parallel

The most secure protocols in the world — TLS, SSH, OpenSSL — are open source.
They are stronger because thousands of people examine them continuously.
Vulnerabilities are found, disclosed, and patched. The code gets better over time
precisely because it is open and attacked.

Legal documents have never been treated this way. OpenNorm applies the open source
model to governance documents:

- Community maintained, forkable, versioned
- Machine-checkable for internal consistency
- Adversarially tested against known historical failure modes
- Transparent about ambiguity rather than hiding it

### 1.3 The Strategic Opportunity

OpenNorm is immediately useful for software licenses, contracts, NGO charters,
and organisational governance. Its most significant near-term commercial application
is regulatory compliance verification — specifically, verifying that business
processes comply with formal regulations such as the GDPR.

The GDPR compliance problem is today solved by consultants with checklists,
privacy-by-design workshops, and GRC platforms built around human attestation.
None of these provide formal, machine-checkable, continuously-valid verification.
OpenNorm does.

A process that was compliant yesterday can be automatically flagged as non-compliant
today because someone added a data-sharing step without a legal basis. The regulation
is encoded once, formally. Every process is checked against the same encoding.
Findings map to specific process elements and specific regulatory articles.
The sorry inventory tells the DPO precisely where human judgment is required and why.

### 1.4 Adoption Path

```
Software licenses      ← MVP. Immediate value. Proves the tool works.
        ↓
GDPR compliance        ← Phase 2. Largest near-term commercial opportunity.
for business processes   Verifies BPMN processes against formal GDPR encoding.
        ↓
Contracts              ← More complex. Two-party dynamics. Framework axioms matter.
        ↓
NGO and org charters   ← First governance documents. Real stakes.
        ↓
Open source project    ← Natural community. DAO overlap.
governance
        ↓
International          ← Treaty language, multi-jurisdiction.
frameworks
```

Each step is independently valuable. Each step stress-tests the tool and generates
the community and credibility needed for the next.

---

## 2. Core Design Philosophy

### 2.1 The Primary Constraint

> **The .md document must be indistinguishable from a well-formatted legal
> document to someone who has never heard of OpenNorm.**

This is not a preference. It is a hard constraint that governs every design
decision. Complexity is hidden in the tooling, never exposed in the document.

A lawyer who receives an OpenNorm document reads a clean, professional legal text.
The formal machinery is invisible infrastructure underneath a human-readable surface.

### 2.2 The Single Source of Truth

> **Every .md file is the source of truth. No hand-written Lean 4 files exist.**

All generated `.lean` files are outputs of the transpiler. They are never edited
directly. They are not committed as sources. If a `.lean` file is lost, it is
regenerated from the `.md` source.

This applies to the stdlib as well. The universal deontic axioms that form the
foundation of the formal system live in `stdlib/frameworks/universal/core.md`,
not in a hand-written `Deontic.lean`. The transpiler generates the Lean 4 preamble
from that file on every run.

### 2.3 Three Term States

Every term in an OpenNorm document is in one of three states:

| State | Syntax | Meaning | Checker Response |
|---|---|---|---|
| **Resolved** | `*distribute*` | Defined in stdlib or local Definitions | Verified against imported package |
| **Fuzzy** | `~~reasonable~~` | Intentionally flexible, declared | Warning issued, review trigger required |
| **Undefined** | `distribute` (plain) | Not declared anywhere | Hard error in review/final mode |

Fuzziness is a feature, not a failure. Intentional flexibility is load-bearing in
legal documents — it allows them to survive changing circumstances without amendment.
OpenNorm does not eliminate fuzziness. It makes fuzziness **explicit, dated, and
scheduled for review** rather than silently accumulating unnoticed.

### 2.4 Warnings vs Errors

```
ERROR   — the document is structurally broken
          must be resolved before finalisation
          example: undefined term used as a condition
          example: fuzzy term not declared in § Known Ambiguities
          example: broken internal reference
          example: permission and prohibition of the same action

WARNING — the document is valid but has known limitations
          human judgment required at point of application
          example: no jurisdiction declared
          example: undecidable case in formal verification
          example: framework conflict between imported packages

INFO    — context that aids interpretation
          example: historical exploit this provision closes
          example: compatibility note with another document
          example: no amendment procedure declared
```

### 2.5 The Translation Gap Principle

The pipeline is:

```
Natural Language → [Human interprets] → OpenNorm encoding → [Lean 4 proves] → Verified
```

Lean 4 verifies the second arrow with mathematical certainty. The first arrow —
the human encoding of natural language into formal terms — is where interpretation
happens and where errors are possible. This gap cannot be eliminated by any
formal system.

OpenNorm addresses the translation gap through the open source model: the encoding
is a public act. If "distribute" is encoded incorrectly, anyone can see the encoding,
propose a correction, and open a pull request. Wrong encodings cannot hide
permanently in a transparent system.

**The formal layer does not claim to be law. It claims to be a consistency checker
for documents that humans write and humans enforce.**

Every report generated by OpenNorm carries:

> *This report was generated by OpenNorm. It is not legal advice. The .md source
> document is the authoritative instrument. Lean 4 output is a consistency
> verification aid.*

### 2.6 No Syntax Beyond Standard Markdown

The only OpenNorm-specific conventions are:

- `*italics*` for resolved terms — reads as emphasis, is a stdlib reference
- `~~strikethrough~~` for fuzzy terms — reads as uncertain, is a formal declaration
- `**bold label:**` for fields — reads as a definition list, is a formal field
- Indented bullet lists for exceptions — reads as sub-points, is a priority chain

Everything else is standard Markdown. Documents render correctly on GitHub, in
any Markdown editor, in any system that accepts Markdown. The formalism is
invisible in the rendered output.

---

## 3. Architecture Overview

### 3.1 The Full Pipeline

```
Input: document.md
        ↓
┌──────────────────────────────────────┐
│  STAGE 0: STDLIB LOADING             │
│  Load frameworks in dependency order │
│  Load definition manifests           │
│  Load clause dependencies            │
│  Generate preamble.lean (output)     │
│  Generate definitions.lean (output)  │
└──────────────────────────────────────┘
        ↓
┌──────────────────────────────────────┐
│  STAGE 1: RUST PARSER                │
│  pest grammar → AST                  │
│  Errors: malformed syntax            │
└──────────────────────────────────────┘
        ↓
┌──────────────────────────────────────┐
│  STAGE 2: RUST CHECKER               │
│  Template conformance                │
│  Term classification                 │
│  Reference resolution                │
│  Import and pin validation           │
│  Structural invariants               │
│  Conflict detection                  │
│  Clause fuzzy term inheritance       │
│  Errors: structural problems         │
└──────────────────────────────────────┘
        ↓
┌──────────────────────────────────────┐
│  STAGE 3: RUST TRANSPILER            │
│  AST → document.lean (output)        │
│  Deontic propositions                │
│  Priority chains from indentation    │
│  sorry stubs for fuzzy terms only    │
└──────────────────────────────────────┘
        ↓
┌──────────────────────────────────────┐
│  STAGE 4: LEAN 4 COMPILER            │
│  Subprocess invocation               │
│  Type checking                       │
│  Contradiction detection             │
│  Proof verification                  │
│  sorry inventory                     │
└──────────────────────────────────────┘
        ↓
┌──────────────────────────────────────┐
│  STAGE 5: REPORT BUILDER             │
│  Translates all stage outputs        │
│  into unified human report           │
│  Output: document_report.md          │
└──────────────────────────────────────┘
```

### 3.2 Repository Structure

```
opennorm/
├── Cargo.toml
├── src/
│   ├── main.rs              ← CLI entry point
│   ├── openlex.pest         ← the grammar (authoritative format spec)
│   ├── parser.rs            ← pest → AST
│   ├── ast.rs               ← AST type definitions
│   ├── checker.rs           ← structural validation
│   ├── resolver.rs          ← term, import, and clause resolution
│   ├── transpiler.rs        ← AST → Lean 4
│   ├── report.rs            ← report generation
│   ├── bpmn.rs              ← BPMN 2.0 reader (Phase 2)
│   ├── lsp.rs               ← LSP server mode
│   └── query.rs             ← document index and queries
├── stdlib/                  ← see § 5
│   ├── frameworks/
│   ├── templates/
│   ├── definitions/
│   └── clauses/
├── licenses/
│   └── mit.md               ← MVP: MIT License in OpenNorm
├── regulations/
│   └── gdpr.md              ← Phase 2: GDPR in OpenNorm
├── tests/
│   ├── contradiction.md     ← deliberately broken, must fail
│   ├── mit_test.lean        ← generated, verified
│   └── gdpr_compliance/     ← BPMN test processes
└── exploit_db/
    └── mit_saas_loophole.md ← known gap as test case
```

### 3.3 Technology Decisions

| Component | Technology | Rationale |
|---|---|---|
| Parser | Rust + pest | PEG grammars are unambiguous by definition. Aligned with OpenNorm's core purpose. |
| Checker | Rust | Same binary as parser. No language bridge. Ships as a single executable. |
| Formal verification | Lean 4 | Modern syntax, Mathlib, excellent DSL-building. sorry workflow maps cleanly to fuzzy terms. |
| Format | Markdown | Universal rendering. Legal scholars can read it. Renders on GitHub. |
| LSP | Standard LSP protocol | Works in VS Code, Neovim, Zed. No custom editor plugin needed. |
| BPMN reader | Rust (xml parsing) | BPMN 2.0 is well-specified XML. Lanes → actors. Tasks → actions. |

**Why no hand-written Lean 4:** every `.lean` file in the repository is generated
by the transpiler from a `.md` source. This is a hard constraint. The stdlib
framework files contain `## Lean4` sections with raw Lean 4 code blocks, but they
are content inside `.md` files — the transpiler extracts and assembles them. A
contributor editing the formal layer edits `.md` files. They never touch generated
`.lean` files directly.

**Why pest over ANTLR:** PEG grammars used by pest are unambiguous by construction —
the first matching rule always wins deterministically. For a tool whose purpose is
to eliminate ambiguity in documents, the parser itself must be incapable of ambiguity.

**Why Lean 4 over Coq:** Lean 4 has more readable generated code, better
metaprogramming for DSL construction, active community growth, and Mathlib.
The `sorry` placeholder workflow cleanly maps to OpenNorm's fuzzy term concept.
Generated code must remain auditable — readability matters.

---

## 4. The OpenNorm Document Format

### 4.1 Document Anatomy

Every OpenNorm document has the same structure:

```markdown
# Document Title

> Human-readable description. Ignored by parser. Rendered for readers.

**OpenNorm:** 0.1
**ID:** unique-identifier
**Version:** 1.0
**Template:** license
**Framework:** common-law        ← optional, loads framework axioms
**Status:** draft
**Imports:**
- stdlib/clauses/warranty/as-is@1.0
- stdlib/definitions/actions/software@1.0

---

## Section Name

**Field:** value
**Another Field:** *resolved-term*

**List Field:**
- *resolved-term*
- ~~fuzzy-term~~
- plain term  ← will produce error or warning

  - exception to parent  ← higher priority in defeasibility chain

> Annotation in blockquote. Human readable. Ignored by parser.

---

## Known Ambiguities

> Fuzzy terms must be declared here with context.

- **fuzzy-term** — reason this is intentionally flexible
  **Review trigger:** when contested in legal proceedings
```

### 4.2 Field Types

**Scalar field:**
```markdown
**Version:** 1.0
```

**Term field:**
```markdown
**To:** any *Person*
```

**List field:**
```markdown
**Permitted:**
- *use*
- *copy*
- *distribute*
```

**Defeasible list** — indentation encodes priority:
```markdown
**Voting rights:**
- *citizen*                          ← priority 1 (base rule)
  - active conviction → none         ← priority 2 (defeats base)
    - sentence served → *citizen*    ← priority 3 (defeats exception)
```

The indentation depth directly becomes the priority integer in the transpiled
Lean 4. No separate priority declaration is needed. The document structure is
the priority structure.

### 4.3 Reference Types

Three URI schemes, each treated differently by the checker:

```markdown
[Apache-2.0](opennorm://licenses/apache2@2.0)
```
Resolved and formally checked. Document must exist in registry. Permissions are
merged and checked for contradictions across the combined document.

```markdown
[French Civil Code Art. 1128](legal://fr/code-civil/art-1128)
```
Resolved for existence only. Framework is known. Compliance is asserted, not proved.
Checker warns if framework definitions conflict with document terms.

```markdown
[§ Obligations](#obligations)
```
Resolved locally. The anchor must exist in this document. A broken internal
reference is a hard error.

### 4.4 Document Modes

```
DRAFT    ← being written
         undefined terms are warnings, not errors
         missing sections are suggestions, not failures
         contradictions are flagged but do not block

REVIEW   ← being checked before ratification
         full validation runs
         all errors must be resolved
         all imports must resolve

FINAL    ← ratified
         all imports must be pinned to explicit versions
         no draft markers remain
         version is frozen
```

---

## 5. The Stdlib

The stdlib is the shared vocabulary and structural layer. It is composed of four
distinct layers with different roles, different audiences, and different
contribution dynamics.

> Every stdlib file is an OpenNorm document. The stdlib eats its own cooking.
> All stdlib packages are formally verified before being marked stable.
> Dissent is recorded permanently. Contradictions block merge.

### 5.1 The Four Layers

```
stdlib/
│
├── frameworks/        ← Layer 1: logical and legal axioms
│   └── ...
│
├── templates/         ← Layer 2: structural schemas
│   └── ...
│
├── definitions/       ← Layer 3: term meanings and Lean 4 types
│   └── ...
│
└── clauses/           ← Layer 4: reusable substantive fragments
    └── ...
```

**Layer 1 — Frameworks** answer: *what structural axioms hold in this legal context?*

**Layer 2 — Templates** answer: *what must this document contain to be a valid
instance of this document type?*

**Layer 3 — Definitions** answer: *what does this term mean precisely enough to
use in a formal proof?*

**Layer 4 — Clauses** answer: *how do people typically say this, tested and
ready to use?*

### 5.2 Layer 1 — Frameworks

Frameworks encode structural axioms that hold across entire document classes
within a given legal system. They are not about individual terms — they are
about how the legal system as a whole works.

The dependency order is always: universal → general framework → specific framework.

```
stdlib/frameworks/
├── universal/
│   └── core.md             ← implicit import, always loaded first
├── common-law/
│   └── contracts.md
├── civil-law/
│   └── contracts.md
├── eu/
│   ├── gdpr.md
│   └── contracts.md
└── international/
    └── uncitral.md
```

**`frameworks/universal/core.md`** is the foundational file. It defines the
deontic modalities (Permitted, Obligated, Forbidden), their core consistency
axioms, and the defeasibility structure. It is the only package that is
implicitly imported by every document — it is never declared, always present.
It is the replacement for the hand-written `Deontic.lean`.

It has the highest review threshold in the entire stdlib. A change here
potentially invalidates every prior verification.

**Framework files contain a `## Lean4` section** with the Lean 4 axioms that
the transpiler extracts to generate `preamble.lean`. They also contain a
`## Meaning` section with plain-language explanations readable by a non-programmer.

Example structure of a framework file:

```markdown
# stdlib / frameworks / universal / core

**OpenNorm:** 0.1
**Package-type:** framework
**Package:** frameworks.universal.core
**Version:** 1.0
**Extends:** none
**Depends-on:** none

---

## Manifest

**Package-type:** framework
**Implicit-import:** true
**Axioms:**
- Permitted
- Obligated
- Forbidden
- deontic_consistency
- obligation_permits
- defeasibility

---

## Permitted

**Meaning:** An actor is allowed to perform an action. Permission is
the absence of prohibition. It does not imply obligation.

**Lean4:**
```lean4
axiom Permitted (actor : α) (action : β) : Prop
```

---

## deontic_consistency

**Meaning:** Nothing can be simultaneously permitted and forbidden.
A document that produces this contradiction fails formal verification.

**Lean4:**
```lean4
axiom deontic_consistency {α β} (a : α) (x : β) :
  ¬(Permitted a x ∧ Forbidden a x)
```

**Dissent:** none on record
```

**Framework axioms for legal systems** encode structural truths that hold across
all documents in that legal system:

```
common-law/contracts.md:
  consideration_required — every valid contract requires consideration
  implied_term_possible  — courts may find terms the parties never wrote
  parol_evidence_rule    — external evidence cannot contradict written terms

civil-law/contracts.md:
  validity_conditions    — capable parties, certain object, lawful cause
  literal_interpretation — contracts interpreted against their written text

eu/gdpr.md:
  lawful_basis_required  — every processing must have exactly one lawful basis
  purpose_limitation     — data may not be processed beyond declared purpose
  erasure_obligation     — controller must erase on valid request within 30 days
  data_minimisation      — data collected must be necessary for declared purpose
```

When a document declares `**Framework:** common-law`, the transpiler loads
`frameworks/common-law/contracts.md` and its axioms are applied during
formal verification. A process checked under GDPR loads `frameworks/eu/gdpr.md`.

If two frameworks are loaded simultaneously and their axioms contradict,
the Lean 4 compiler detects the contradiction. This is error E040:
incompatible frameworks.

### 5.3 Layer 2 — Templates

A template defines the structural requirements for a document type. It answers:
does this document have the right sections, the right required fields, and does
it satisfy the structural invariants for its type?

Templates have nothing to do with term meaning. They are purely structural.

```
stdlib/templates/
├── license.md
├── contract.md
├── charter.md
└── dao.md
```

Anyone can write a new template. Custom templates follow the same format and
can be published and imported like any other stdlib package.

Template files use `**Package-type:** template` and contain:
- `## Required Sections` — with required fields per section
- `## Optional Sections`
- `## Structural Invariants` — machine-checkable rules
- `## Warnings` — diagnostic codes issued for missing optional elements

### 5.4 Layer 3 — Definitions

Definitions are the load-bearing layer. A mistake here propagates everywhere
the term is used. Definitions have the strictest review process after
universal framework axioms.

```
stdlib/definitions/
├── core/
│   ├── actors.md           Person, Institution, RightsHolder, Licensor, ...
│   ├── logic.md            conditional, unless, notwithstanding, ...
│   └── time.md             duration, perpetual, upon, within, ...
├── actions/
│   ├── software.md         use, copy, modify, distribute, sublicense, sell, ...
│   ├── financial.md        pay, transfer, refund, escrow, ...
│   └── legal.md            assign, waive, indemnify, terminate, ...
├── economics/
│   └── core.md             free_of_charge, consideration, royalty, ...
├── ip/
│   └── copyright.md        copyright_notice, derivative_work, ...
└── data/
    └── gdpr.md             personal_data, data_subject, controller, ...
                            lawful_basis, consent, legitimate_interests, ...
```

Each definition file contains:

- `## Manifest` — surface forms mapped to canonical term ids, used by the checker
  to recognise terms in document text
- One section per defined term, each containing:
  - `**Meaning:**` — human-readable definition
  - `**Lean4:**` — the type declaration and/or axioms for the formal layer,
    structured as `### Types` and `### Axioms` subsections
  - `**Dissent:**` — recorded disagreements with the definition
  - `**Review trigger:**` — condition under which the definition should be revisited

The `## Manifest` section format:

```markdown
## Manifest

- "distribute"      → distribute
- "make available"  → distribute
- "share"           → distribute
- "run"             → use
- "execute"         → use
```

Single-word terms are direct lookups. Multi-word surface forms use a sliding
window over the token stream. When a term matches multiple packages the checker
flags it as ambiguous and requests disambiguation in the local Definitions section.

### 5.5 Layer 4 — Clauses

Clauses are pre-written, vetted, formally-verified document fragments. They are
composed entirely of defined terms. A drafter imports a clause rather than
writing the same language from scratch.

```
stdlib/clauses/
├── warranty/
│   ├── as-is.md            standard no-warranty disclaimer
│   ├── as-is-eu.md         EU consumer-law compliant variant
│   └── limited.md          limited warranty for N days
├── liability/
│   ├── full-exclusion.md   total liability exclusion
│   └── capped.md           liability capped at declared amount
├── ip/
│   ├── assignment.md       IP ownership transfer
│   └── retention.md        licensor retains all IP
├── jurisdiction/
│   ├── us-general.md       Delaware/New York governing law
│   ├── eu-general.md       GDPR-aware governing law
│   └── neutral.md          UNCITRAL / ICC arbitration
└── notice/
    └── copyright-preservation.md   MIT-style notice obligation
```

Clause files use `**Package-type:** clause` and declare:
- `**Depends:**` — which definition packages they require
- `**Parameters:**` — values the importing document must supply (if any)
- `## Clause Text` — the substantive content, using resolved and fuzzy terms
- `## Known Ambiguities` — fuzzy terms declared within the clause

**Fuzzy term inheritance:** when a document imports a clause, the clause's
fuzzy terms are automatically inherited into the document's ambiguity record.
The drafter does not need to re-declare them. The report shows both local
and inherited ambiguities, clearly labelled. This is automatic — explicit
manual acknowledgement is not required.

**Import syntax in a document:**

```markdown
**Imports:**
- stdlib/clauses/warranty/as-is@1.0

## Waivers

*(import: clauses/warranty/as-is)*
```

The checker resolves the import, inlines the clause's terms into the document's
term index, and carries the clause's Known Ambiguities forward.

### 5.6 Dependency and Contribution Dynamics

```
Layer 1 — Frameworks:  highest review threshold. Changes invalidate prior
                        verifications. Universal core requires unanimity.
                        Legal framework axioms require legal + Lean 4 expertise.

Layer 2 — Templates:   moderate threshold. Wrong templates produce missing-field
                        errors, not formal incorrectness. Domain experts can
                        contribute without Lean 4 knowledge.

Layer 3 — Definitions: high threshold, second only to universal framework.
                        Version bumps trigger re-check of all dependent documents.
                        Dissent system is load-bearing here.

Layer 4 — Clauses:     moderate threshold. Must pass full pipeline checks before
                        publication. Community naturally produces many variants
                        (as-is-eu, as-is-saas, capped-10k-eur) without each
                        requiring the scrutiny of a definition change.
```

---

## 6. The Parser — Rust + pest

### 6.1 The Grammar File

The `openlex.pest` grammar file is the authoritative specification of the
OpenNorm document format. It is readable by non-programmers.

```pest
// openlex.pest — OpenNorm Grammar v0.1

// ── Top Level ──────────────────────────────────────────────────
document       =  { SOI ~ metadata_block ~ section* ~ EOI }
metadata_block =  { field+ }
section        =  { separator? ~ header ~ block* }
block          =  { field | bullet_list | blockquote | prose_block | blank_line }

// ── Structure ──────────────────────────────────────────────────
header         =  { NEWLINE* ~ header_prefix ~ " "+ ~ header_text ~ NEWLINE }
header_prefix  = @{ "#"+ }
header_text    = @{ (!NEWLINE ~ ANY)+ }
separator      =  { "---" ~ NEWLINE }
blank_line     =  { NEWLINE+ }

// ── Fields ─────────────────────────────────────────────────────
field          =  { "**" ~ field_label ~ ":**" ~ " "* ~ field_value_inline? ~ NEWLINE
                    ~ field_value_block? }
field_label    = @{ (!(":**") ~ !"*" ~ ANY)+ }
field_value_inline = { term_inline }
field_value_block  = { bullet_list }

// ── Prose blocks ───────────────────────────────────────────────
// Prose contains free text that may include inline *term* and ~~term~~ markers.
// Full prose term extraction is implemented in the checker via pattern scanning.
prose_block    =  { prose_line+ }
prose_line     =  { !("**" | "- " | "> " | "---" | "#") ~ (!NEWLINE ~ ANY)+ ~ NEWLINE }

// ── Bullet Lists (indentation = priority) ──────────────────────
bullet_list    =  { bullet+ }
bullet         =  { indent_level ~ "- " ~ term_inline ~ NEWLINE ~ bullet* }
indent_level   = @{ ("  ")* }    // length / 2 = priority integer

// ── Blockquotes ────────────────────────────────────────────────
blockquote     =  { blockquote_line+ }
blockquote_line =  { "> " ~ (!NEWLINE ~ ANY)* ~ NEWLINE }

// ── Terms ──────────────────────────────────────────────────────
term_inline    =  { resolved | fuzzy | plain_term }
resolved       =  { "*" ~ term_word ~ "*" }           // stdlib reference
fuzzy          =  { "~~" ~ term_word ~ "~~" }         // intentional flexibility
plain_term     =  { term_word ~ (" " ~ term_word)* }  // undefined — error or warning

term_word      = @{ ASCII_ALPHANUMERIC+ ~ ("_" ~ ASCII_ALPHANUMERIC+)* }

// ── References ─────────────────────────────────────────────────
ref_link       =  { "[" ~ ref_text ~ "](" ~ ref_uri ~ ")" }
ref_text       = @{ (!"]" ~ ANY)+ }
ref_uri        = @{ (!")" ~ ANY)+ }

// ── Imports ────────────────────────────────────────────────────
import_entry   = @{ import_path ~ ("@" ~ version_str)? }
import_path    = @{ (ASCII_ALPHANUMERIC | "/" | "_" | "-" | ".")+ }
version_str    = @{ ASCII_DIGIT+ ~ ("." ~ ASCII_DIGIT+)* }

// ── Whitespace ─────────────────────────────────────────────────
WHITESPACE     = _{ " " | "\t" }
NEWLINE        = _{ "\r\n" | "\n" }
```

### 6.2 The AST

```rust
pub enum Term {
    Resolved { name: String, package: Option<String>, version: Option<String> },
    Fuzzy    { name: String, review_trigger: Option<String>, reason: Option<String> },
    Undefined(String),
}

pub struct Field     { pub label: String, pub value: FieldValue, pub location: Location }
pub struct Bullet    { pub term: Term, pub priority: usize, pub sub_bullets: Vec<Bullet> }
pub struct Section   { pub kind: SectionKind, pub fields: Vec<Field>,
                       pub bullets: Vec<Bullet>, pub prose: Vec<String>,
                       pub annotations: Vec<String> }
pub struct Import    { pub package: String, pub version: Option<String> }
pub struct Document  { pub id: String, pub version: String, pub template: Option<String>,
                       pub framework: Option<String>, pub status: DocumentStatus,
                       pub imports: Vec<Import>, pub sections: Vec<Section>,
                       pub known_fuzzies: Vec<KnownFuzzyTerm> }
```

### 6.3 Term Recognition — The Manifest System

The stdlib packages carry a `## Manifest` section mapping surface forms to
canonical term ids. The checker builds a recognition index from all imported
manifests before term classification begins.

**Auto-import flow:** the checker infers the minimum import set from all
recognised terms and proposes it to the drafter during draft mode.
Before finalisation every import must be explicitly pinned:

```bash
$ opennorm pin document.md
# Locks all auto-resolved imports to current stable versions
```

---

## 7. The Checker

### 7.1 Three Validation Passes

**Pass 1 — Template conformance**
Does the document structure match its declared template? Required sections
present? Required fields within sections present? Structural invariants satisfied?
This pass is purely structural. No term meaning is involved.

**Pass 2 — Term resolution**
Every `*resolved*` term is looked up against the manifest index built from
imported definition packages. Every `~~fuzzy~~` term is verified to appear
in § Known Ambiguities. Plain undefined terms produce errors in review/final
mode, warnings in draft mode.

**Pass 3 — Clause and reference integrity**
For each imported clause, are all the clause's terms still resolved in the
document's combined import set? Are the clause's fuzzy terms automatically
inherited into the document's ambiguity record? Are all `opennorm://` references
resolvable? Are all `#anchor` references pointing to existing sections?

### 7.2 Conflict Detection

The conflict vs provision distinction is what makes amendment review tractable.

**Conflict** — the same actor is simultaneously permitted and forbidden the
same action under the same conditions. Hard error. Must be resolved before merge.

**Provision** — a new clause adds something the existing document is silent on.
Not a conflict. Requires human judgment: is this intentional extension or scope creep?

```
Existing: distribute is permitted
New:      distribute requires payment    ← CONFLICT  (E030)

Existing: distribute is permitted
New:      network_distribute is permitted  ← PROVISION (W030)
```

### 7.3 Diagnostic Codes

```rust
pub struct Diagnostic {
    pub severity:   Severity,       // Error, Warning, Info
    pub code:       &'static str,   // "E001", "W003"
    pub message:    String,
    pub location:   Location,       // section and line
    pub suggestion: Option<String>,
}
```

Standard codes:

| Code | Severity | Meaning |
|---|---|---|
| E001 | Error | Required section missing |
| E002 | Error | Required field missing in section |
| E010 | Error | Unpinned import in review/final mode |
| E011 | Error | Resolved term not found in any manifest |
| E012 | Error | Undefined plain term (review/final mode) |
| E020 | Error | Fuzzy term not declared in § Known Ambiguities |
| E030 | Error | Conflict: simultaneously permitted and forbidden |
| E040 | Error | Incompatible framework axioms |
| W001 | Warning | No jurisdiction declared |
| W002 | Warning | No version governance declared |
| W010 | Warning | Undefined plain term (draft mode) |
| W030 | Warning | Provision detected — silent gap filled |
| I001 | Info | No amendment procedure declared |

---

## 8. The Transpiler — Lean 4

### 8.1 Generated File Assembly

The drafter never sees or edits generated `.lean` files. The `.md` source is
authoritative. Generated files carry a header stating they must not be edited.

The transpiler assembles Lean 4 output in three steps:

**Step 0 — Preamble (from frameworks)**

```
frameworks/universal/core.md  ─┐
frameworks/common-law/...md   ─┤→ preamble.lean (generated)
frameworks/eu/gdpr.md         ─┘
```

The preamble contains all axioms extracted from `## Lean4` sections in
framework files, emitted in dependency order. Universal axioms first,
specific framework axioms after.

**Step 1 — Definitions (from definition packages)**

```
definitions/core/actors.md        ─┐
definitions/actions/software.md   ─┤→ definitions.lean (generated)
definitions/data/gdpr.md          ─┘
```

Types are emitted before axioms within each package. Packages are emitted
in import order.

**Step 2 — Document**

```
document.md → document.lean (generated, imports preamble + definitions)
```

### 8.2 The Lean4 Section Format in Stdlib Files

Definition files use subsections to distinguish types from axioms,
allowing the transpiler to emit them in the correct order:

```markdown
## distribute

**Meaning:** To transfer or make available copies of the Software to third parties.

**Lean4:**

### Types
```lean4
opaque distribute : Person → Software → Action
```

### Axioms
```lean4
axiom distribute_triggers_obligations :
  ∀ (p : Person) (sw : Software),
  performs p (distribute sw) →
  Obligated p (include_notice sw)
```
```

### 8.3 Transpilation of the MIT Grant

Source markdown:
```markdown
## Grant
**To:** any *Person*
**Permitted:**
- *use*
- *distribute*
- *sublicense*
```

Generated Lean 4:
```lean4
-- Transpiled from mit.md § Grant
def MIT_Grant (recipient : Person) (sw : Software) : Prop :=
  obtained recipient sw →
    Permitted recipient (use sw)        ∧
    Permitted recipient (distribute sw) ∧
    Permitted recipient (sublicense sw)

theorem MIT_sublicense_bounded (r : Person) (sw : Software) :
  MIT_Grant r sw →
  sublicense_rights r sw ⊆ original_rights sw := by
  intro h
  exact sublicense_bound _ _ _ (grant_rights_bounded h)
```

### 8.4 Fuzzy Terms Become sorry Stubs

```lean4
-- Fuzzy term: substantial_portions
-- Declared in mit.md § Known Ambiguities
-- Intentional flexibility — human judgment required
-- Review trigger: when contested in legal proceedings
def substantial_portions_threshold : Nat := by
  sorry  -- documented: no threshold defined, 30 years of litigation
```

Every `sorry` in a generated file corresponds to exactly one fuzzy term
declared in § Known Ambiguities. There are no silent sorrys. The sorry
inventory in the report translates each one into plain language and
required human action.

### 8.5 Transpilation of Defeasibility

Source markdown (indented bullets):
```markdown
**Voting Rights:**
- *citizen*
  - active_conviction → none
    - sentence_served → *citizen*
```

Generated Lean 4:
```lean4
def voting_rules : List (Rule Person VotingRight) := [
  { id := "citizen", applies := fun p _ => citizen p,
    permitted := true, priority := 1 },
  { id := "conviction", applies := fun p _ => active_conviction p,
    permitted := false, priority := 2 },
  { id := "served", applies := fun p _ => sentence_served p,
    permitted := true, priority := 3 }
]

def voting_permitted (p : Person) : Bool :=
  defeasible_permitted voting_rules p VotingRight.vote
```

---

## 9. The Report

### 9.1 Report Structure

The report is the product. Everything else is machinery. The report translates
all stage outputs into plain language that a non-technical drafter can read
and act on.

```markdown
# OpenNorm Verification Report
**Document:** MIT License
**Version:** 1.0
**Checked:** 2025-01-15T14:23:01Z
**OpenNorm:** 0.2
**Result:** ⚠️ VALID WITH WARNINGS

---

## Summary

| Category | Count |
|---|---|
| ✅ Resolved terms | 11 |
| ⚠️ Fuzzy terms | 3 |
| ❌ Hard errors | 0 |
| ℹ️ Warnings | 3 |
| 🔬 Proved theorems | 3 |
| 📋 Sorry stubs | 3 |

---

## Stage 1 — Parse
## Stage 2 — Structure
### Resolved Terms  [table]
### Fuzzy Terms     [table with inheritance labels]
### Errors          [none]
### Warnings        [W001 no jurisdiction, W002 no version governance]

---

## Stage 3 — Transpilation
## Stage 4 — Formal Verification
### Proved
### Sorry Inventory

---

## Recommendations

---

*This report was generated by OpenNorm 0.2*
*It is not legal advice.*
*The .md source document is the authoritative instrument.*
*Lean 4 output is a consistency verification aid.*
```

### 9.2 The Sorry Inventory

Every `sorry` in the generated Lean 4 corresponds to a fuzzy term.
The report translates each one:

| Sorry | Plain Language | Human Action Required |
|---|---|---|
| `substantial_portions_threshold` | What percentage of the software triggers the notice obligation? | Legal judgment at point of dispute. Review trigger: contested in legal proceedings. |
| `otherwise_scope` | What is the full scope of the liability waiver? | Jurisdiction-specific interpretation. Review trigger: contested in legal proceedings. |

### 9.3 Inherited Ambiguities

When a document imports a clause, the clause's fuzzy terms appear in the
report clearly labelled:

| Term | Origin | Review Trigger | Status |
|---|---|---|---|
| `~~substantial_portions~~` | local | contested in legal proceedings | declared |
| `~~otherwise~~` | inherited from clauses/warranty/as-is@1.0 | contested in legal proceedings | inherited |

---

## 10. The LSP — Live Drafting

The LSP server provides real-time feedback as a drafter writes an OpenNorm
document in any compatible editor (VS Code, Neovim, Zed).

```json
{
  "lsp": {
    "opennorm": {
      "command": "opennorm",
      "args": ["--lsp"],
      "filetypes": ["markdown"]
    }
  }
}
```

The LSP activates on `.md` files that contain an `**OpenNorm:**` metadata field.
On non-OpenNorm markdown it finds nothing to check and stays silent.

Features:
- Real-time term resolution as you type `*word*`
- Inline error/warning annotations
- Autocomplete for stdlib terms from imported packages
- Hover documentation showing the full definition of any resolved term
- Quick-fix suggestions for undefined terms

---

## 11. The Query Layer

After verification, the document is indexed as a structured knowledge graph.
Queries run against the index — fast, deterministic, offline.

```bash
# What can a recipient do?
$ opennorm query mit.md "permissions"

# What triggers an obligation?
$ opennorm query mit.md "obligation triggers"

# Cross-document compatibility
$ opennorm query "compatible mit.md apache2.md"

# All fuzzy terms and their risk
$ opennorm query mit.md "fuzzy terms"

# Is this BPMN process GDPR compliant?
$ opennorm check-bpmn process.bpmn --regulation regulations/gdpr.md

# Compatibility graph across a directory
$ opennorm graph licenses/
```

---

## 12. CLI Interface

```
opennorm new <file.md>              Creates file from template.
                                    Prompts for document type and framework.

opennorm check <file.md>            Full pipeline. Produces report.
                                    Exit 0: valid (with or without warnings)
                                    Exit 1: errors present

opennorm check-bpmn <process.bpmn>  Check BPMN process against a regulation.
  --regulation <regulation.md>      Requires Phase 2 regulation encoding.
  --report <output.md>

opennorm review <file.md>           Full validation in review mode.
  --external <dir>                  Check against other documents in directory.

opennorm finalize <file.md>         Ratification check. All imports pinned.
                                    All fuzzy terms declared. No errors.
                                    Produces ratification record.

opennorm pin <file.md>              Pins all auto-resolved imports to
                                    current stable stdlib versions.

opennorm diff <file1> <file2>       Semantic diff — changes in meaning,
                                    not just text. Shows compatibility delta.

opennorm query <file> <query>       Query the document index.

opennorm graph <directory>          Compatibility graph of all indexed documents.

opennorm explain <file> <term>      Trace a term — where defined, where used,
                                    what it affects.

opennorm --lsp                      Start LSP server mode.
```

---

## 13. MVP — MIT License in OpenNorm

### 13.1 The Goal

Produce a single file, `licenses/mit.md`, that:

- Is indistinguishable from a well-formatted legal document to a non-technical reader
- Could replace the MIT license in a project without legal ambiguity
- Passes the OpenNorm parser without structural errors
- Has all terms resolved, declared fuzzy, or flagged as known gaps
- Generates valid Lean 4 that compiles and produces a formal verification report
- Surfaces the known ambiguities that 30 years of litigation have identified
- Proves the sublicense constraint: a sublicensee cannot receive more rights than
  the licensor held

**Success criterion:** the report flags the known MIT ambiguities that 30 years of
litigation have identified. The sublicense constraint is formally proved. The tool
works end-to-end.

### 13.2 The Document

```markdown
# MIT License

> The MIT License is a permissive free software license originating at the
> Massachusetts Institute of Technology. It permits free use, modification,
> distribution, and commercialisation of software, subject only to the
> condition that the original copyright and permission notice be preserved
> in all copies or substantial portions of the software.
>
> This document is the MIT License encoded in OpenNorm 0.2. *Italicised terms*
> are formally defined in the referenced packages. ~~Struck-through terms~~ are
> intentionally flexible and declared in § Known Ambiguities below.

**OpenNorm:** 0.2
**ID:** MIT
**Version:** 1.0
**Template:** license
**Status:** review
**Imports:**
- stdlib/definitions/core/actors@1.0
- stdlib/definitions/actions/software@1.0
- stdlib/definitions/economics/core@1.0
- stdlib/definitions/ip/copyright@1.0

---

## Grant

**To:** any *Person*
**Condition:** obtained a copy of the *Software*
**Cost:** *free_of_charge*
**Scope:** worldwide, perpetual, irrevocable, non-exclusive

Permission is hereby granted, *free_of_charge*, to any *Person* obtaining
a copy of the *Software* and *associated_documentation*, to *deal* in the
*Software* without restriction, including without limitation the rights to
*use*, *copy*, *modify*, *merge*, *publish*, *distribute*, *sublicense*,
and *sell* copies of the *Software*, and to permit persons to whom the
*Software* is furnished to do so, subject to the following conditions:

**Permitted:**
- *use* the *Software* for any purpose
- *copy* the *Software*
- *modify* the *Software*
- *merge* the *Software* with other software
- *publish* the *Software*
- *distribute* the *Software*
- *sublicense* the *Software*
- *sell* copies of the *Software*
- permit *Person*s to whom the *Software* is furnished to do the same

---

## Obligations

**When:** *distribute* or *sublicense*

The above *copyright_notice* and this *permission_notice* shall be included
in all copies or ~~substantial_portions~~ of the *Software*.

**Must include in all copies or** ~~substantial_portions~~**:**
- *copyright_notice*
- *permission_notice*

---

## Waivers

The *Software* is provided "as is", without warranty of any kind, express
or implied, including but not limited to the warranties of merchantability,
fitness for a particular purpose, and non-infringement. In no event shall
the authors or *copyright_notice* holders be liable for any claim, damages,
or other liability, whether in an action of contract, tort, or ~~otherwise~~,
arising from, out of, or in connection with the *Software* or the use or
other dealings in the *Software*.

**Warranty waived:** all warranties, express or implied
**Liability waived:** all claims arising from use, including contract and tort
**Scope:** ~~otherwise~~ — catch-all, see § Known Ambiguities

---

## Known Ambiguities

> The following terms are intentionally flexible. They require human judgment
> at the point of application and cannot be formally resolved without context.
> This is a deliberate characteristic of the MIT License, not an oversight.

- **substantial_portions** — no threshold defined for when the notice obligation
  applies. Litigated across multiple jurisdictions for thirty years without
  producing a bright-line rule. The absence of a threshold is arguably intentional.
  **Review trigger:** contested in legal proceedings

- **otherwise** — catch-all in the liability waiver, scope intentionally unbounded.
  **Review trigger:** contested in legal proceedings

- **associated_documentation** — scope of what files are covered alongside the
  primary codebase. Does "associated" include README files, man pages, a project
  website? Currently undefined.
  **Review trigger:** ten years from this version, or when contested

---

## Structural Notes

> Structural characteristics identified by OpenNorm. Not defects — design choices.

- **No jurisdiction declared.** Intentionally jurisdiction-neutral. Enforcement
  varies by location. OpenNorm status: warning W001 issued, acknowledged.

- **No version governance.** No institution controls the MIT name or namespace.
  OpenNorm status: warning W002 issued, acknowledged.

- **No amendment procedure.** MIT 1.0 was the first and only version. Consistent
  with its design as a minimal, stable, one-version instrument.
  OpenNorm status: info I001 issued, acknowledged.
```

### 13.3 Expected Report Output

Running `opennorm check licenses/mit.md` produces:

**Resolved:** use, copy, modify, merge, publish, distribute, sublicense, sell,
Person, Software, free_of_charge, copyright_notice, permission_notice,
associated_documentation, deal

**Fuzzy:** substantial_portions, otherwise, associated_documentation_scope

**Proved:** no internal contradictions; sublicense_rights ⊆ grant_rights;
obligations are fulfillable without licensor action

**Undecidable:** obligation scope under SaaS distribution (documented, known gap)

**Structural gaps:** no jurisdiction (W001), no version governance (W002),
no amendment procedure (I001)

### 13.4 Build Steps for MVP

```
Step 1 — frameworks/universal/core.md
  Define Permitted, Obligated, Forbidden as axioms
  Define deontic_consistency axiom
  Define obligation_permits axiom
  Define defeasibility Rule structure and winning_rule function
  Test: manually write a 3-clause toy document
        introduce contradiction
        verify Lean catches it
  This is the proof of concept for the entire system.

Step 2 — pest grammar
  Write src/openlex.pest
  Cover: document, metadata, sections, fields,
         bullet_lists, terms, references, prose_blocks
  Test against hand-crafted valid and invalid documents

Step 3 — Rust AST types
  Write src/ast.rs

Step 4 — Parser
  Write src/parser.rs
  pest pairs → AST

Step 5 — Proto-stdlib packages
  Write stdlib/frameworks/universal/core.md
  Write stdlib/templates/license.md
  Write stdlib/definitions/core/actors.md
  Write stdlib/definitions/actions/software.md
  Write stdlib/definitions/economics/core.md
  Write stdlib/definitions/ip/copyright.md
  Write stdlib/clauses/warranty/as-is.md
  Write stdlib/clauses/notice/copyright-preservation.md
  All are OpenNorm documents, not code.

Step 6 — Checker
  Write src/checker.rs
  Three passes: template, term resolution, clause integrity
  Conflict detection
  Fuzzy term inheritance from clauses

Step 7 — Transpiler
  Write src/transpiler.rs
  Stage 0: assemble preamble.lean from framework files
  Stage 1: assemble definitions.lean from definition packages
  Stage 2: transpile document sections to document.lean

Step 8 — Lean invocation
  src/main.rs: subprocess call to lean
  Parse output for proved/failed/sorry counts
  Fallback gracefully if lean not on PATH

Step 9 — Report builder
  Write src/report.rs
  Collect all stage outputs
  Render plain text and JSON variants

Step 10 — Encode MIT
  Write licenses/mit.md
  Run full pipeline
  Verify: flagged ambiguities match 30 years of known litigation
  Verify: sublicense constraint is proved
  This is the validation test for the entire system.

Step 11 — Deliberately broken test
  Write tests/contradiction.md
  Simultaneously permit and forbid the same action
  Verify: contradiction is caught (E030)
  This is the red team test.
```

---

## 14. Phase 2 — GDPR Compliance for Business Processes

### 14.1 The Problem

GDPR compliance for business processes is currently handled in three ways,
all of them inadequate:

**Consultants with checklists.** Manual, expensive, point-in-time,
non-reproducible. Two consultants reviewing the same process reach different
conclusions. When the process changes, the compliance review expires immediately.

**Privacy-by-design workshops.** Catches obvious violations early but has no
formal verification, no machine-readable output, and no way to detect that a
compliant design became non-compliant when someone changed a downstream task.

**GRC platforms.** Built around human attestation — someone clicks a checkbox
saying "yes this process is compliant." The checkbox is not derived from any
formal analysis. When it is wrong, nobody knows until there is an incident.

The gap all three share: **there is no formal, machine-checkable connection
between what the regulation says and what the process does.**

### 14.2 The OpenNorm Approach

OpenNorm starts from the normative side — from what the regulation actually
says — and derives compliance requirements formally. The regulation is the ground
truth. The process is what gets verified against it.

Two artifacts are required:

**`regulations/gdpr.md`** — the formal encoding of GDPR in OpenNorm.
This imports `frameworks/eu/gdpr.md` for the axioms and encodes each relevant
article as sections with obligations, conditions, and fuzzy terms.

**A BPMN reader (`src/bpmn.rs`)** — parses a BPMN 2.0 XML file and produces
an OpenNorm-compatible representation:

```
BPMN lanes          → OpenNorm actors
BPMN tasks          → OpenNorm actions
BPMN data objects   → OpenNorm data terms
BPMN sequence flows → temporal ordering constraints
BPMN message flows  → data transfer events
BPMN gateways       → conditional branches
```

The compliance checker then verifies that the process representation does not
violate the regulation encoding. Findings map to specific BPMN elements and
specific GDPR articles.

### 14.3 GDPR Articles That Map Cleanly

Some GDPR obligations are sufficiently precise to encode as formal axioms
with no fuzziness:

**Article 6 — Lawful basis:**
```lean4
axiom lawful_basis_required :
  ∀ p : DataProcessing, Lawful p →
    HasConsent p ∨ ContractNecessity p ∨ LegalObligation p ∨
    VitalInterests p ∨ PublicTask p ∨ LegitimateInterests p
```
A process that touches personal data without a declared lawful basis
is a hard error.

**Article 17 — Right to erasure:**
```lean4
axiom erasure_obligation :
  ∀ (s : DataSubject) (c : Controller),
  ValidErasureRequest s c →
  Obligated c (erase (data_of s)) ∧ Within c 30
```
A BPMN process that receives an erasure request is checked: does it have
a path terminating with erasure within 30 days?

**Article 25 — Data minimisation:**
```lean4
axiom data_minimisation :
  ∀ p : DataProcessing, Lawful p →
  Necessary (data_collected p) (purpose p)
```
Every data collection step must have a declared purpose, and the data
collected must be shown to be necessary for that purpose.

**Article 13/14 — Information obligations:**
```lean4
axiom information_obligation :
  ∀ (p : DataProcessing) (s : DataSubject),
  CollectsFrom s p →
  Obligated (controller p) (inform s) ∧ AtOrBefore (controller p) point_of_collection
```

### 14.4 GDPR Articles That Are Genuinely Fuzzy

These become sorry stubs with review triggers. The sorry inventory becomes
the DPO's prioritised work queue:

| Fuzzy Term | Article | Why Fuzzy | Sorry Stub |
|---|---|---|---|
| `appropriate_measures` | 25, 32 | No formal threshold defined | `appropriate_security_threshold` |
| `legitimate_interests` | 6(1)(f) | Requires a balancing test | `legitimate_interests_balancing` |
| `high_risk` | 35 | Partial criteria, partial judgment | `dpia_risk_threshold` |
| `reasonable_expectation` | 6(1)(f) | Context and jurisdiction dependent | `data_subject_expectation` |

### 14.5 The Compliance Report

Running `opennorm check-bpmn process.bpmn --regulation regulations/gdpr.md`
produces a report where every finding is mapped to:

- A specific BPMN element (task name, lane, line number in XML)
- A specific GDPR article
- The formal proposition that was violated or could not be proved
- Whether the finding is a hard error, a warning, or a sorry requiring human judgment

Example finding:
```
[E011] Task "Send confirmation email" (lane: Marketing, line 247)
  transfers PersonalData to ExternalSystem "MailProvider"
  No data processing agreement declared.
  Possible violation: Article 28 — processor must provide sufficient guarantees.
  Suggestion: Add a DPA reference to this task's data object annotations,
              or add MailProvider to § Processors in your GDPR record of processing.
```

### 14.6 Business Value

**For Data Protection Officers:** a tool that continuously monitors process
compliance and produces auditable reports changes the job from reactive
firefighting to proactive governance. Process changes trigger automatic re-check.

**For consulting firms:** encode expertise once in a reusable OpenNorm GDPR
library. Deliver continuous compliance monitoring rather than point-in-time
assessments. Competitive advantage shifts from "we know GDPR" to "we have the
best-validated GDPR encoding."

**For process automation vendors:** GDPR compliance verification built into
the process modelling tool (Camunda, Signavio, Bizagi) is a significant
differentiator. A modeller that shows a compliance dashboard as you design
is qualitatively different from one requiring a separate review after the fact.

**For regulators:** a company that can demonstrate to a supervisory authority
that every process was formally verified against the regulation, with an
auditable report showing exactly which articles were checked and which fuzzy
terms required human judgment, is in a materially different position than one
that can only show a consultant's attestation.

### 14.7 Build Steps for Phase 2

```
Step 1 — frameworks/eu/gdpr.md
  Encode Articles 5, 6, 7, 13, 14, 17, 25, 28, 32 as axioms
  Declare all genuinely fuzzy articles as ~~fuzzy_term~~ with review triggers
  This is the core intellectual work. Requires legal + Lean 4 expertise.
  Dissent system is load-bearing here — contested encodings are common.

Step 2 — definitions/data/gdpr.md
  Define: personal_data, data_subject, controller, processor
  Define: consent, legitimate_interests, lawful_basis
  Define: data_processing, purpose, retention_period
  Build manifest for GDPR vocabulary recognition

Step 3 — regulations/gdpr.md
  The full GDPR encoded as an OpenNorm document
  Each Article as a section
  Obligations, conditions, and fuzzy terms properly declared
  Run full pipeline — report must surface known GDPR ambiguities

Step 4 — BPMN reader (src/bpmn.rs)
  Parse BPMN 2.0 XML
  Map lanes → actors, tasks → actions, data objects → data terms
  Map sequence flows → temporal ordering
  Map message flows → data transfer events
  Output: OpenNorm-compatible process representation

Step 5 — Compliance checker
  Check process representation against regulation encoding
  Map findings to BPMN elements and GDPR articles
  Produce structured compliance report

Step 6 — Validation
  Test against a known non-compliant process (must fail with specific findings)
  Test against a known compliant process (must pass with expected sorry inventory)
  The sorry inventory must match the genuinely undecidable GDPR obligations
```

---

## 15. Known Limitations and Honest Boundaries

### 15.1 The Translation Gap

The parser verifies that the encoding is internally consistent. It cannot verify
that the encoding faithfully represents the intent of the original document.
This gap is addressed by the open source model — wrong encodings are public and
correctable — but it cannot be eliminated by any formal system.

### 15.2 Classical Logic and Defeasibility

Law uses defeasible reasoning: rules hold unless defeated by more specific rules,
later rules, or higher authority. Classical logic assumes monotonicity — adding
facts never invalidates old proofs. OpenNorm addresses this through the explicit
priority chain system, where indentation depth encodes priority. The complexity
of defeasible reasoning is hidden in the generated Lean 4; the document surface
remains readable. But this means the generated Lean 4 for complex documents with
many exception chains will be verbose even when the source document is clean.

### 15.3 Gödel Bounds

For sufficiently complex regulatory interactions, the prover may return
"undecidable" rather than true or false. This is not a bug. Undecidable cases
become explicit warnings rather than hidden ambiguities that surface only in
disputes. Converting invisible problems to visible ones is valuable even when
the prover cannot resolve them.

### 15.4 No Legal Standing

An OpenNorm document has no legal standing in any jurisdiction until a court
or legislature grants it recognition. This is an adoption problem, not a technical
one. The path to legal standing runs through demonstrated utility at smaller
scales — open source projects, organisations, foundations — building the track
record that eventually makes courts and legislatures willing to treat OpenNorm
documents as formal instruments.

### 15.5 Jurisdiction Fragmentation

Common law and civil law systems have different epistemologies, not just different
vocabularies. The stdlib handles this through separate framework layers
(frameworks/common-law/, frameworks/civil-law/, frameworks/eu/) that sit on top of
the universal core. When documents from different frameworks interact, the checker
flags the mismatch and requires explicit jurisdiction declaration. It cannot resolve
the underlying substantive differences — it makes them visible.

### 15.6 Prose Term Extraction

The current grammar captures `*term*` and `~~term~~` patterns in prose blocks
via pattern scanning rather than full parse-tree integration. This means terms
embedded in flowing prose are scanned with a simpler mechanism than terms in
structured fields and bullets. Full prose term integration is deferred to v0.3.
In the meantime the checker warns when it detects prose patterns it cannot
fully classify.

---

## 16. Roadmap

### Phase 1 — MVP (Current)

- `frameworks/universal/core.md` — replaces hand-written Deontic.lean
- `openlex.pest` grammar
- Rust parser and AST
- Proto-stdlib (frameworks, templates, definitions, clauses)
- Checker (three-pass validation, conflict detection)
- Transpiler (preamble + definitions + document generation)
- Report builder
- MIT License encoded and verified

**Success criterion:** the report flags the known MIT ambiguities that 30 years
of litigation have identified. The sublicense constraint is formally proved.
The tool works end-to-end with no hand-written Lean 4.

### Phase 2 — GDPR Compliance

- `frameworks/eu/gdpr.md` — formal GDPR axioms
- `definitions/data/gdpr.md` — GDPR vocabulary
- `regulations/gdpr.md` — full GDPR encoding
- BPMN 2.0 reader
- Process compliance checker
- Compliance report with per-element, per-article findings

**Success criterion:** `opennorm check-bpmn process.bpmn --regulation regulations/gdpr.md`
returns correct, article-cited findings. A known non-compliant process fails.
A known compliant process passes with a clean sorry inventory for genuinely
undecidable obligations.

### Phase 3 — Contracts and Community

- Apache 2.0 encoded
- GPL 3.0 encoded
- License compatibility oracle
- LSP server implemented
- Query layer implemented
- `frameworks/common-law/contracts.md`
- `frameworks/civil-law/contracts.md`
- Contract template

**Success criterion:** `opennorm query "compatible mit.md apache2.md"` returns
a correct, cited answer. One real organisation uses OpenNorm for internal governance.

### Phase 4 — Institutional

- NGO and DAO charter templates
- Multi-jurisdiction framework layers
- Treaty language encoding
- Amendment proposal documents
- Additional EU framework layers (ePrivacy, AI Act)

**Success criterion:** one international body uses OpenNorm for a real document.
One regulatory body accepts an OpenNorm compliance report as formal evidence.

---

*OpenNorm v0.2 — Project Documentation*
*Status: Pre-implementation (Phase 1 in progress)*
*First pull request: stdlib/frameworks/universal/core.md*
