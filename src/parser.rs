//! Stage 1: Parser — Markdown → AST
//!
//! Uses a lightweight markdown parser to extract OpenNorm document structure.
//! Converts markdown lines into AST types.

use crate::ast::*;
use crate::error::OpenNormError;

/// Parse a markdown source string into an AST Document.
pub fn parse(source: &str, _filename: &str) -> Result<Document, OpenNormError> {
    let mut doc = Document {
        id:              String::new(),
        version:         String::new(),
        opennorm:        "0.1".to_string(),
        template:        None,
        status:          DocumentStatus::Draft,
        imports:         Vec::new(),
        sections:        Vec::new(),
        known_fuzzies:   Vec::new(),
    };

    let mut line_num = 1;
    let lines: Vec<&str> = source.lines().collect();
    let mut pos = 0;

    // skip leading heading/title and any blank lines before metadata
    while pos < lines.len() {
        let t = lines[pos].trim();
        if t.starts_with("# ") || t.is_empty() {
            pos += 1;
            line_num += 1;
        } else {
            break;
        }
    }

    // Parse metadata block (fields at the start)
    let mut in_imports_section = false;
    while pos < lines.len() {
        let line = lines[pos].trim();
        if line.starts_with("**") && line.contains(":**") {
            if line.starts_with("**Imports:**") {
                in_imports_section = true;
                pos += 1;
                line_num += 1;
                // Next lines should be import bullets
                while pos < lines.len() && in_imports_section {
                    let import_line = lines[pos].trim();
                    if import_line.starts_with("- ") {
                        let import_spec = import_line[2..].trim();
                        if let Some((package, version)) = parse_import_spec(import_spec) {
                            doc.imports.push(Import { package, version });
                        }
                        pos += 1;
                        line_num += 1;
                    } else if import_line.is_empty() || import_line.starts_with(">") {
                        pos += 1;
                        line_num += 1;
                    } else if import_line.starts_with("#") {
                        in_imports_section = false;
                        break;
                    } else {
                        // Non-bullet line marks end of imports
                        in_imports_section = false;
                        break;
                    }
                }
            } else {
                if let Some((label, value)) = parse_metadata_field(line) {
                    update_metadata(&mut doc, label, value);
                }
                pos += 1;
                line_num += 1;
            }
        } else if line.is_empty() || line.starts_with(">") {
            pos += 1;
            line_num += 1;
        } else if line.starts_with("---") {
            // Separator line - skip it
            pos += 1;
            line_num += 1;
        } else if line.starts_with("#") {
            break;  // End of metadata, start of sections
        } else {
            break;
        }
    }

    // Parse sections
    while pos < lines.len() {
        if let Some((section, consumed)) = parse_section(&lines, pos, &mut line_num) {
            // Extract known ambiguities if present
            if section.kind == SectionKind::KnownAmbiguities {
                doc.known_fuzzies = extract_known_fuzzies(&section);
            }
            doc.sections.push(section);
            pos += consumed;
        } else {
            pos += 1;
            line_num += 1;
        }
    }

    Ok(doc)
}

fn parse_import_spec(spec: &str) -> Option<(String, Option<String>)> {
    // split on '@' to separate package path from optional version
    let mut parts = spec.splitn(2, '@');
    let package = parts.next()?.trim().to_string();
    let version = parts.next().map(|s| s.trim().to_string());
    Some((package, version))
}

fn parse_metadata_field(line: &str) -> Option<(String, String)> {
    if let Some(label_end) = line.find(":**") {
        let label = line.get(2..label_end)?.trim().to_string();
        let value = line.get(label_end + 3..)?.trim().to_string();
        Some((label, value))
    } else {
        None
    }
}

