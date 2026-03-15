//! AST type definitions for OpenNorm documents.
//!
//! The AST is produced by `parser.rs` from the pest parse tree.
//! It is the single representation passed through checker, transpiler, and report.

use serde::{Deserialize, Serialize};

// ─────────────────────────────────────────────────────────────────────────────
// Package Types
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum PackageType {
    Stdlib,
    Template,
    Document,
}

impl PackageType {
    pub fn from_str(s: &str) -> Option<Self> {
        match s.to_lowercase().trim() {
            "stdlib" | "framework" | "domain" => Some(PackageType::Stdlib),
            "template" => Some(PackageType::Template),
            "document" | "license" => Some(PackageType::Document),
            _ => None,
        }
    }
    
    pub fn as_str(&self) -> &str {
        match self {
            PackageType::Stdlib => "stdlib",
            PackageType::Template => "template",
            PackageType::Document => "document",
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Document Status
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum DocumentStatus {
    Draft,
    Review,
    Final,
}

impl DocumentStatus {
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().trim() {
            "review" => DocumentStatus::Review,
            "final" => DocumentStatus::Final,
            _ => DocumentStatus::Draft,
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Manifest Section
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ManifestSection {
    pub opennorm: String,
    pub package: String,
    pub package_type: PackageType,
    pub version: String,
    pub implicit_import: bool,
    pub status: DocumentStatus,
    pub imports: Vec<String>,
}

// ─────────────────────────────────────────────────────────────────────────────
// Taxonomy
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Taxonomy {
    pub name: String,
    pub items: Vec<TaxonomyItem>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TaxonomyItem {
    pub name: String,
    pub children: Vec<TaxonomyItem>,
    pub location: Location,
}

// ─────────────────────────────────────────────────────────────────────────────
// Definition
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Definition {
    pub name: String,
    pub free_forms: Vec<String>,
    pub meaning: String,
    pub location: Location,
}

// ─────────────────────────────────────────────────────────────────────────────
// Code Section (for Axioms and FormalDescription)
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodeSection {
    pub description: Vec<String>,
    pub code_blocks: Vec<CodeBlock>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodeBlock {
    pub language: String,
    pub content: String,
    pub location: Location,
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Kinds
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum SectionKind {
    // Stdlib package sections
    Manifest,
    Taxonomies,
    Definitions,
    Axioms,
    FormalDescription,
    // Legacy/Template/Document sections
    Grant,
    Obligations,
    Waivers,
    Prohibitions,
    Compatibility,
    Jurisdiction,
    KnownAmbiguities,
    StructuralNotes,
    // Unknown section
    Unknown(String),
}

impl SectionKind {
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().trim() {
            "manifest" => SectionKind::Manifest,
            "taxonomies" => SectionKind::Taxonomies,
            "definitions" => SectionKind::Definitions,
            "axioms" => SectionKind::Axioms,
            "formal description" | "formaldescription" | "lean4" => SectionKind::FormalDescription,
            // Legacy
            "grant" => SectionKind::Grant,
            "obligations" => SectionKind::Obligations,
            "waivers" => SectionKind::Waivers,
            "prohibitions" => SectionKind::Prohibitions,
            "compatibility" => SectionKind::Compatibility,
            "jurisdiction" => SectionKind::Jurisdiction,
            "known ambiguities" => SectionKind::KnownAmbiguities,
            "structural notes" => SectionKind::StructuralNotes,
            other => SectionKind::Unknown(other.to_string()),
        }
    }
    
    pub fn is_stdlib_section(&self) -> bool {
        matches!(
            self,
            SectionKind::Manifest
                | SectionKind::Taxonomies
                | SectionKind::Definitions
                | SectionKind::Axioms
                | SectionKind::FormalDescription
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Document Structure
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Document {
    pub manifest: ManifestSection,
    pub taxonomies: Vec<Taxonomy>,
    pub definitions: Vec<Definition>,
    pub axioms: Option<CodeSection>,
    pub formal_description: Option<CodeSection>,
    // Legacy sections for non-stdlib packages
    pub legacy_sections: Vec<LegacySection>,
}

// ─────────────────────────────────────────────────────────────────────────────
// Legacy Section (for backwards compatibility)
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LegacySection {
    pub kind: SectionKind,
    pub header_text: String,
    pub depth: usize,
    pub fields: Vec<Field>,
    pub bullets: Vec<Bullet>,
    pub prose: Vec<String>,
    pub annotations: Vec<String>,
    pub location: Location,
}

// ─────────────────────────────────────────────────────────────────────────────
// Field (legacy)
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Field {
    pub label: String,
    pub value: FieldValue,
    pub location: Location,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum FieldValue {
    Single(Term),
    List(Vec<Term>),
    Prose(String),
    Reference(Reference),
    Empty,
}

// ─────────────────────────────────────────────────────────────────────────────
// Term (legacy)
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum Term {
    Resolved {
        name: String,
        package: Option<String>,
        version: Option<String>,
    },
    Fuzzy {
        name: String,
        review_trigger: Option<String>,
        reason: Option<String>,
    },
    Undefined(String),
}

impl Term {
    pub fn name(&self) -> &str {
        match self {
            Term::Resolved { name, .. } => name,
            Term::Fuzzy { name, .. } => name,
            Term::Undefined(name) => name,
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reference (legacy)
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Reference {
    pub display_text: String,
    pub uri: String,
    pub kind: ReferenceKind,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ReferenceKind {
    OpenNorm,
    Legal,
    Anchor,
}

// ─────────────────────────────────────────────────────────────────────────────
// Bullet (legacy)
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Bullet {
    pub term: Term,
    pub priority: usize,
    pub sub_bullets: Vec<Bullet>,
    pub location: Location,
}

// ─────────────────────────────────────────────────────────────────────────────
// Source Location
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Location {
    pub line: usize,
    pub column: usize,
    pub source: Option<String>,
}