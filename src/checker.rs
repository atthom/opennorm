//! Stage 2: Structural validation.
//!
//! The checker runs on the AST produced by the parser. It:
//!  1. Validates template invariants (required sections, required fields).
//!  2. Classifies every term as Resolved, Fuzzy, or Undefined.
//!  3. Resolves Resolved terms against the loaded stdlib manifests.
//!  4. Verifies every Fuzzy term is declared in § Known Ambiguities.
//!  5. Validates references (opennorm://, legal://, #anchor).
//!  6. Checks import pins (required at Review/Final).
//!  7. Detects conflicts: same action simultaneously permitted and forbidden.

use std::collections::HashSet;
use crate::ast::*;
use crate::error::{Diagnostic, OpenNormError, Severity};
use crate::stdlib::{ManifestIndex, StdlibRegistry};

// ─────────────────────────────────────────────────────────────────────────────
// Public interface
// ─────────────────────────────────────────────────────────────────────────────

pub struct CheckerResult {
    pub diagnostics:    Vec<Diagnostic>,
    pub resolved_terms: Vec<ResolvedTermInfo>,
    pub fuzzy_terms:    Vec<FuzzyTermInfo>,
    pub undefined_terms: Vec<String>,
    pub error_count:    usize,
    pub warning_count:  usize,
}

#[derive(Debug, Clone)]
pub struct ResolvedTermInfo {
    pub name:    String,
    pub package: String,
    pub version: String,
    pub section: String,
}

#[derive(Debug, Clone)]
pub struct FuzzyTermInfo {
    pub name:           String,
    pub section:        String,
    pub review_trigger: Option<String>,
    pub declared:       bool,   // true if found in § Known Ambiguities
}

pub fn check(
    doc:      &mut Document,
    registry: &mut StdlibRegistry,
) -> Result<CheckerResult, OpenNormError> {
    let mut diagnostics    = Vec::new();
    let mut resolved_terms = Vec::new();
    let mut fuzzy_terms    = Vec::new();
    let mut undefined_terms = Vec::new();

    // Build manifest index from all imported packages
    let mut manifest = ManifestIndex::new();
    for import in &doc.imports {
        let pkg = registry.load(&import.package, import.version.as_deref())?;
        manifest.merge(&pkg.manifest);
    }

    // 1. Template validation
    if let Some(template) = &doc.template.clone() {
        check_template(doc, template, &mut diagnostics);
    }

    // 2. Import pin validation
    if matches!(doc.status, DocumentStatus::Review | DocumentStatus::Final) {
        for import in &doc.imports {
            if import.version.is_none() {
                diagnostics.push(Diagnostic {
                    severity:   Severity::Error,
                    code:       "E010",
                    message:    format!("Import '{}' is unpinned — version required in review/final mode", import.package),
                    location:   Location::default(),
                    suggestion: Some(format!("Pin to a specific version, e.g. {}@1.0", import.package)),
                });
            }
        }
    }

    // 3. Build Known Ambiguities index
    let declared_fuzzies: HashSet<String> = doc.known_fuzzies
        .iter()
        .map(|f| f.name.clone())
        .collect();

    // 4. Term classification — walk all sections
    for section in &mut doc.sections {
        // Fields
        for field in &mut section.fields {
            check_term_in_field(
                field, &manifest, &declared_fuzzies, &doc.status,
                &section.header_text,
                &mut diagnostics, &mut resolved_terms,
                &mut fuzzy_terms, &mut undefined_terms,
            );
        }
        // Bullets
        for bullet in &mut section.bullets {
            check_term_in_bullet(
                bullet, &manifest, &declared_fuzzies, &doc.status,
                &section.header_text,
                &mut diagnostics, &mut resolved_terms,
                &mut fuzzy_terms, &mut undefined_terms,
            );
        }
        // Prose: regex scan for *word* and ~~word~~ patterns
        for prose in &section.prose {
            check_terms_in_prose(
                prose, &manifest, &declared_fuzzies, &doc.status,
                &section.header_text,
                &mut diagnostics, &mut resolved_terms,
                &mut fuzzy_terms, &mut undefined_terms,
            );
        }
    }

    // 5. Fuzzy term declaration check
    // Every fuzzy term encountered must have a declaration in Known Ambiguities.
    for ft in &mut fuzzy_terms {
        if declared_fuzzies.contains(&ft.name) {
            ft.declared = true;
            // Enrich with review trigger from the declaration
            if let Some(kf) = doc.known_fuzzies.iter().find(|k| k.name == ft.name) {
                ft.review_trigger = Some(kf.review_trigger.clone());
            }
        } else {
            diagnostics.push(Diagnostic {
                severity:   Severity::Error,
                code:       "E020",
                message:    format!(
                    "Fuzzy term '~~{}~~' in § {} is not declared in § Known Ambiguities",
                    ft.name, ft.section
                ),
                location:   Location::default(),
                suggestion: Some(format!(
                    "Add '~~{}~~' to § Known Ambiguities with a review trigger",
                    ft.name
                )),
            });
        }
    }

    // 6. Conflict detection
    detect_conflicts(doc, &mut diagnostics);

    // 7. Structural warnings
    check_structural_warnings(doc, &mut diagnostics);

    let error_count   = diagnostics.iter().filter(|d| d.severity == Severity::Error).count();
    let warning_count = diagnostics.iter().filter(|d| d.severity == Severity::Warning).count();

    Ok(CheckerResult {
        diagnostics,
        resolved_terms,
        fuzzy_terms,
        undefined_terms,
        error_count,
        warning_count,
    })
}

