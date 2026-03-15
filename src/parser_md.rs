//! Markdown-based parser using markdown-rs
//!
//! This is a prototype showing how to use markdown-rs AST for parsing OpenNorm documents.

use crate::ast::*;
use crate::error::OpenNormError;
use markdown::{to_mdast, ParseOptions};
use markdown::mdast::{Node, Heading, List, ListItem, Paragraph, Text, Strong, Code, InlineCode};

pub fn parse_with_markdown(source: &str, _filename: &str) -> Result<Document, OpenNormError> {
    // Parse markdown to AST
    let ast = to_mdast(source, &ParseOptions::default())
        .map_err(|e| OpenNormError::Parse(format!("Markdown parse error: {}", e)))?;
    
    // Extract sections from AST
    let mut manifest = None;
    let mut taxonomies = Vec::new();
    let mut definitions = Vec::new();
    let mut axioms = None;
    let mut formal_description = None;
    let mut legacy_sections = Vec::new();
    
    if let Node::Root(root) = ast {
        let mut i = 0;
        while i < root.children.len() {
            if let Node::Heading(heading) = &root.children[i] {
                if heading.depth == 2 {
                    let section_name = extract_text(&heading.children);
                    let kind = SectionKind::from_str(&section_name);
                    
                    match kind {
                        SectionKind::Manifest => {
                            manifest = Some(parse_manifest_from_ast(&root.children, &mut i)?);
                        }
                        SectionKind::Taxonomies => {
                            taxonomies = parse_taxonomies_from_ast(&root.children, &mut i)?;
                        }
                        SectionKind::Definitions => {
                            definitions = parse_definitions_from_ast(&root.children, &mut i)?;
                        }
                        SectionKind::Axioms => {
                            axioms = Some(parse_code_section_from_ast(&root.children, &mut i)?);
                        }
                        SectionKind::FormalDescription => {
                            formal_description = Some(parse_code_section_from_ast(&root.children, &mut i)?);
                        }
                        _ => {
                            // Legacy section - skip for now
                            i += 1;
                        }
                    }
                } else {
                    i += 1;
                }
            } else {
                i += 1;
            }
        }
    }
    
    let manifest = manifest.ok_or_else(|| OpenNormError::Parse("Missing Manifest section".to_string()))?;
    
    Ok(Document {
        manifest,
        taxonomies,
        definitions,
        axioms,
        formal_description,
        legacy_sections,
    })
}

fn extract_text(nodes: &[Node]) -> String {
    let mut text = String::new();
    for node in nodes {
        match node {
            Node::Text(t) => text.push_str(&t.value),
            Node::Strong(s) => text.push_str(&extract_text(&s.children)),
            Node::Emphasis(e) => text.push_str(&extract_text(&e.children)),
            Node::InlineCode(c) => text.push_str(&c.value),
            _ => {}
        }
    }
    text
}

fn parse_manifest_from_ast(children: &[Node], pos: &mut usize) -> Result<ManifestSection, OpenNormError> {
    *pos += 1; // Skip the ## Manifest heading
    
    let mut opennorm = None;
    let mut package = None;
    let mut package_type = None;
    let mut version = None;
    let mut implicit_import = None;
    let mut status = None;
    
    // Look for paragraphs with strong (bold) fields
    while *pos < children.len() {
        match &children[*pos] {
            Node::Heading(h) if h.depth == 2 => break, // Next section
            Node::Paragraph(p) => {
                // Look for **Field:** value patterns
                for child in &p.children {
                    if let Node::Strong(s) = child {
                        let text = extract_text(&s.children);
                        if text.ends_with(':') {
                            let field_name = text.trim_end_matches(':');
                            // The value comes after the strong node
                            let value = extract_text(&p.children);
                            let value = value.trim_start_matches(&format!("{}:", field_name)).trim();
                            
                            match field_name.to_lowercase().as_str() {
                                "opennorm" => opennorm = Some(value.to_string()),
                                "package" => package = Some(value.to_string()),
                                "package-type" => package_type = PackageType::from_str(value),
                                "version" => version = Some(value.to_string()),
                                "implicit-import" => implicit_import = Some(value.to_lowercase() == "true"),
                                "status" => status = Some(DocumentStatus::from_str(value)),
                                _ => {}
                            }
                        }
                    }
                }
            }
            _ => {}
        }
        *pos += 1;
    }
    
    Ok(ManifestSection {
        opennorm: opennorm.ok_or_else(|| OpenNormError::Parse("Missing OpenNorm field".to_string()))?,
        package: package.ok_or_else(|| OpenNormError::Parse("Missing Package field".to_string()))?,
        package_type: package_type.ok_or_else(|| OpenNormError::Parse("Missing Package-type field".to_string()))?,
        version: version.ok_or_else(|| OpenNormError::Parse("Missing Version field".to_string()))?,
        implicit_import: implicit_import.ok_or_else(|| OpenNormError::Parse("Missing Implicit-import field".to_string()))?,
        status: status.unwrap_or(DocumentStatus::Draft),
        imports: Vec::new(), // TODO: Parse imports from markdown AST if needed
    })
}

