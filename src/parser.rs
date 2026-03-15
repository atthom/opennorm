//! Stage 1: Parser — Markdown → AST
//!
//! Parses OpenNorm markdown documents into the structured AST.
//! Enforces the new spec: Manifest (required), Taxonomies, Definitions, Axioms, FormalDescription.

use crate::ast::*;
use crate::error::OpenNormError;

/// Parse a markdown source string into an AST Document.
pub fn parse(source: &str, filename: &str) -> Result<Document, OpenNormError> {
    let lines: Vec<&str> = source.lines().collect();
    let mut pos = 0;
    let mut line_num = 1;

    // Skip title/heading
    while pos < lines.len() && (lines[pos].trim().starts_with('#') || lines[pos].trim().is_empty()) {
        pos += 1;
        line_num += 1;
    }

    // Parse Manifest section (required)
    let (manifest, consumed) = parse_manifest(&lines, pos, &mut line_num)?;
    pos += consumed;

    // Initialize document structure
    let mut doc = Document {
        manifest,
        taxonomies: Vec::new(),
        definitions: Vec::new(),
        axioms: None,
        formal_description: None,
        legacy_sections: Vec::new(),
    };

    // Parse remaining sections
    while pos < lines.len() {
        let line = lines[pos].trim();
        
        // Only process ## level sections, not ### subsections
        if line.starts_with("## ") && !line.starts_with("### ") {
            let section_name = line.trim_start_matches('#').trim();
            let kind = SectionKind::from_str(section_name);
            
            match kind {
                SectionKind::Taxonomies => {
                    let (taxonomies, consumed) = parse_taxonomies_section(&lines, pos, &mut line_num)?;
                    doc.taxonomies = taxonomies;
                    pos += consumed;
                }
                SectionKind::Definitions => {
                    let (definitions, consumed) = parse_definitions_section(&lines, pos, &mut line_num)?;
                    doc.definitions = definitions;
                    pos += consumed;
                }
                SectionKind::Axioms => {
                    let (axioms, consumed) = parse_code_section(&lines, pos, &mut line_num)?;
                    doc.axioms = Some(axioms);
                    pos += consumed;
                }
                SectionKind::FormalDescription => {
                    let (formal, consumed) = parse_code_section(&lines, pos, &mut line_num)?;
                    doc.formal_description = Some(formal);
                    pos += consumed;
                }
                _ => {
                    // Legacy or unknown section
                    let (section, consumed) = parse_legacy_section(&lines, pos, &mut line_num)?;
                    doc.legacy_sections.push(section);
                    pos += consumed;
                }
            }
        } else {
            pos += 1;
            line_num += 1;
        }
    }

    Ok(doc)
}

// ─────────────────────────────────────────────────────────────────────────────
// Parse Manifest Section
// ─────────────────────────────────────────────────────────────────────────────