fn update_metadata(doc: &mut Document, label: String, value: String) {
    match label.to_lowercase().as_str() {
        "id" => doc.id = value,
        "version" => doc.version = value,
        "opennorm" => doc.opennorm = value,
        "template" => doc.template = Some(value),
        "status" => doc.status = DocumentStatus::from_str(&value),
        "imports" => {
            // Parse individual imports from the value
            if value.contains('@') {
                let parts: Vec<&str> = value.split('@').collect();
                if parts.len() == 2 {
                    doc.imports.push(Import {
                        package: parts[0].trim().to_string(),
                        version: Some(parts[1].trim().to_string()),
                    });
                }
            } else if !value.is_empty() {
                doc.imports.push(Import {
                    package: value,
                    version: None,
                });
            }
        }
        _ => {}
    }
}

fn parse_section(
    lines: &[&str],
    start_pos: usize,
    line_num: &mut usize,
) -> Option<(Section, usize)> {
    if start_pos >= lines.len() {
        return None;
    }

    let line = lines[start_pos].trim();
    if !line.starts_with("#") {
        return None;
    }

    let depth = line.chars().take_while(|&c| c == '#').count();
    let header_text = line.get(depth..)
        .map(|s| s.trim())?
        .to_string();
    let kind = SectionKind::from_str(&header_text);

    let mut section = Section {
        kind,
        header_text,
        depth,
        fields: Vec::new(),
        bullets: Vec::new(),
        prose: Vec::new(),
        annotations: Vec::new(),
        location: Location {
            line: *line_num,
            column: 0,
            source: None,
        },
    };

    *line_num += 1;
    let mut pos = start_pos + 1;
    let mut prose_buffer = String::new();

    while pos < lines.len() {
        let current_line = lines[pos];
        let trimmed = current_line.trim();

        // Stop if we hit a new section (heading with 1-6 #'s)
        if trimmed.starts_with("#") && trimmed.chars().take_while(|c| *c == '#').count() <= 6 {
            if trimmed != "---" {
                break;
            }
        }

        if trimmed.starts_with("**") && trimmed.contains(":**") {
            // Flush prose buffer if needed
            if !prose_buffer.is_empty() {
                section.prose.push(prose_buffer.trim().to_string());
                prose_buffer.clear();
            }
            // Field
            if let Some(field) = parse_field_line(current_line) {
                section.fields.push(field);
            }
        } else if trimmed.starts_with("- ") && !trimmed.starts_with("- **") {
            // Bullet list (but not if it's a field)
            if !prose_buffer.is_empty() {
                section.prose.push(prose_buffer.trim().to_string());
                prose_buffer.clear();
            }
            if let Some(bullet) = parse_bullet_line(current_line) {
                section.bullets.push(bullet);
            }
        } else if trimmed.starts_with("> ") {
            // Annotation/blockquote
            if !prose_buffer.is_empty() {
                section.prose.push(prose_buffer.trim().to_string());
                prose_buffer.clear();
            }
            section.annotations.push(trimmed.get(2..).unwrap_or("").to_string());
        } else if trimmed == "---" || trimmed.is_empty() {
            if !prose_buffer.is_empty() {
                section.prose.push(prose_buffer.trim().to_string());
                prose_buffer.clear();
            }
        } else {
            // Prose
            prose_buffer.push_str(current_line);
            prose_buffer.push('\n');
        }

        pos += 1;
        *line_num += 1;
    }

    if !prose_buffer.is_empty() {
        section.prose.push(prose_buffer.trim().to_string());
    }

    Some((section, pos - start_pos))
}

fn parse_field_line(line: &str) -> Option<Field> {
    if let Some(colon_pos) = line.find(":**") {
        let label = line.get(2..colon_pos)?.trim().to_string();
        let value_str = line.get(colon_pos + 3..)?.trim();

        let value = parse_field_value(value_str);
        Some(Field {
            label,
            value,
            location: Location::default(),
        })
    } else {
        None
    }
}

fn parse_field_value(value_str: &str) -> FieldValue {
    if value_str.trim().is_empty() {
        FieldValue::Empty
    } else if is_single_term(value_str) {
        // Only a single resolved or fuzzy term, no other text
        if let Some(term) = parse_term_from_str(value_str) {
            FieldValue::Single(term)
        } else {
            FieldValue::Prose(value_str.to_string())
        }
    } else if value_str.contains('*') || value_str.contains("~~") {
        // Contains terms mixed with prose - treat as prose
        FieldValue::Prose(value_str.to_string())
    } else {
        FieldValue::Prose(value_str.to_string())
    }
}

