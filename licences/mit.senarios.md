# Manifest

**OpenNorm:** 0.1
**Package:** scenarios.mit.basic
**Package-type:** scenario
**Version:** 1.0
**Import:**

    - /stdlib/licenses/mit

## Scenario: Bob Distributes Without Notice

**Facts:**

*the Software* isa *Software*
*Alice* has licensed *the Software* under *MIT*
*Bob* has obtained *the Software* from *Alice*
*Bob* has distributed *the Software*

**Questions:**

Does *Alice* isa *Licensor*
Does *Bob* isa *Licensee*
Does *Bob* **may** distribute *the Software*
Does *Bob* **must** include *the Copyright Notice*
Does *Alice* **is protected from** claim *damages*

## Scenario: Carol Sublicenses To Minor

**Facts:**

*the Software* isa *Software*
*Alice* has licensed *the Software* under *MIT*
*Bob* has obtained *the Software* from *Alice*
*Bob* has sublicensed *the Software* to *Carol*
*Carol* isa *minor*
*Carol* has distributed *the Software*

**Questions:**

Does *Bob* isa *Licensee*
Does *Carol* isa *Sublicensee*
Does *Carol* **may** distribute *the Software*
Does *Carol* **must** include *the Copyright Notice*

## Scenario: Alice Attempts Revocation

**Facts:**

*the Software* isa *Software*
*Alice* has licensed *the Software* under *MIT*
*Bob* has obtained *the Software* from *Alice*

**Questions:**

Does *Alice* **can** revoke *the License*
Does *Bob* **is protected from** revoke *the License*