fn parse_manifest(lines: &[&str], start: usize, line_num: &mut usize) -> Result<(ManifestSection, usize), OpenNormError> {
    let mut pos = start;
    let mut opennorm = None;
    let mut package = None;
    let mut package_type = None;
    let mut version = None;
    let mut implicit_import = None;
    let mut status = None;
    let mut imports = Vec::new();

    // Skip to manifest section or parse inline metadata
    while pos < lines.len() {
        let line = lines[pos].trim();
        
        if line.starts_with("## Manifest") {
            pos += 1;
            *line_num += 1;
            break;
        }
        
        // Check for inline metadata
        if line.starts_with("**") && line.contains(":**") {
            if let Some((label, value)) = parse_metadata_field(line) {
                match label.to_lowercase().as_str() {
                    "opennorm" => opennorm = Some(value),
                    "package" => package = Some(value),
                    "package-type" => package_type = PackageType::from_str(&value),
                    "version" => version = Some(value),
                    "implicit-import" => implicit_import = Some(parse_bool(&value)),
                    "status" => status = Some(DocumentStatus::from_str(&value)),
                    "imports" => {
                        // Parse imports list - skip to next line and parse list items
                        pos += 1;
                        *line_num += 1;
                        // Skip blank lines
                        while pos < lines.len() && lines[pos].trim().is_empty() {
                            pos += 1;
                            *line_num += 1;
                        }
                        // Parse list items
                        while pos < lines.len() {
                            let import_line = lines[pos].trim();
                            if import_line.starts_with("- ") {
                                imports.push(import_line.trim_start_matches('-').trim().to_string());
                                pos += 1;
                                *line_num += 1;
                            } else if import_line.starts_with("##") {
                                break;
                            } else if !import_line.is_empty() && !import_line.starts_with(">") {
                                break;
                            } else {
                                pos += 1;
                                *line_num += 1;
                            }
                        }
                        continue;
                    }
                    _ => {}
                }
            }
        }
        
        if line.starts_with("##") && !line.starts_with("## Manifest") {
            break;
        }
        
        pos += 1;
        *line_num += 1;
    }

    // Parse manifest fields
    while pos < lines.len() {
        let line = lines[pos].trim();
        
        if line.starts_with("##") && !line.contains("Manifest") {
            break;
        }
        
        if line.starts_with("**") && line.contains(":**") {
            if let Some((label, value)) = parse_metadata_field(line) {
                match label.to_lowercase().as_str() {
                    "opennorm" => opennorm = Some(value),
                    "package" => package = Some(value),
                    "package-type" => package_type = PackageType::from_str(&value),
                    "version" => version = Some(value),
                    "implicit-import" => implicit_import = Some(parse_bool(&value)),
                    "status" => status = Some(DocumentStatus::from_str(&value)),
                    "imports" => {
                        // Parse imports list - skip to next line and parse list items
                        pos += 1;
                        *line_num += 1;
                        // Skip blank lines
                        while pos < lines.len() && lines[pos].trim().is_empty() {
                            pos += 1;
                            *line_num += 1;
                        }
                        // Parse list items
                        while pos < lines.len() {
                            let import_line = lines[pos].trim();
                            if import_line.starts_with("- ") {
                                imports.push(import_line.trim_start_matches('-').trim().to_string());
                                pos += 1;
                                *line_num += 1;
                            } else if import_line.starts_with("##") {
                                break;
                            } else if !import_line.is_empty() && !import_line.starts_with(">") {
                                break;
                            } else {
                                pos += 1;
                                *line_num += 1;
                            }
                        }
                        continue;
                    }
                    _ => {}
                }
            }
        }
        
        pos += 1;
        *line_num += 1;
    }

    // Validate required fields
    let manifest = ManifestSection {
        opennorm: opennorm.ok_or_else(|| OpenNormError::Parse("Missing required field: OpenNorm".to_string()))?,
        package: package.ok_or_else(|| OpenNormError::Parse("Missing required field: Package".to_string()))?,
        package_type: package_type.ok_or_else(|| OpenNormError::Parse("Missing required field: Package-type".to_string()))?,
        version: version.ok_or_else(|| OpenNormError::Parse("Missing required field: Version".to_string()))?,
        implicit_import: implicit_import.unwrap_or(false), // Default to false if not specified
        status: status.unwrap_or(DocumentStatus::Draft),
        imports,
    };

    Ok((manifest, pos - start))
}

fn parse_metadata_field(line: &str) -> Option<(String, String)> {
    if let Some(colon_pos) = line.find(":**") {
        let label = line.get(2..colon_pos)?.trim().to_string();
        let value = line.get(colon_pos + 3..)?.trim().to_string();
        Some((label, value))
    } else {
        None
    }
}

fn parse_bool(s: &str) -> bool {
    matches!(s.to_lowercase().trim(), "true" | "yes" | "1")
}

// ─────────────────────────────────────────────────────────────────────────────
// Parse Taxonomies Section
// ─────────────────────────────────────────────────────────────────────────────

