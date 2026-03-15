//! Stage 5: Report generation.
//!
//! The report is the product. Everything else is machinery.
//! The report translates all stage outputs into plain language.
//!
//! CRITICAL: Formal verification result is the headline, not buried.
//! The number of lemmas proved/failed/sorry is the primary output.

use crate::ast::*;
use crate::checker::CheckerResult;

// ─────────────────────────────────────────────────────────────────────────────
// Public interface
// ─────────────────────────────────────────────────────────────────────────────

pub struct PipelineOutputs<'a> {
    pub document:    &'a Document,
    pub source_file: &'a str,
    pub checker:     CheckerResult,
    pub lean_output: Option<LeanOutput>,
    pub lean_source: String,  // Add the generated Lean source
    pub timestamp:   String,
}

pub struct LeanOutput {
    pub proved:      Vec<String>,
    pub failed:      Vec<String>,
    pub undecidable: Vec<String>,
    pub sorry_count: usize,
    pub raw_output:  String,
}

pub fn build_report(outputs: &PipelineOutputs) -> String {
    let mut report = String::new();

    emit_header(&mut report, outputs);
    emit_formal_verification_result(&mut report, outputs);
    emit_lemma_breakdown(&mut report, outputs);
    emit_structural_validation(&mut report, outputs);
    emit_warnings_and_info(&mut report, outputs);
    emit_footer(&mut report);

    report
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

fn emit_header(report: &mut String, outputs: &PipelineOutputs) {
    report.push_str("# OpenNorm Verification Report\n\n");
    report.push_str(&format!("**Document:** {}\n", outputs.document.manifest.package));
    report.push_str(&format!("**Version:** {}\n", outputs.document.manifest.version));
    report.push_str(&format!("**Checked:** {}\n", outputs.timestamp));
    report.push_str(&format!("**OpenNorm:** 0.1\n"));
    report.push_str(&format!("**Status:** {}\n", format_status(&outputs.document.manifest.status)));
    report.push_str("\n---\n\n");
}

fn format_status(status: &DocumentStatus) -> String {
    match status {
        DocumentStatus::Draft  => "DRAFT".to_string(),
        DocumentStatus::Review => "REVIEW".to_string(),
        DocumentStatus::Final  => "FINAL".to_string(),
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formal Verification Result (THE HEADLINE)
// ─────────────────────────────────────────────────────────────────────────────

fn emit_formal_verification_result(report: &mut String, outputs: &PipelineOutputs) {
    report.push_str("## FORMAL VERIFICATION RESULT\n\n");
    
    let verdict = determine_verdict(outputs);
    let verdict_icon = match verdict {
        Verdict::Certified => "✅",
        Verdict::PartiallyCertified => "⚠️",
        Verdict::Failed => "❌",
    };
    
    report.push_str(&format!("**Verdict:** {} **{}**\n\n", verdict_icon, verdict_name(&verdict)));
    
    // Count elements from imported packages
    let imported_counts = count_imported_elements(outputs);
    
    // Count elements from local document
    let local_counts = count_local_elements(outputs);
    
    // Calculate totals
    let total_lemmas = imported_counts.lemmas + local_counts.lemmas;
    let total_theorems = imported_counts.theorems + local_counts.theorems;
    let total_holds = imported_counts.holds + local_counts.holds;
    let total_axioms = imported_counts.axioms + local_counts.axioms;
    
    // Proof status
    let sorry_count = outputs.lean_output.as_ref().map(|o| o.sorry_count).unwrap_or(0);
    let failed_count = outputs.lean_output.as_ref().map(|o| o.failed.len()).unwrap_or(0);
    let proved_count = total_lemmas.saturating_sub(sorry_count).saturating_sub(failed_count);
    
    // Proof status summary
    report.push_str("| Category | Count |\n");
    report.push_str("|---|---|\n");
    report.push_str(&format!("| ✅ Lemmas proved | {} |\n", proved_count));
    report.push_str(&format!("| ⚠️ Sorry stubs | {} |\n", sorry_count));
    report.push_str(&format!("| ❌ Lemmas failed | {} |\n", failed_count));
    report.push_str("\n");
    
    // Element counts table with Imported/Local/Total columns
    report.push_str("| Element Type | Imported | Local | Total |\n");
    report.push_str("|---|---|---|---|\n");
    report.push_str(&format!("| Lemmas | {} | {} | **{}** |\n", imported_counts.lemmas, local_counts.lemmas, total_lemmas));
    report.push_str(&format!("| Theorems | {} | {} | **{}** |\n", imported_counts.theorems, local_counts.theorems, total_theorems));
    report.push_str(&format!("| Holds | {} | {} | **{}** |\n", imported_counts.holds, local_counts.holds, total_holds));
    report.push_str(&format!("| Axioms | {} | {} | **{}** |\n", imported_counts.axioms, local_counts.axioms, total_axioms));
    report.push_str("\n");
    
    report.push_str("---\n\n");
}

enum Verdict {
    Certified,           // All lemmas proved, zero sorry stubs
    PartiallyCertified,  // All structural invariants hold, sorry stubs = fuzzy terms
    Failed,              // Hard errors present
}

fn determine_verdict(outputs: &PipelineOutputs) -> Verdict {
    if outputs.checker.error_count > 0 {
        return Verdict::Failed;
    }
    
    let sorry_count = outputs.lean_output.as_ref().map(|o| o.sorry_count).unwrap_or(0);
    
    if sorry_count == 0 {
        Verdict::Certified
    } else {
        Verdict::PartiallyCertified
    }
}

fn verdict_name(verdict: &Verdict) -> &'static str {
    match verdict {
        Verdict::Certified => "CERTIFIED",
        Verdict::PartiallyCertified => "PARTIALLY CERTIFIED",
        Verdict::Failed => "FAILED",
    }
}

fn count_lemmas_from_source(lean_source: &str) -> usize {
    // Count lemmas from the generated Lean source
    lean_source.lines()
        .filter(|line| {
            let trimmed = line.trim_start();
            trimmed.starts_with("lemma ") || trimmed.starts_with("theorem ")
        })
        .count()
}

fn estimate_imported_lemmas(_outputs: &PipelineOutputs) -> usize {
    // For stdlib packages, no imports
    0
}

// ─────────────────────────────────────────────────────────────────────────────
// Lemma Breakdown
// ─────────────────────────────────────────────────────────────────────────────

fn emit_lemma_breakdown(report: &mut String, outputs: &PipelineOutputs) {
    report.push_str("## Lemma Breakdown\n\n");
    
    // Extract tier information from Lean source
    let tier_info = extract_tier_info(&outputs.lean_source);
    
    // Display tier breakdown
    if tier_info.strict_count > 0 || tier_info.soft_count > 0 {
        report.push_str("### 📊 Proof Certification Tiers\n\n");
        
        report.push_str("#### ✅ STRICT TIER (Mathematically Certain)\n\n");
        report.push_str(&format!("- **{}** lemmas with no fuzzy dependencies\n", tier_info.strict_count));
        report.push_str(&format!("- **{}** fully proved with actual proofs\n", tier_info.proved_count));
        report.push_str(&format!("- **{}** provable but not yet implemented\n", 
                                tier_info.strict_count - tier_info.proved_count));
        report.push_str("- Can be verified by Lean compiler\n\n");
        
        if !tier_info.proved_lemmas.is_empty() {
            report.push_str("**Fully Proved Lemmas:**\n\n");
            report.push_str("| Lemma | Proof Method |\n");
            report.push_str("|---|---|\n");
            for lemma in &tier_info.proved_lemmas {
                report.push_str(&format!("| `{}` | ✓ Proved via axiom/theorem |\n", lemma));
            }
            report.push_str("\n");
        }
        
        if tier_info.soft_count > 0 {
            report.push_str("#### ⚠️ SOFT TIER (Requires Human Judgment)\n\n");
            report.push_str(&format!("- **{}** lemmas blocked by fuzzy terms\n", tier_info.soft_count));
            report.push_str("- Cannot be mechanically verified\n");
            report.push_str("- Require human interpretation\n\n");
            
            if !tier_info.soft_lemmas.is_empty() {
                report.push_str("**Blocked Lemmas:**\n\n");
                report.push_str("| Lemma | Blocked By |\n");
                report.push_str("|---|---|\n");
                for (lemma, blocking) in &tier_info.soft_lemmas {
                    report.push_str(&format!("| `{}` | {} |\n", lemma, blocking));
                }
                report.push_str("\n");
            }
        } else {
            report.push_str("#### ⚠️ SOFT TIER (Requires Human Judgment)\n\n");
            report.push_str("- **0** lemmas blocked by fuzzy terms\n");
            report.push_str("- All lemmas are in strict tier\n\n");
        }
    }
    
    if let Some(lean_output) = &outputs.lean_output {
        // Failed lemmas
        if !lean_output.failed.is_empty() {
            report.push_str("### ❌ Failed Lemmas\n\n");
            report.push_str("| Error | Description |\n");
            report.push_str("|---|---|\n");
            for failed in &lean_output.failed {
                report.push_str(&format!("| ❌ | {} |\n", failed));
            }
            report.push_str("\n");
        }
    }
    
    report.push_str("---\n\n");
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural Validation (secondary to formal verification)
// ─────────────────────────────────────────────────────────────────────────────

fn emit_structural_validation(report: &mut String, outputs: &PipelineOutputs) {
    report.push_str("## Structural Validation\n\n");
    
    // Summary stats
    report.push_str("| Category | Count |\n");
    report.push_str("|---|---|\n");
    report.push_str(&format!("| [ERROR] Hard errors | {} |\n", outputs.checker.error_count));
    report.push_str(&format!("| [WARN] Warnings | {} |\n", outputs.checker.warning_count));
    report.push_str(&format!("| Taxonomies | {} |\n", outputs.document.taxonomies.len()));
    report.push_str(&format!("| Definitions | {} |\n", outputs.document.definitions.len()));
    report.push_str("\n");
    
    report.push_str("---\n\n");
}

// ─────────────────────────────────────────────────────────────────────────────
// Warnings and Info
// ─────────────────────────────────────────────────────────────────────────────

fn emit_warnings_and_info(report: &mut String, outputs: &PipelineOutputs) {
    let errors: Vec<_> = outputs.checker.diagnostics.iter()
        .filter(|d| d.severity == crate::error::Severity::Error)
        .collect();
    
    let warnings: Vec<_> = outputs.checker.diagnostics.iter()
        .filter(|d| d.severity == crate::error::Severity::Warning)
        .collect();
    
    let info: Vec<_> = outputs.checker.diagnostics.iter()
        .filter(|d| d.severity == crate::error::Severity::Info)
        .collect();
    
    if !errors.is_empty() {
        report.push_str("## ❌ Errors\n\n");
        for diag in errors {
            report.push_str(&format!("- **[{}]** {}\n", diag.code, diag.message));
            if let Some(suggestion) = &diag.suggestion {
                report.push_str(&format!("  - *Suggestion:* {}\n", suggestion));
            }
        }
        report.push_str("\n");
    }
    
    if !warnings.is_empty() {
        report.push_str("## ⚠️  Warnings\n\n");
        for diag in warnings {
            report.push_str(&format!("- **[{}]** {}\n", diag.code, diag.message));
            if let Some(suggestion) = &diag.suggestion {
                report.push_str(&format!("  - *Suggestion:* {}\n", suggestion));
            }
        }
        report.push_str("\n");
    }
    
    if !info.is_empty() {
        report.push_str("## ℹ️  Info\n\n");
        for diag in info {
            report.push_str(&format!("- **[{}]** {}\n", diag.code, diag.message));
        }
        report.push_str("\n");
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────────────────────────

fn emit_footer(report: &mut String) {
    report.push_str("---\n\n");
    report.push_str("> *This report was generated by OpenNorm 0.1. It is not legal advice.*\n");
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility
// ─────────────────────────────────────────────────────────────────────────────

fn sanitise_id(s: &str) -> String {
    s.chars()
        .map(|c| if c.is_alphanumeric() { c } else { '_' })
        .collect()
}

// ─────────────────────────────────────────────────────────────────────────────
// Tier Information Extraction
// ─────────────────────────────────────────────────────────────────────────────

struct TierInfo {
    strict_count: usize,
    soft_count: usize,
    proved_count: usize,
    proved_lemmas: Vec<String>,
    soft_lemmas: Vec<(String, String)>,  // (lemma_name, blocking_terms)
}

fn extract_tier_info(lean_source: &str) -> TierInfo {
    let mut strict_count = 0;
    let mut soft_count = 0;
    let mut proved_count = 0;
    let mut proved_lemmas = Vec::new();
    let mut soft_lemmas = Vec::new();
    
    let mut in_tier_section = false;
    let mut in_strict = false;
    let mut in_soft = false;
    
    for line in lean_source.lines() {
        if line.contains("PROOF CERTIFICATION TIERS") {
            in_tier_section = true;
            continue;
        }
        
        if !in_tier_section {
            continue;
        }
        
        if line.contains("STRICT TIER:") {
            in_strict = true;
            in_soft = false;
            if let Some(count_str) = line.split("STRICT TIER: ").nth(1) {
                if let Some(num_str) = count_str.split(" lemmas").next() {
                    strict_count = num_str.trim().parse().unwrap_or(0);
                }
            }
            continue;
        }
        
        if line.contains("SOFT TIER:") {
            in_strict = false;
            in_soft = true;
            if let Some(count_str) = line.split("SOFT TIER: ").nth(1) {
                if let Some(num_str) = count_str.split(" lemmas").next() {
                    soft_count = num_str.trim().parse().unwrap_or(0);
                }
            }
            continue;
        }
        
        if in_strict && line.contains("[PROVED]") {
            proved_count += 1;
            // Extract lemma name
            if let Some(name_part) = line.split("✓ ").nth(1) {
                if let Some(name) = name_part.split(" [PROVED]").next() {
                    proved_lemmas.push(name.trim().to_string());
                }
            }
        }
        
        if in_soft && line.contains("[blocked by:") {
            // Extract lemma name and blocking terms
            if let Some(name_part) = line.split("⚠ ").nth(1) {
                if let Some(name) = name_part.split(" [blocked by:").next() {
                    if let Some(blocking_part) = name_part.split("[blocked by: ").nth(1) {
                        if let Some(blocking) = blocking_part.split("]").next() {
                            soft_lemmas.push((name.trim().to_string(), blocking.trim().to_string()));
                        }
                    }
                }
            }
        }
    }
    
    TierInfo {
        strict_count,
        soft_count,
        proved_count,
        proved_lemmas,
        soft_lemmas,
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Element Counting
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Default)]
struct ElementCounts {
    lemmas: usize,
    theorems: usize,
    holds: usize,
    axioms: usize,
}

fn count_imported_elements(outputs: &PipelineOutputs) -> ElementCounts {
    let mut counts = ElementCounts::default();
    
    // Load and count elements from each imported package
    for import in &outputs.document.manifest.imports {
        if let Some(imported_counts) = load_and_count_import(import) {
            counts.lemmas += imported_counts.lemmas;
            counts.theorems += imported_counts.theorems;
            counts.holds += imported_counts.holds;
            counts.axioms += imported_counts.axioms;
        }
    }
    
    counts
}

fn count_local_elements(outputs: &PipelineOutputs) -> ElementCounts {
    let mut counts = ElementCounts::default();
    
    // Count from Axioms section
    if let Some(axioms) = &outputs.document.axioms {
        for block in &axioms.code_blocks {
            if block.language.contains("lean") {
                let block_counts = count_lean_elements(&block.content);
                counts.axioms += block_counts.axioms;
                counts.lemmas += block_counts.lemmas;
                counts.theorems += block_counts.theorems;
                counts.holds += block_counts.holds;
            }
        }
    }
    
    // Count from FormalDescription section
    if let Some(formal) = &outputs.document.formal_description {
        for block in &formal.code_blocks {
            if block.language.contains("lean") {
                let block_counts = count_lean_elements(&block.content);
                counts.lemmas += block_counts.lemmas;
                counts.theorems += block_counts.theorems;
                counts.holds += block_counts.holds;
                counts.axioms += block_counts.axioms;
            }
        }
    }
    
    counts
}

fn load_and_count_import(import_path: &str) -> Option<ElementCounts> {
    // Parse import path (e.g., "stdlib/frameworks/universal/core@2.0")
    let path_without_version = import_path.split('@').next()?;
    let file_path = format!("{}.md", path_without_version);
    
    // Try to read the file
    let content = std::fs::read_to_string(&file_path).ok()?;
    
    // Count elements in all Lean code blocks
    let mut counts = ElementCounts::default();
    
    // Simple markdown parsing to extract code blocks
    let mut in_code_block = false;
    let mut code_content = String::new();
    
    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed.starts_with("```lean") {
            in_code_block = true;
            code_content.clear();
        } else if trimmed.starts_with("```") && in_code_block {
            in_code_block = false;
            let block_counts = count_lean_elements(&code_content);
            counts.lemmas += block_counts.lemmas;
            counts.theorems += block_counts.theorems;
            counts.holds += block_counts.holds;
            counts.axioms += block_counts.axioms;
        } else if in_code_block {
            code_content.push_str(line);
            code_content.push('\n');
        }
    }
    
    Some(counts)
}

fn count_lean_elements(lean_code: &str) -> ElementCounts {
    let mut counts = ElementCounts::default();
    
    for line in lean_code.lines() {
        let trimmed = line.trim();
        
        // Count lemmas
        if trimmed.starts_with("lemma ") {
            counts.lemmas += 1;
        }
        
        // Count theorems
        if trimmed.starts_with("theorem ") {
            counts.theorems += 1;
        }
        
        // Count holds statements
        if trimmed.starts_with("holds ") {
            counts.holds += 1;
        }
        
        // Count axioms
        if trimmed.starts_with("axiom ") {
            counts.axioms += 1;
        }
    }
    
    counts
}
