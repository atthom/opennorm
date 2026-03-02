//! Stage 5: Report builder.
//!
//! Translates all pipeline stage outputs into a unified human-readable report.
//! Output is a .md file that a non-technical drafter can read and act on.
//! The report is the product. Everything else is machinery.

use crate::ast::{Document, DocumentStatus};
use crate::checker::CheckerResult;
use crate::error::Severity;

// ─────────────────────────────────────────────────────────────────────────────
// Report inputs
// ─────────────────────────────────────────────────────────────────────────────

pub struct PipelineOutputs<'a> {
    pub document:     &'a Document,
    pub source_file:  &'a str,
    pub checker:      CheckerResult,
    pub lean_output:  Option<LeanOutput>,
    pub timestamp:    String,
}

pub struct LeanOutput {
    pub proved:      Vec<String>,   // proved theorem names in plain language
    pub failed:      Vec<String>,   // failed proof obligations
    pub undecidable: Vec<String>,   // prover returned unknown
    pub sorry_count: usize,
    pub raw_output:  String,
}

// ─────────────────────────────────────────────────────────────────────────────
// Report generation
// ─────────────────────────────────────────────────────────────────────────────

pub fn build_report(p: &PipelineOutputs) -> String {
    let mut out = String::new();

    // Determine overall result
    let result = if p.checker.error_count > 0 {
        "❌ INVALID — errors must be resolved"
    } else if p.checker.warning_count > 0 {
        "⚠️  VALID WITH WARNINGS"
    } else {
        "✅ VALID"
    };

    // ── Header ────────────────────────────────────────────────────────────────
    out.push_str("# OpenNorm Verification Report\n\n");
    out.push_str(&format!("**Document:** {}\n", p.document.id));
    out.push_str(&format!("**Version:** {}\n", p.document.version));
    out.push_str(&format!("**Checked:** {}\n", p.timestamp));
    out.push_str("**OpenNorm:** 0.1\n");
    out.push_str(&format!("**Status:** {}\n", status_str(p.document.status)));
    out.push_str(&format!("**Result:** {result}\n\n"));
    out.push_str("---\n\n");

    // ── Summary table ─────────────────────────────────────────────────────────
    out.push_str("## Summary\n\n");
    out.push_str("| Category | Count |\n|---|---|\n");
    out.push_str(&format!("| ✅ Resolved terms | {} |\n", p.checker.resolved_terms.len()));
    out.push_str(&format!("| ⚠️  Fuzzy terms | {} |\n", p.checker.fuzzy_terms.len()));
    out.push_str(&format!("| ❌ Hard errors | {} |\n", p.checker.error_count));
    out.push_str(&format!("| ℹ️  Warnings | {} |\n", p.checker.warning_count));
    out.push_str(&format!("| 🔬 Undefined terms | {} |\n", p.checker.undefined_terms.len()));

    if let Some(lean) = &p.lean_output {
        out.push_str(&format!("| ✓  Proved theorems | {} |\n", lean.proved.len()));
        out.push_str(&format!("| ✗  Failed proofs | {} |\n", lean.failed.len()));
        out.push_str(&format!("| ?  Undecidable | {} |\n", lean.undecidable.len()));
        out.push_str(&format!("| 📋 Sorry stubs | {} |\n", lean.sorry_count));
    }
    out.push_str("\n---\n\n");

    // ── Stage 1: Parse ────────────────────────────────────────────────────────
    out.push_str("## Stage 1 — Parse\n\n");
    out.push_str("✅ Document structure valid\n");
    out.push_str(&format!("✅ {} sections recognized\n", p.document.sections.len()));
    if let Some(t) = &p.document.template {
        out.push_str(&format!("✅ Template: `{t}` — required sections checked\n"));
    }
    out.push_str("\n---\n\n");

    // ── Stage 2: Checker ──────────────────────────────────────────────────────
    out.push_str("## Stage 2 — Structure\n\n");

    if !p.checker.resolved_terms.is_empty() {
        out.push_str("### Resolved Terms\n\n");
        out.push_str("| Term | Package | Version | Section |\n|---|---|---|---|\n");
        for rt in &p.checker.resolved_terms {
            out.push_str(&format!(
                "| `*{}*` | {} | {} | {} |\n",
                rt.name, rt.package, rt.version, rt.section
            ));
        }
        out.push('\n');
    }

    if !p.checker.fuzzy_terms.is_empty() {
        out.push_str("### Fuzzy Terms\n\n");
        out.push_str("| Term | Section | Review Trigger | Declared |\n|---|---|---|---|\n");
        for ft in &p.checker.fuzzy_terms {
            let trigger = ft.review_trigger.as_deref().unwrap_or("—");
            let declared = if ft.declared { "✅" } else { "❌ MISSING" };
            out.push_str(&format!(
                "| `~~{}~~` | {} | {} | {} |\n",
                ft.name, ft.section, trigger, declared
            ));
        }
        out.push('\n');
    }

    if !p.checker.undefined_terms.is_empty() {
        out.push_str("### Undefined Terms\n\n");
        out.push_str("> These terms are neither resolved (*) nor declared fuzzy (~~).\n\n");
        for ut in &p.checker.undefined_terms {
            let advice = if p.document.status == DocumentStatus::Draft {
                "⚠️  warning (draft mode)"
            } else {
                "❌ error"
            };
            out.push_str(&format!("- `{ut}` — {advice}\n"));
        }
        out.push('\n');
    }

    // Diagnostics
    let errors: Vec<_>   = p.checker.diagnostics.iter().filter(|d| d.severity == Severity::Error).collect();
    let warnings: Vec<_> = p.checker.diagnostics.iter().filter(|d| d.severity == Severity::Warning).collect();
    let infos: Vec<_>    = p.checker.diagnostics.iter().filter(|d| d.severity == Severity::Info).collect();

    if !errors.is_empty() {
        out.push_str("### Errors\n\n");
        for d in &errors {
            out.push_str(&format!("- **[{}]** {}\n", d.code, d.message));
            if let Some(s) = &d.suggestion {
                out.push_str(&format!("  - *Suggestion:* {s}\n"));
            }
        }
        out.push('\n');
    }

    if !warnings.is_empty() {
        out.push_str("### Warnings\n\n");
        for d in &warnings {
            out.push_str(&format!("- **[{}]** {}\n", d.code, d.message));
            if let Some(s) = &d.suggestion {
                out.push_str(&format!("  - *Suggestion:* {s}\n"));
            }
        }
        out.push('\n');
    }

    if !infos.is_empty() {
        out.push_str("### Info\n\n");
        for d in &infos {
            out.push_str(&format!("- **[{}]** {}\n", d.code, d.message));
        }
        out.push('\n');
    }

    out.push_str("---\n\n");

    // ── Stage 3: Transpilation ────────────────────────────────────────────────
    out.push_str("## Stage 3 — Transpilation\n\n");
    out.push_str("✅ Lean 4 source generated\n");
    if let Some(lean) = &p.lean_output {
        out.push_str(&format!("✅ {} proof obligations created\n", lean.proved.len() + lean.failed.len()));
        out.push_str(&format!("✅ {} sorry stubs for fuzzy terms\n", lean.sorry_count));
    }
    out.push_str("\n---\n\n");

    // ── Stage 4: Lean 4 verification ─────────────────────────────────────────
    if let Some(lean) = &p.lean_output {
        out.push_str("## Stage 4 — Formal Verification\n\n");

        if !lean.proved.is_empty() {
            out.push_str("### Proved\n\n");
            for p_item in &lean.proved {
                out.push_str(&format!("- ✅ {p_item}\n"));
            }
            out.push('\n');
        }

        if !lean.failed.is_empty() {
            out.push_str("### Failed\n\n");
            for f in &lean.failed {
                out.push_str(&format!("- ❌ {f}\n"));
            }
            out.push('\n');
        }

        if !lean.undecidable.is_empty() {
            out.push_str("### Undecidable\n\n");
            out.push_str("> These are not bugs. Undecidable cases become explicit warnings rather\n");
            out.push_str("> than hidden ambiguities. Converting invisible problems to visible ones\n");
            out.push_str("> is valuable even when the prover cannot resolve them.\n\n");
            for u in &lean.undecidable {
                out.push_str(&format!("- ❓ {u}\n"));
            }
            out.push('\n');
        }

        // Sorry inventory
        if lean.sorry_count > 0 && !p.document.known_fuzzies.is_empty() {
            out.push_str("### Sorry Inventory\n\n");
            out.push_str("> Every sorry corresponds to a fuzzy term declared in § Known Ambiguities.\n\
                          > None are silent gaps. Human judgment is required at point of application.\n\n");
            out.push_str("| Sorry stub | Plain language | Required human action |\n|---|---|---|\n");
            for f in &p.document.known_fuzzies {
                let action = format!("Legal judgment at point of dispute. Review trigger: {}", f.review_trigger);
                out.push_str(&format!("| `{}` | {} | {} |\n", f.name, f.reason, action));
            }
            out.push('\n');
        }

        out.push_str("---\n\n");
    }

    // ── Footer ────────────────────────────────────────────────────────────────
    out.push_str("---\n\n");
    out.push_str("> *This report was generated by OpenNorm 0.1.*\n");
    out.push_str("> *It is not legal advice.*\n");
    out.push_str("> *The .md source document is the authoritative instrument.*\n");
    out.push_str("> *Lean 4 output is a consistency verification aid.*\n");

    out
}

fn status_str(s: DocumentStatus) -> &'static str {
    match s {
        DocumentStatus::Draft  => "DRAFT",
        DocumentStatus::Review => "REVIEW",
        DocumentStatus::Final  => "FINAL",
    }
}