fn parse_taxonomies_section(lines: &[&str], start: usize, line_num: &mut usize) -> Result<(Vec<Taxonomy>, usize), OpenNormError> {
    let mut pos = start + 1; // Skip "## Taxonomies"
    *line_num += 1;
    let mut taxonomies = Vec::new();

    while pos < lines.len() {
        let line = lines[pos].trim();
        
        // Parse subsection (### Taxonomy Name)
        if line.starts_with("###") {
            let name = line.trim_start_matches('#').trim().to_string();
            pos += 1;
            *line_num += 1;
            
            let items = parse_taxonomy_items(&lines, &mut pos, line_num, 0)?;
            
            taxonomies.push(Taxonomy { name, items });
        }
        // Stop at next major section (but not ### subsections)
        else if line.starts_with("## ") && !line.starts_with("### ") {
            break;
        } else {
            pos += 1;
            *line_num += 1;
        }
    }

    Ok((taxonomies, pos - start))
}

fn parse_taxonomy_items(lines: &[&str], pos: &mut usize, line_num: &mut usize, base_indent: usize) -> Result<Vec<TaxonomyItem>, OpenNormError> {
    let mut items = Vec::new();

    while *pos < lines.len() {
        let line = lines[*pos];
        let trimmed = line.trim();
        
        // Stop at next section
        if trimmed.starts_with("##") {
            break;
        }
        
        // Parse bullet items
        if trimmed.starts_with("- ") {
            let indent = line.len() - line.trim_start().len();
            
            if indent < base_indent {
                break;
            }
            
            if indent == base_indent {
                let name = trimmed.trim_start_matches('-').trim().to_string();
                *pos += 1;
                *line_num += 1;
                
                // Parse children
                let children = parse_taxonomy_items(lines, pos, line_num, base_indent + 2)?;
                
                items.push(TaxonomyItem {
                    name,
                    children,
                    location: Location { line: *line_num, column: 0, source: None },
                });
            } else {
                // Child of previous item, will be handled by recursion
                break;
            }
        } else if trimmed.is_empty() || trimmed.starts_with(">") {
            *pos += 1;
            *line_num += 1;
        } else {
            break;
        }
    }

    Ok(items)
}

// ─────────────────────────────────────────────────────────────────────────────
// Parse Definitions Section
// ─────────────────────────────────────────────────────────────────────────────

fn parse_definitions_section(lines: &[&str], start: usize, line_num: &mut usize) -> Result<(Vec<Definition>, usize), OpenNormError> {
    let mut pos = start + 1; // Skip "## Definitions"
    *line_num += 1;
    let mut definitions = Vec::new();

    while pos < lines.len() {
        let line = lines[pos].trim();
        
        // Parse subsection (### Term Name)
        if line.starts_with("###") {
            let name = line.trim_start_matches('#').trim().to_string();
            let def_line = *line_num;
            pos += 1;
            *line_num += 1;
            
            let mut free_forms = Vec::new();
            let mut meaning = String::new();
            
            // Parse definition fields
            while pos < lines.len() {
                let def_line_text = lines[pos].trim();
                
                if def_line_text.starts_with("###") || def_line_text.starts_with("##") {
                    break;
                }
                
                if def_line_text.starts_with("**Free form:**") {
                    let value = def_line_text.strip_prefix("**Free form:**").unwrap_or("").trim();
                    free_forms = value.split(',').map(|s| s.trim().to_string()).filter(|s| !s.is_empty()).collect();
                } else if def_line_text.starts_with("**Meaning:**") {
                    let value = def_line_text.strip_prefix("**Meaning:**").unwrap_or("").trim();
                    meaning = value.to_string();
                    pos += 1;
                    *line_num += 1;
                    
                    // Collect following prose lines as part of meaning
                    while pos < lines.len() {
                        let next_line = lines[pos].trim();
                        if next_line.starts_with("###") || next_line.starts_with("##") || next_line.starts_with("**") {
                            break;
                        }
                        if !next_line.is_empty() && !next_line.starts_with(">") {
                            meaning.push(' ');
                            meaning.push_str(next_line);
                        }
                        pos += 1;
                        *line_num += 1;
                    }
                    continue;
                }
                
                pos += 1;
                *line_num += 1;
            }
            
            definitions.push(Definition {
                name,
                free_forms,
                meaning,
                location: Location { line: def_line, column: 0, source: None },
            });
            continue;
        }
        // Stop at next major section (but not ### subsections)
        else if line.starts_with("## ") && !line.starts_with("### ") {
            break;
        } else {
            pos += 1;
            *line_num += 1;
        }
    }

    Ok((definitions, pos - start))
}

