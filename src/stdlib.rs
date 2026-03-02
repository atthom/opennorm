//! Stdlib registry and manifest index.
//!
//! The stdlib is a directory of OpenNorm documents following the package format.
//! Each package has a § Manifest section listing surface forms → canonical term ids.
//! The registry loads packages from disk. The ManifestIndex aggregates all
//! loaded package manifests for O(1) term lookup.

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use crate::error::OpenNormError;

// ─────────────────────────────────────────────────────────────────────────────
// Manifest entry
// ─────────────────────────────────────────────────────────────────────────────

/// One entry in a package's term manifest.
#[derive(Debug, Clone)]
pub struct ManifestEntry {
    /// The surface form as it appears in documents (e.g. "make available").
    pub surface:     String,
    /// The canonical term id within the package (e.g. "distribute").
    pub canonical:   String,
    /// The package id (e.g. "stdlib/actions/software").
    pub package:     String,
    pub version:     String,
}

// ─────────────────────────────────────────────────────────────────────────────
// ManifestIndex — aggregated lookup table
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Default)]
pub struct ManifestIndex {
    /// surface_form (lowercased) → entry
    index: HashMap<String, ManifestEntry>,
}

impl ManifestIndex {
    pub fn new() -> Self { Self::default() }

    pub fn merge(&mut self, entries: &[ManifestEntry]) {
        for entry in entries {
            self.index.insert(entry.surface.to_lowercase(), entry.clone());
        }
    }

    /// Look up a term by name. Returns the first matching entry.
    pub fn lookup(&self, name: &str) -> Option<&ManifestEntry> {
        self.index.get(&name.to_lowercase())
    }

    pub fn len(&self) -> usize { self.index.len() }
}

// ─────────────────────────────────────────────────────────────────────────────
// StdlibPackage — one loaded package
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug)]
pub struct StdlibPackage {
    pub id:       String,
    pub version:  String,
    pub manifest: Vec<ManifestEntry>,
}

// ─────────────────────────────────────────────────────────────────────────────
// StdlibRegistry — loads packages from the stdlib directory
// ─────────────────────────────────────────────────────────────────────────────

pub struct StdlibRegistry {
    /// Root of the stdlib directory (e.g. ./stdlib).
    root: PathBuf,
    /// Cache of loaded packages.
    cache: HashMap<String, StdlibPackage>,
}

impl StdlibRegistry {
    pub fn new(root: impl AsRef<Path>) -> Self {
        Self {
            root: root.as_ref().to_path_buf(),
            cache: HashMap::new(),
        }
    }

    /// Load a package by id (e.g. "stdlib/actions/software") and optional version.
    ///
    /// The registry resolves the id to a file path within the stdlib root:
    ///   stdlib/actions/software → {root}/actions/software.md
    ///
    /// The § Manifest section is parsed to extract surface form → term mappings.
    pub fn load(
        &mut self,
        package_id: &str,
        version: Option<&str>,
    ) -> Result<&StdlibPackage, OpenNormError> {
        // Normalise id: strip leading "stdlib/" prefix if present
        let id = package_id
            .strip_prefix("stdlib/")
            .unwrap_or(package_id);

        let cache_key = format!("{id}@{}", version.unwrap_or("latest"));
        if self.cache.contains_key(&cache_key) {
            return Ok(&self.cache[&cache_key]);
        }

        // Resolve to file path
        let path = self.root.join(format!("{id}.md"));
        if !path.exists() {
            return Err(OpenNormError::StdlibLoad {
                package: package_id.to_string(),
                message: format!("File not found: {}", path.display()),
            });
        }

        let content = std::fs::read_to_string(&path)?;
        let manifest = parse_manifest_section(&content, id, version.unwrap_or("1.0"));

        let pkg = StdlibPackage {
            id:      id.to_string(),
            version: version.unwrap_or("1.0").to_string(),
            manifest,
        };

        self.cache.insert(cache_key.clone(), pkg);
        Ok(&self.cache[&cache_key])
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// § Manifest section parser
// ─────────────────────────────────────────────────────────────────────────────

/// Extract term entries from the § Manifest section of a stdlib package file.
///
/// Format of each bullet in the manifest section:
///   - "surface form"  → canonical_id
///
/// Leading/trailing quotes on the surface form are stripped.
fn parse_manifest_section(content: &str, package: &str, version: &str) -> Vec<ManifestEntry> {
    let mut entries   = Vec::new();
    let mut in_manifest = false;

    for line in content.lines() {
        let trimmed = line.trim();

        // Detect section header
        if trimmed.starts_with("## ") {
            in_manifest = trimmed[3..].trim().to_lowercase() == "manifest";
            continue;
        }
        if trimmed.starts_with("# ") {
            in_manifest = false;
            continue;
        }

        if !in_manifest { continue; }

        // Parse bullet: `- "surface form"  → canonical`
        // or:           `- surface_form    → canonical`
        if let Some(rest) = trimmed.strip_prefix("- ") {
            if let Some(arrow_pos) = rest.find("→") {
                let surface_raw = rest[..arrow_pos].trim().trim_matches('"');
                let canonical   = rest[arrow_pos + "→".len()..].trim().to_string();
                entries.push(ManifestEntry {
                    surface:   surface_raw.to_string(),
                    canonical,
                    package:   package.to_string(),
                    version:   version.to_string(),
                });
            }
        }
    }

    entries
}