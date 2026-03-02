# stdlib / actions / software

> Defines the actions that can be performed on software under a license grant.
> These are the verbs of software licensing.

**OpenNorm:** 0.1
**Package:** actions.software
**Version:** 1.0
**Status:** review

---

## Manifest

> Surface forms recognized by the term manifest index.

- "use"              → use
- "run"              → use
- "execute"          → use
- "operate"          → use
- "copy"             → copy
- "reproduce"        → copy
- "duplicate"        → copy
- "modify"           → modify
- "alter"            → modify
- "adapt"            → modify
- "edit"             → modify
- "merge"            → merge
- "combine"          → merge
- "incorporate"      → merge
- "publish"          → publish
- "make public"      → publish
- "release"          → publish
- "distribute"       → distribute
- "make available"   → distribute
- "share"            → distribute
- "sublicense"       → sublicense
- "relicense"        → sublicense
- "sell"             → sell
- "sell copies"      → sell
- "commercialize"    → sell
- "deal"             → deal
- "deal in"          → deal

---

## use

**Meaning:** To execute or operate the Software for any purpose on any infrastructure.
**Excludes:** *distribute*, *sublicense*

> Running software as a network service (SaaS) constitutes *use*, not *distribute*.
> This is the subject of active legal debate. See dissent below.

**Dissent:** SaaS delivery should trigger distribution obligations when the software
is the primary vehicle of service delivery.
**Dissent by:** copyleft community, J. Moglen
**Status:** rejected v1.0; scheduled for review v1.1
**Review trigger:** legislative change or appellate ruling in any G7 jurisdiction

---

## copy

**Meaning:** To reproduce the Software in any medium or form.
**Includes:** digital reproduction, physical media, network transfer, cache
**Note:** Transient RAM copies made during *use* are covered by *use* and
do not require separate *copy* permission.

---

## modify

**Meaning:** To alter, adapt, transform, or build upon the Software.
**Includes:** adding features, removing features, porting, refactoring
**Produces:** a *derivative work* as defined in stdlib/ip/copyright

---

## merge

**Meaning:** To combine the Software with other software into a unified codebase
or executable, where the boundary between components may not be preserved.
**Distinction from distribute:** *merge* describes the act of combination;
*distribute* describes subsequent sharing of the combined work.

> The legal significance of merge in license compatibility analysis is contested.
> When combining software under different licenses, the merge operation is the
> point at which compatibility must hold. See stdlib/ip/copyright#compatibility.

**Fuzzy boundary:** where *incorporate* ends and *merge* begins in dynamic linking
**Review trigger:** appellate ruling on dynamic linking as derivative work

---

## publish

**Meaning:** To make the Software available to the public, whether or not copies
are transferred.
**Includes:** posting to a public repository, making accessible via network
**Relation to distribute:** *publish* does not require physical transfer of a copy;
*distribute* does. In practice many licenses treat them equivalently.

> The distinction between *publish* and *distribute* is relevant in jurisdictions
> where "making available" is a separate right under copyright law (e.g. EU Copyright
> Directive Art. 3). In US copyright law the "distribution right" requires actual
> transfer; "making available" is arguably a separate right under the public display
> and performance provisions.

**Fuzzy boundary:** when does a private repository become public publication
**Review trigger:** when contested in legal proceedings

---

## distribute

**Meaning:** To transfer or make available copies of the Software to third parties.
**Includes:** physical distribution, download, network delivery of executable
**Does not include:** *use* as a service (SaaS) — see *use* dissent above
**Triggers:** notice obligations in MIT, GPL, Apache-2.0

---

## sublicense

**Meaning:** To grant a third party rights under a license that is itself derived
from the original grant.
**Bound by:** sublicense_bound — the sublicensee cannot receive rights exceeding
those held by the licensor at point of sublicensing
**Requires:** the original license must permit sublicensing

---

## sell

**Meaning:** To transfer copies of the Software in exchange for monetary or
equivalent consideration.
**Includes:** selling the software itself, selling products that incorporate it
**Note:** "sell copies of the Software" in MIT does not transfer copyright;
it grants permission to commercialize under the license terms.

---

## deal

**Meaning:** To engage in any transaction involving the Software without restriction.
**Scope:** broader than any single enumerated action; used as a catch-all grant
**Note:** "deal in the Software without restriction" in the original MIT text is
the operative grant from which the enumerated rights are derived. When all
enumerated rights are listed, *deal* is redundant but preserved for completeness.