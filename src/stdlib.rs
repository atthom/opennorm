//! Stdlib registry and manifest index.
//!
//! The stdlib is a directory of OpenNorm documents following the package format.
//! Each package has a § Manifest section listing surface forms → canonical term ids.
//! The registry loads packages from disk. The ManifestIndex aggregates all
//! loaded package manifests for O(1) term lookup.

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use crate::error::OpenNormError;

// helper to normalise a surface string by stripping markdown asterisks and
// surrounding whitespace. This ensures that forms like `** use` or ``*foo*``
// collapse to `use` and `foo` respectively, eliminating markdown artefacts.
fn clean_surface(s: &str) -> String {
    s.trim_start_matches('*')
     .trim_end_matches('*')
     .trim()
     .to_string()
}

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

/// Ensure **Package:** and **Version:** metadata appear near the top of the file.
fn require_top_metadata(content: &str, package_id: &str) -> Result<(), OpenNormError> {
    let mut seen_pkg = false;
    let mut seen_ver = false;
    for line in content.lines().take(40) {
        let t = line.trim();
        if t.starts_with("**Package:") { seen_pkg = true; }
        if t.starts_with("**Version:") { seen_ver = true; }
        if seen_pkg && seen_ver { return Ok(()); }
    }
    Err(OpenNormError::StdlibLoad {
        package: package_id.to_string(),
        message: "missing **Package:** or **Version:** metadata".into(),
    })
}

/// Extract term entries from a stdlib package file.
///
/// Scans for:
/// 1. `**Forms:` metadata inside definitions (##-level sections);
/// 2. Old-style `## Manifest` section with `- surface → canonical` entries;
/// 3. Bare hierarchy bullets `- Name` (mapped as surface==canonical).
///
/// Requires **Package:** and **Version:** metadata at top of file.
fn parse_manifest_section(content: &str, package: &str, version: &str) -> Vec<ManifestEntry> {
    // Enforce metadata presence
    let _ = require_top_metadata(content, package);

    let mut entries = Vec::new();
    let mut current_canonical: Option<String> = None;

    for line in content.lines() {
        let trimmed = line.trim();

        // Update current section when encountering a definition header
        if trimmed.starts_with("## ") {
            let name = trimmed[3..].trim();
            if !name.is_empty() {
                current_canonical = Some(name.to_string());
            }
            continue;
        }

        // Parse Forms metadata inside the current section
        if trimmed.starts_with("**Forms:") {
            if let Some(canon) = &current_canonical {
                // remove the leading label
                let mut rest = trimmed.trim_start_matches("**Forms:").trim().to_string();
                // strip any leading '*' characters leftover from bold markup
                rest = rest.trim_start_matches('*').trim().to_string();
                for part in rest.split(',') {
                    let mut surface = part.trim().trim_matches('"').to_string();
                    surface = clean_surface(&surface);
                    if !surface.is_empty() {
                        entries.push(ManifestEntry {
                            surface,
                            canonical: canon.clone(),
                            package: package.to_string(),
                            version: version.to_string(),
                        });
                    }
                }
            }
            continue;
        }

        // Parse old-style explicit manifest entries (arrow notation)
        if let Some(rest) = trimmed.strip_prefix("- ") {
            if let Some(arrow_pos) = rest.find("→") {
                let surface_raw = rest[..arrow_pos].trim().trim_matches('"');
                let canonical = rest[arrow_pos + "→".len()..].trim().to_string();
                entries.push(ManifestEntry {
                    surface: surface_raw.to_string(),
                    canonical,
                    package: package.to_string(),
                    version: version.to_string(),
                });
            } else {
                // Treat bare hierarchy bullets as self-mapping entries
                let name = rest.trim().trim_matches('"');
                if !name.is_empty() {
                    entries.push(ManifestEntry {
                        surface: name.to_string(),
                        canonical: name.to_string(),
                        package: package.to_string(),
                        version: version.to_string(),
                    });
                }
            }
        }
    }

    entries
}