/// Check if a value is a single term (possibly with whitespace) with no other text
fn is_single_term(value: &str) -> bool {
    let trimmed = value.trim();
    
    // Check for resolved term: *term*
    if trimmed.starts_with('*') && trimmed.ends_with('*') && trimmed.len() > 2 {
        let inner = &trimmed[1..trimmed.len() - 1];
        // Must not contain asterisks within the term
        return !inner.contains('*');
    }
    
    // Check for fuzzy term: ~~term~~
    if trimmed.starts_with("~~") && trimmed.ends_with("~~") && trimmed.len() > 4 {
        let inner = &trimmed[2..trimmed.len() - 2];
        // Must not contain tildes within the term
        return !inner.contains("~~");
    }
    
    false
}

fn parse_term_from_str(s: &str) -> Option<Term> {
    let trimmed = s.trim();

    if trimmed.starts_with('*') && trimmed.ends_with('*') && trimmed.len() > 2 {
        let name = trimmed.strip_prefix('*')?.strip_suffix('*')?.to_string();
        return Some(Term::Resolved {
            name,
            package: None,
            version: None,
        });
    }

    if trimmed.starts_with("~~") && trimmed.ends_with("~~") && trimmed.len() > 4 {
        let name = trimmed.strip_prefix("~~")?.strip_suffix("~~")?.to_string();
        return Some(Term::Fuzzy {
            name,
            review_trigger: None,
            reason: None,
        });
    }

    None
}

fn parse_bullet_line(line: &str) -> Option<Bullet> {
    let indent_count = line.len() - line.trim_start().len();
    let priority = indent_count / 2;

    let trimmed = line.trim();
    if trimmed.starts_with("- ") {
        let term_str = trimmed.get(2..)?.trim();
        let term = if is_single_term(term_str) {
            if let Some(t) = parse_term_from_str(term_str) {
                t
            } else {
                Term::Undefined(term_str.to_string())
            }
        } else {
            // Multiple terms or prose - treat as undefined/prose composite
            Term::Undefined(term_str.to_string())
        };
        return Some(Bullet {
            term,
            priority,
            sub_bullets: Vec::new(),
            location: Location::default(),
        });
    }
    None
}

fn extract_known_fuzzies(section: &Section) -> Vec<KnownFuzzyTerm> {
    let mut fuzzies = Vec::new();
    let all_content = section.prose.join("\n") + &section.annotations.join("\n");

    let lines: Vec<&str> = all_content.lines().collect();
    let mut i = 0;

    while i < lines.len() {
        let line = lines[i].trim();

        if line.starts_with("- **") || line.starts_with("**") {
            if let Some(term_name) = parse_bold_term(line) {
                let mut reason = String::new();
                let mut review_trigger = String::new();

                // Extract reason from the line (after — em dash)
                if let Some(dash_pos) = line.find('—') {
                    reason = line.get(dash_pos + 1..).unwrap_or("").trim().to_string();
                }

                // Look ahead for Review trigger
                if i + 1 < lines.len() {
                    let next_line = lines[i + 1].trim();
                    if next_line.starts_with("**Review trigger:**") {
                        if let Some(trigger_text) = next_line.strip_prefix("**Review trigger:**") {
                            review_trigger = trigger_text.trim().to_string();
                        }
                    }
                }

                fuzzies.push(KnownFuzzyTerm {
                    name: term_name,
                    reason: reason.trim().to_string(),
                    review_trigger,
                    note: None,
                });
            }
        }

        i += 1;
    }

    fuzzies
}

fn parse_bold_term(line: &str) -> Option<String> {
    if let Some(start) = line.find("**") {
        if let Some(end) = line.get(start + 2..)?.find("**") {
            let term = line.get(start + 2..start + 2 + end)?;
            let cleaned = term.trim_start_matches('-').trim().to_string();
            if !cleaned.is_empty() {
                return Some(cleaned);
            }
        }
    }
    None
}
