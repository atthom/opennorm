//! AST type definitions for OpenNorm documents.
//!
//! The AST is produced by `parser.rs` from the pest parse tree.
//! It is the single representation passed through checker, transpiler, and report.

use serde::{Deserialize, Serialize};

// ─────────────────────────────────────────────────────────────────────────────
// Term — the three states
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum Term {
    /// *term* — resolved against an imported package.
    Resolved {
        name:    String,
        package: Option<String>,   // filled by checker after manifest lookup
        version: Option<String>,
    },
    /// ~~term~~ — intentionally flexible, must be declared in § Known Ambiguities.
    Fuzzy {
        name:           String,
        review_trigger: Option<String>,   // filled by checker from Known Ambiguities
        reason:         Option<String>,
    },
    /// plain word — undefined. Hard error in Review/Final; warning in Draft.
    Undefined(String),
}

impl Term {
    pub fn name(&self) -> &str {
        match self {
            Term::Resolved { name, .. } => name,
            Term::Fuzzy    { name, .. } => name,
            Term::Undefined(name)       => name,
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Field {
    pub label:    String,
    pub value:    FieldValue,
    pub location: Location,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum FieldValue {
    Single(Term),
    List(Vec<Term>),
    Prose(String),         // raw prose — terms extracted during check phase
    Reference(Reference),
    Empty,                 // field label only, value follows as bullet list
}

// ─────────────────────────────────────────────────────────────────────────────
// Reference
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Reference {
    pub display_text: String,
    pub uri:          String,
    pub kind:         ReferenceKind,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ReferenceKind {
    /// `opennorm://package@version` — formally checked, rights merged
    OpenNorm,
    /// `legal://jurisdiction/code` — asserted only, checker warns on conflict
    Legal,
    /// `#section-anchor` — local, hard error if target missing
    Anchor,
}

// ─────────────────────────────────────────────────────────────────────────────
// Bullet — defeasible list
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Bullet {
    pub term:        Term,
    /// Priority derived from indentation depth (0 = top-level, 1 = first indent, ...).
    pub priority:    usize,
    pub sub_bullets: Vec<Bullet>,
    pub location:    Location,
}

// ─────────────────────────────────────────────────────────────────────────────
// Section
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Section {
    pub kind:        SectionKind,
    pub header_text: String,
    pub depth:       usize,        // heading level 1–6
    pub fields:      Vec<Field>,
    pub bullets:     Vec<Bullet>,
    pub prose:       Vec<String>,  // prose blocks — terms extracted in check phase
    pub annotations: Vec<String>,  // blockquotes — non-normative
    pub location:    Location,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum SectionKind {
    // Required in license template
    Grant,
    Obligations,
    Waivers,
    // Optional
    Prohibitions,
    Definitions,
    Compatibility,
    Jurisdiction,
    KnownAmbiguities,
    StructuralNotes,
    // Stdlib-specific
    Manifest,
    // Unknown section — checker warns if template requires specific sections
    Unknown(String),
}

impl SectionKind {
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().trim() {
            "grant"               => SectionKind::Grant,
            "obligations"         => SectionKind::Obligations,
            "waivers"             => SectionKind::Waivers,
            "prohibitions"        => SectionKind::Prohibitions,
            "definitions"         => SectionKind::Definitions,
            "compatibility"       => SectionKind::Compatibility,
            "jurisdiction"        => SectionKind::Jurisdiction,
            "known ambiguities"   => SectionKind::KnownAmbiguities,
            "structural notes"    => SectionKind::StructuralNotes,
            "manifest"            => SectionKind::Manifest,
            other                 => SectionKind::Unknown(other.to_string()),
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Import
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Import {
    pub package: String,
    pub version: Option<String>,   // None = unpinned → error at finalization
}

// ─────────────────────────────────────────────────────────────────────────────
// Document metadata and root node
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
            "final"  => DocumentStatus::Final,
            _        => DocumentStatus::Draft,
        }
    }
}

/// A fuzzy term declared in § Known Ambiguities.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KnownFuzzyTerm {
    pub name:           String,
    pub reason:         String,
    pub review_trigger: String,
    pub note:           Option<String>,
}

/// The root AST node — one per parsed document.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Document {
    pub id:              String,
    pub version:         String,
    pub opennorm:        String,
    pub template:        Option<String>,
    pub status:          DocumentStatus,
    pub imports:         Vec<Import>,
    pub sections:        Vec<Section>,
    pub known_fuzzies:   Vec<KnownFuzzyTerm>,  // extracted from KnownAmbiguities section
}

// ─────────────────────────────────────────────────────────────────────────────
// Source location
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Location {
    pub line:   usize,
    pub column: usize,
    pub source: Option<String>,   // filename
}