// ─────────────────────────────────────────────────────────────────────────────
// Template validation
// ─────────────────────────────────────────────────────────────────────────────

fn check_template(doc: &Document, template: &str, diags: &mut Vec<Diagnostic>) {
    let required = match template {
        "license" => vec![SectionKind::Grant, SectionKind::Obligations, SectionKind::Waivers],
        "charter" => vec![SectionKind::Grant, SectionKind::Obligations],
        _         => vec![],
    };

    let present: HashSet<_> = doc.sections.iter().map(|s| s.kind.clone()).collect();

    for req in required {
        if !present.contains(&req) {
            diags.push(Diagnostic {
                severity:   Severity::Error,
                code:       "E001",
                message:    format!("Template '{template}' requires § {:?} section — not found", req),
                location:   Location::default(),
                suggestion: Some(format!("Add a ## {:?} section", req)),
            });
        }
    }

    // License-specific: Grant must have To and Permitted fields
    if template == "license" {
        if let Some(grant) = doc.sections.iter().find(|s| s.kind == SectionKind::Grant) {
            let field_labels: HashSet<_> = grant.fields.iter()
                .map(|f| f.label.to_lowercase())
                .collect();
            for required_field in &["to", "permitted"] {
                if !field_labels.contains(*required_field) {
                    diags.push(Diagnostic {
                        severity:   Severity::Error,
                        code:       "E002",
                        message:    format!("§ Grant requires **{}:** field", required_field),
                        location:   grant.location.clone(),
                        suggestion: None,
                    });
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conflict detection
// ─────────────────────────────────────────────────────────────────────────────

/// A term is in conflict if it appears in both Permitted and Prohibitions
/// in the same document (under the same conditions, if conditions are present).
fn detect_conflicts(doc: &Document, diags: &mut Vec<Diagnostic>) {
    let permitted_terms: HashSet<String> = doc.sections.iter()
        .filter(|s| s.kind == SectionKind::Grant)
        .flat_map(|s| s.bullets.iter())
        .map(|b| b.term.name().to_string())
        .collect();

    let forbidden_terms: HashSet<String> = doc.sections.iter()
        .filter(|s| s.kind == SectionKind::Prohibitions)
        .flat_map(|s| s.bullets.iter())
        .map(|b| b.term.name().to_string())
        .collect();

    for conflict in permitted_terms.intersection(&forbidden_terms) {
        diags.push(Diagnostic {
            severity:   Severity::Error,
            code:       "E030",
            message:    format!(
                "Conflict: '{}' is simultaneously listed in § Grant (permitted) and § Prohibitions (forbidden)",
                conflict
            ),
            location:   Location::default(),
            suggestion: Some("Remove from one section, or add a condition to distinguish the cases".into()),
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural warnings
// ─────────────────────────────────────────────────────────────────────────────

fn check_structural_warnings(doc: &Document, diags: &mut Vec<Diagnostic>) {
    let section_kinds: HashSet<_> = doc.sections.iter().map(|s| s.kind.clone()).collect();

    if !section_kinds.contains(&SectionKind::Jurisdiction) {
        diags.push(Diagnostic {
            severity:   Severity::Warning,
            code:       "W001",
            message:    "No § Jurisdiction declared — governing law is undefined".into(),
            location:   Location::default(),
            suggestion: Some("Add optional § Jurisdiction section, or acknowledge in § Structural Notes".into()),
        });
    }

    if doc.template.as_deref() == Some("license") {
        let has_version_governance = doc.sections.iter()
            .any(|s| matches!(s.kind, SectionKind::StructuralNotes | SectionKind::Unknown(_))
                && s.prose.iter().any(|p| p.to_lowercase().contains("version governance")));
        if !has_version_governance {
            diags.push(Diagnostic {
                severity:   Severity::Warning,
                code:       "W002",
                message:    "No version governance declared — who controls the name and namespace?".into(),
                location:   Location::default(),
                suggestion: Some("Add a version governance note, or acknowledge in § Structural Notes".into()),
            });
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Term checking helpers (stubs — full implementation uses manifest index)
// ─────────────────────────────────────────────────────────────────────────────

fn check_term(
    term:             &mut Term,
    manifest:         &ManifestIndex,
    _declared_fuzzies: &HashSet<String>,
    status:           &DocumentStatus,
    section_name:     &str,
    diags:            &mut Vec<Diagnostic>,
    resolved:         &mut Vec<ResolvedTermInfo>,
    fuzzies:          &mut Vec<FuzzyTermInfo>,
    undefined:        &mut Vec<String>,
    location:         &Location,
) {
    match term {
        Term::Resolved { name, package, version } => {
            if let Some(entry) = manifest.lookup(name) {
                *package = Some(entry.package.clone());
                *version = Some(entry.version.clone());
                resolved.push(ResolvedTermInfo {
                    name:    name.clone(),
                    package: entry.package.clone(),
                    version: entry.version.clone(),
                    section: section_name.to_string(),
                });
            } else {
                diags.push(Diagnostic {
                    severity:   Severity::Error,
                    code:       "E011",
                    message:    format!("Resolved term '*{}*' not found in any imported manifest", name),
                    location:   location.clone(),
                    suggestion: Some(format!("Add an import that defines '{}', or move to local Definitions", name)),
                });
            }
        }
        Term::Fuzzy { name, .. } => {
            fuzzies.push(FuzzyTermInfo {
                name:           name.clone(),
                section:        section_name.to_string(),
                review_trigger: None,
                declared:       false,   // will be updated in pass 2
            });
        }
        Term::Undefined(name) => {
            undefined.push(name.clone());
            let severity = match status {
                DocumentStatus::Draft  => Severity::Warning,
                _                     => Severity::Error,
            };
            diags.push(Diagnostic {
                severity,
                code:       if severity == Severity::Error { "E012" } else { "W010" },
                message:    format!("Term '{}' is plain text — not resolved (*) or declared fuzzy (~~)", name),
                location:   location.clone(),
                suggestion: Some(format!("Wrap as *{}* if defined in stdlib, or ~~{}~~ if intentionally flexible", name, name)),
            });
        }
    }
}

fn check_term_in_field(
    field: &mut Field, manifest: &ManifestIndex,
    declared_fuzzies: &HashSet<String>, status: &DocumentStatus,
    section_name: &str,
    diags: &mut Vec<Diagnostic>, resolved: &mut Vec<ResolvedTermInfo>,
    fuzzies: &mut Vec<FuzzyTermInfo>, undefined: &mut Vec<String>,
) {
    let loc = field.location.clone();
    match &mut field.value {
        FieldValue::Single(term) => {
            check_term(term, manifest, declared_fuzzies, status, section_name,
                       diags, resolved, fuzzies, undefined, &loc);
        }
        FieldValue::List(terms) => {
            for term in terms {
                check_term(term, manifest, declared_fuzzies, status, section_name,
                           diags, resolved, fuzzies, undefined, &loc);
            }
        }
        _ => {}
    }
}

fn check_term_in_bullet(
    bullet: &mut Bullet, manifest: &ManifestIndex,
    declared_fuzzies: &HashSet<String>, status: &DocumentStatus,
    section_name: &str,
    diags: &mut Vec<Diagnostic>, resolved: &mut Vec<ResolvedTermInfo>,
    fuzzies: &mut Vec<FuzzyTermInfo>, undefined: &mut Vec<String>,
) {
    let loc = bullet.location.clone();
    check_term(&mut bullet.term, manifest, declared_fuzzies, status, section_name,
               diags, resolved, fuzzies, undefined, &loc);
    for sub in &mut bullet.sub_bullets {
        check_term_in_bullet(sub, manifest, declared_fuzzies, status, section_name,
                             diags, resolved, fuzzies, undefined);
    }
}

fn check_terms_in_prose(
    prose: &str, manifest: &ManifestIndex,
    declared_fuzzies: &HashSet<String>, status: &DocumentStatus,
    section_name: &str,
    diags: &mut Vec<Diagnostic>, resolved: &mut Vec<ResolvedTermInfo>,
    fuzzies: &mut Vec<FuzzyTermInfo>, undefined: &mut Vec<String>,
) {
    // Scan for *term* and ~~term~~ patterns in prose text.
    // This is a simplified scan; full prose term extraction is a v0.2 feature.
    let resolved_re = regex_find_italics(prose);
    for name in resolved_re {
        let mut term = Term::Resolved { name: name.clone(), package: None, version: None };
        check_term(&mut term, manifest, declared_fuzzies, status, section_name,
                   diags, resolved, fuzzies, undefined, &Location::default());
    }
    let fuzzy_terms = regex_find_fuzzies(prose);
    for name in fuzzy_terms {
        fuzzies.push(FuzzyTermInfo {
            name, section: section_name.to_string(),
            review_trigger: None, declared: false,
        });
    }
}

/// Minimal *word* extractor from prose text.
fn regex_find_italics(text: &str) -> Vec<String> {
    let mut result = Vec::new();
    let mut chars = text.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '*' {
            let word: String = chars.by_ref().take_while(|&x| x != '*').collect();
            if !word.is_empty() { result.push(word); }
        }
    }
    result
}

/// Minimal ~~word~~ extractor from prose text.
fn regex_find_fuzzies(text: &str) -> Vec<String> {
    let mut result = Vec::new();
    let bytes = text.as_bytes();
    let mut i = 0;
    while i + 1 < bytes.len() {
        if bytes[i] == b'~' && bytes[i + 1] == b'~' {
            i += 2;
            let start = i;
            while i + 1 < bytes.len() && !(bytes[i] == b'~' && bytes[i + 1] == b'~') {
                i += 1;
            }
            let word = &text[start..i];
            if !word.is_empty() { result.push(word.to_string()); }
            i += 2;
        } else {
            i += 1;
        }
    }
    result
}