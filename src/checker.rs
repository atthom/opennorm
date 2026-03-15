//! Stage 2: Structural validation for stdlib packages.
//!
//! The checker validates that stdlib packages conform to the spec:
//!  - Manifest section with all required fields
//!  - Taxonomies with proper hierarchy
//!  - Definitions with name, free_forms, meaning
//!  - Optional Axioms and FormalDescription sections

use std::collections::HashSet;
use crate::ast::*;
use crate::error::{Diagnostic, OpenNormError, Severity};

// ─────────────────────────────────────────────────────────────────────────────
// Public interface
// ─────────────────────────────────────────────────────────────────────────────

pub struct CheckerResult {
    pub diagnostics:     Vec<Diagnostic>,
    pub error_count:     usize,
    pub warning_count:   usize,
}

pub fn check(doc: &Document) -> Result<CheckerResult, OpenNormError> {
    let mut diagnostics = Vec::new();

    // For stdlib packages, enforce strict structure
    if doc.manifest.package_type == PackageType::Stdlib {
        check_stdlib_structure(doc, &mut diagnostics);
    }

    let error_count   = diagnostics.iter().filter(|d| d.severity == Severity::Error).count();
    let warning_count = diagnostics.iter().filter(|d| d.severity == Severity::Warning).count();

    Ok(CheckerResult {
        diagnostics,
        error_count,
        warning_count,
    })
}

// ─────────────────────────────────────────────────────────────────────────────
// Stdlib structure validation
// ─────────────────────────────────────────────────────────────────────────────

fn check_stdlib_structure(doc: &Document, diags: &mut Vec<Diagnostic>) {
    // Check that legacy sections are not used in stdlib
    if !doc.legacy_sections.is_empty() {
        for section in &doc.legacy_sections {
            if !section.kind.is_stdlib_section() {
                diags.push(Diagnostic {
                    severity:   Severity::Error,
                    code:       "E001",
                    message:    format!(
                        "Stdlib package contains invalid section: '{}'. Only Taxonomies, Definitions, Axioms, and FormalDescription are allowed.",
                        section.header_text
                    ),
                    location:   section.location.clone(),
                    suggestion: Some("Remove this section or restructure as Taxonomies/Definitions".into()),
                });
            }
        }
    }

    // Check that all taxonomy items have definitions
    let defined_names: HashSet<String> = doc.definitions.iter()
        .map(|d| d.name.clone())
        .collect();

    for taxonomy in &doc.taxonomies {
        check_taxonomy_items_defined(&taxonomy.items, &defined_names, &taxonomy.name, diags);
    }

    // Check definition structure
    for def in &doc.definitions {
        if def.meaning.trim().is_empty() {
            diags.push(Diagnostic {
                severity:   Severity::Error,
                code:       "E003",
                message:    format!("Definition '{}' has empty Meaning field", def.name),
                location:   def.location.clone(),
                suggestion: Some("Add a Meaning field with the definition text".into()),
            });
        }
    }

    // Check code blocks have Lean content
    if let Some(axioms) = &doc.axioms {
        check_code_section(axioms, "Axioms", diags);
    }
    if let Some(formal) = &doc.formal_description {
        check_code_section(formal, "FormalDescription", diags);
    }
}

fn check_taxonomy_items_defined(
    items: &[TaxonomyItem],
    defined: &HashSet<String>,
    taxonomy_name: &str,
    diags: &mut Vec<Diagnostic>,
) {
    for item in items {
        if !defined.contains(&item.name) {
            diags.push(Diagnostic {
                severity:   Severity::Warning,
                code:       "W001",
                message:    format!(
                    "Taxonomy item '{}' in {} has no definition",
                    item.name, taxonomy_name
                ),
                location:   item.location.clone(),
                suggestion: Some(format!("Add a definition for '{}'", item.name)),
            });
        }
        check_taxonomy_items_defined(&item.children, defined, taxonomy_name, diags);
    }
}

fn check_code_section(section: &CodeSection, name: &str, diags: &mut Vec<Diagnostic>) {
    if section.code_blocks.is_empty() {
        diags.push(Diagnostic {
            severity:   Severity::Warning,
            code:       "W002",
            message:    format!("Section {} has no code blocks", name),
            location:   Location::default(),
            suggestion: Some("Add ```lean4 code blocks or remove the section".into()),
        });
    }

    for block in &section.code_blocks {
        if block.content.trim().is_empty() {
            diags.push(Diagnostic {
                severity:   Severity::Warning,
                code:       "W003",
                message:    format!("Empty code block in {}", name),
                location:   block.location.clone(),
                suggestion: None,
            });
        }
    }
}