# stdlib / ip / copyright

**OpenNorm:** 0.1
**Package:** ip.copyright
**Version:** 1.0
**Status:** review

**Imports:**
- stdlib/actors/core@1.0

> Defines intellectual property terms relevant to software licensing.

---

## Manifest

## copyright_notice

**Meaning:** A statement identifying the copyright holder and the year(s) of
creation or publication, in the form: "Copyright (c) [year] [holder]".
**Required form:** must include the word "Copyright" or the © symbol,
a year or year range, and the name of the holder.
**Preservation obligation:** when a license requires inclusion of the copyright
notice, this full form must appear — not a summary or reference to it.

**Forms:** copyright notice, copyright

---

## permission_notice

**Meaning:** The text of the license grant itself, or a notice that the software
is available under a named license.
**In MIT:** the full MIT license text, from "Permission is hereby granted"
through the end of the disclaimer.
**Preservation obligation:** must appear verbatim in all copies or
~~substantial portions~~ of the Software.

**Forms:** permission notice, license notice

---

## derivative_work

**Meaning:** A work based upon one or more pre-existing works from which
it was derived.
**Includes:** modifications, translations, compilations, adaptations
**Jurisdiction note:** the threshold for what constitutes a derivative work
varies by jurisdiction. US copyright requires transformation, adaptation, or
arrangement of the original; the EU threshold differs.

**Fuzzy boundary:** ~~derivative threshold~~ — at what point does use of a
library make the using work a derivative work
**Review trigger:** relevant appellate ruling

**Forms:** derivative work

---

## substantial_portion

**Meaning:** An amount of the Software sufficient to trigger notice obligations.
**Known ambiguity:** no threshold has been formally defined in any jurisdiction.
30 years of MIT litigation have not produced a bright-line rule.
**Factors considered:** functional significance, percentage of codebase,
centrality to the work's purpose.

> This is the single most litigated term in MIT licensing. The absence of a
> definition is arguably intentional — a percentage threshold would be
> gamed immediately by any bad-faith actor.

**Fuzzy:** ~~threshold~~ — no numeric definition is possible or desirable here
**Review trigger:** appellate ruling establishing a threshold

**Forms:** substantial portion

---

## associated_documentation

**Meaning:** Documentation files that accompany and describe the Software.
**Includes:** README, man pages, API documentation
**Contested:** whether project blog posts, website content, or marketing
materials count as "associated documentation files"
**Fuzzy boundary:** ~~documentation_scope~~ — where documentation ends
and other content begins
**Review trigger:** when contested in legal proceedings

**Forms:** associated documentation

---

## Software

**Meaning:** The program, library, or codebase that is the subject of the license,
together with its *associated_documentation*.
**Note:** "Software" in MIT is defined by context — the document being licensed.
It is a placeholder whose referent is the specific program at point of application.

**Forms:** the software, software