// ─────────────────────────────────────────────────────────────────────────────
// Parse Code Section (Axioms or FormalDescription)
// ─────────────────────────────────────────────────────────────────────────────

fn parse_code_section(lines: &[&str], start: usize, line_num: &mut usize) -> Result<(CodeSection, usize), OpenNormError> {
    let mut pos = start + 1; // Skip section header
    *line_num += 1;
    let mut description = Vec::new();
    let mut code_blocks = Vec::new();
    let mut current_prose = String::new();

    while pos < lines.len() {
        let line = lines[pos];
        let trimmed = line.trim();
        
        // Stop at next major section
        if trimmed.starts_with("##") {
            break;
        }
        
        // Detect code block start
        if trimmed.starts_with("```") {
            // Save any accumulated prose
            if !current_prose.trim().is_empty() {
                description.push(current_prose.trim().to_string());
                current_prose.clear();
            }
            
            let language = trimmed.trim_start_matches('`').trim().to_string();
            let code_start_line = *line_num;
            pos += 1;
            *line_num += 1;
            
            let mut code_content = String::new();
            
            // Collect code until closing ```
            while pos < lines.len() {
                let code_line = lines[pos];
                if code_line.trim().starts_with("```") {
                    pos += 1;
                    *line_num += 1;
                    break;
                }
                code_content.push_str(code_line);
                code_content.push('\n');
                pos += 1;
                *line_num += 1;
            }
            
            code_blocks.push(CodeBlock {
                language,
                content: code_content,
                location: Location { line: code_start_line, column: 0, source: None },
            });
        } else if !trimmed.is_empty() && !trimmed.starts_with(">") {
            current_prose.push_str(line);
            current_prose.push('\n');
            pos += 1;
            *line_num += 1;
        } else {
            pos += 1;
            *line_num += 1;
        }
    }

    // Save final prose
    if !current_prose.trim().is_empty() {
        description.push(current_prose.trim().to_string());
    }

    Ok((CodeSection { description, code_blocks }, pos - start))
}

// ─────────────────────────────────────────────────────────────────────────────
// Parse Legacy Section (for backwards compatibility)
// ─────────────────────────────────────────────────────────────────────────────

fn parse_legacy_section(lines: &[&str], start: usize, line_num: &mut usize) -> Result<(LegacySection, usize), OpenNormError> {
    let line = lines[start].trim();
    let depth = line.chars().take_while(|&c| c == '#').count();
    let header_text = line.get(depth..).map(|s| s.trim()).unwrap_or("").to_string();
    let kind = SectionKind::from_str(&header_text);
    
    let mut section = LegacySection {
        kind,
        header_text,
        depth,
        fields: Vec::new(),
        bullets: Vec::new(),
        prose: Vec::new(),
        annotations: Vec::new(),
        location: Location { line: *line_num, column: 0, source: None },
    };
    
    let mut pos = start + 1;
    *line_num += 1;
    
    while pos < lines.len() {
        let line_text = lines[pos].trim();
        
        if line_text.starts_with("##") {
            break;
        }
        
        if line_text.starts_with("**") && line_text.contains(":**") {
            // Field
            if let Some((label, value)) = parse_metadata_field(line_text) {
                section.fields.push(Field {
                    label,
                    value: FieldValue::Prose(value),
                    location: Location { line: *line_num, column: 0, source: None },
                });
            }
        } else if line_text.starts_with("- ") {
            // Bullet
            let term_text = line_text.trim_start_matches('-').trim();
            section.bullets.push(Bullet {
                term: Term::Undefined(term_text.to_string()),
                priority: 0,
                sub_bullets: Vec::new(),
                location: Location { line: *line_num, column: 0, source: None },
            });
        } else if line_text.starts_with(">") {
            section.annotations.push(line_text.trim_start_matches('>').trim().to_string());
        } else if !line_text.is_empty() {
            section.prose.push(line_text.to_string());
        }
        
        pos += 1;
        *line_num += 1;
    }
    
    Ok((section, pos - start))
}