fn parse_taxonomies_from_ast(children: &[Node], pos: &mut usize) -> Result<Vec<Taxonomy>, OpenNormError> {
    *pos += 1; // Skip the ## Taxonomies heading
    let mut taxonomies = Vec::new();
    
    while *pos < children.len() {
        match &children[*pos] {
            Node::Heading(h) if h.depth == 2 => break, // Next major section
            Node::Heading(h) if h.depth == 3 => {
                // ### Taxonomy Name
                let name = extract_text(&h.children);
                *pos += 1;
                
                // Next should be a list
                if *pos < children.len() {
                    if let Node::List(list) = &children[*pos] {
                        let items = parse_list_items(&list.children);
                        taxonomies.push(Taxonomy { name, items });
                        *pos += 1;
                    }
                }
            }
            _ => *pos += 1,
        }
    }
    
    Ok(taxonomies)
}

fn parse_list_items(items: &[Node]) -> Vec<TaxonomyItem> {
    let mut result = Vec::new();
    
    for item in items {
        if let Node::ListItem(li) = item {
            let mut name = String::new();
            let mut children = Vec::new();
            
            for child in &li.children {
                match child {
                    Node::Paragraph(p) => {
                        name = extract_text(&p.children);
                    }
                    Node::List(sublist) => {
                        children = parse_list_items(&sublist.children);
                    }
                    _ => {}
                }
            }
            
            if !name.is_empty() {
                result.push(TaxonomyItem {
                    name,
                    children,
                    location: Location::default(),
                });
            }
        }
    }
    
    result
}

fn parse_definitions_from_ast(children: &[Node], pos: &mut usize) -> Result<Vec<Definition>, OpenNormError> {
    *pos += 1; // Skip the ## Definitions heading
    let mut definitions = Vec::new();
    
    while *pos < children.len() {
        match &children[*pos] {
            Node::Heading(h) if h.depth == 2 => break, // Next major section
            Node::Heading(h) if h.depth == 3 => {
                // ### Definition Name
                let name = extract_text(&h.children);
                *pos += 1;
                
                let mut free_forms = Vec::new();
                let mut meaning = String::new();
                
                // Parse following paragraphs for Free form and Meaning
                while *pos < children.len() {
                    match &children[*pos] {
                        Node::Heading(_) => break,
                        Node::Paragraph(p) => {
                            let text = extract_text(&p.children);
                            if text.starts_with("Free form:") {
                                let value = text.trim_start_matches("Free form:").trim();
                                free_forms = value.split(',').map(|s| s.trim().to_string()).collect();
                            } else if text.starts_with("Meaning:") {
                                meaning = text.trim_start_matches("Meaning:").trim().to_string();
                            }
                            *pos += 1;
                        }
                        _ => *pos += 1,
                    }
                }
                
                definitions.push(Definition {
                    name,
                    free_forms,
                    meaning,
                    location: Location::default(),
                });
                continue;
            }
            _ => *pos += 1,
        }
    }
    
    Ok(definitions)
}

fn parse_code_section_from_ast(children: &[Node], pos: &mut usize) -> Result<CodeSection, OpenNormError> {
    *pos += 1; // Skip section heading
    let mut description = Vec::new();
    let mut code_blocks = Vec::new();
    
    while *pos < children.len() {
        match &children[*pos] {
            Node::Heading(h) if h.depth == 2 => break,
            Node::Paragraph(p) => {
                description.push(extract_text(&p.children));
                *pos += 1;
            }
            Node::Code(code) => {
                code_blocks.push(CodeBlock {
                    language: code.lang.clone().unwrap_or_default(),
                    content: code.value.clone(),
                    location: Location::default(),
                });
                *pos += 1;
            }
            _ => *pos += 1,
        }
    }
    
    Ok(CodeSection {
        description,
        code_blocks,
    })
}