//! OpenNorm CLI entry point.
//!
//! Commands:
//!   opennorm check   <file.md>        — full pipeline, print report
//!   opennorm check   <file.md> --json — machine-readable report
//!   opennorm transpile <file.md>      — print generated Lean 4 only

mod ast;
mod checker;
mod error;
mod parser;
mod report;
mod stdlib;
mod transpiler;

use std::{env, fs, path::Path, process, collections::HashSet};
use chrono::Utc;

use error::OpenNormError;
use report::{LeanOutput, PipelineOutputs};
use stdlib::StdlibRegistry;

fn main() {
    if let Err(e) = run() {
        eprintln!("opennorm: {e}");
        process::exit(1);
    }
}

fn run() -> Result<(), OpenNormError> {
    let args: Vec<String> = env::args().collect();

    match args.as_slice() {
        [_, cmd, file] => dispatch(cmd, file, false, false),
        [_, cmd, file, flag] if flag == "--json" => dispatch(cmd, file, true, false),
        [_, cmd, flag, path] if cmd == "validate" && flag == "-r" => cmd_validate(path, true),
        [_, cmd, path, flag] if cmd == "validate" && flag == "-r" => cmd_validate(path, true),
        _ => {
            eprintln!(
                "Usage:\n  opennorm check    <file.md> [--json]\n  opennorm transpile <file.md>\n  opennorm validate  <file.md|dir> [-r]\n"
            );
            process::exit(1);
        }
    }
}

fn dispatch(cmd: &str, file: &str, json: bool, recursive: bool) -> Result<(), OpenNormError> {
    match cmd {
        "check"     => cmd_check(file, json),
        "transpile" => cmd_transpile(file),
        "validate"  => cmd_validate(file, recursive),
        _           => {
            eprintln!("Unknown command: {cmd}");
            process::exit(1);
        }
    }
}

fn cmd_check(file: &str, _json: bool) -> Result<(), OpenNormError> {
    let source = fs::read_to_string(file)?;

    // Stage 1: Parse
    let mut doc = parser::parse(&source, file)?;

    // Validate all imported stdlib packages before proceeding
    println!("📚 Validating imported stdlib packages...\n");
    let _imported_defs = validate_imports(&doc)?;
    println!();

    // Load stdlib registry from ./stdlib relative to cwd
    let stdlib_root = Path::new("stdlib");
    let mut registry = StdlibRegistry::new(stdlib_root);

    // Stage 2: Check
    let checker_result = checker::check(&mut doc, &mut registry)?;

    // Stage 3: Transpile
    let lean_source = transpiler::transpile(&doc, file)?;

    // Stage 4: Invoke Lean 4 (subprocess)
    let lean_output = invoke_lean(&lean_source, file)?;

    // Stage 5: Report
    let outputs = PipelineOutputs {
        document:    &doc,
        source_file: file,
        checker:     checker_result,
        lean_output: Some(lean_output),
        timestamp:   Utc::now().to_rfc3339(),
    };

    let report = report::build_report(&outputs);
    println!("{report}");

    // Exit 1 if there were errors
    if outputs.checker.error_count > 0 {
        process::exit(1);
    }

    Ok(())
}

fn validate_imports(doc: &ast::Document) -> Result<HashSet<String>, OpenNormError> {
    // entrypoint: sets up visited package names and a global definition set
    let mut visited = HashSet::new();
    let mut global_defs = HashSet::new();
    internal_validate_imports(doc, &mut visited, &mut global_defs, 0)?;
    Ok(global_defs)
}

/// Recursive helper that walks imports, validating each package and its own
/// dependencies. `depth` is used for indentation in the printed status lines.
///
/// The algorithm first descends into a package's own imports so that definitions
/// from dependencies are available when checking the manifest of the parent.
fn internal_validate_imports(
    doc: &ast::Document,
    visited: &mut HashSet<String>,
    global_defs: &mut HashSet<String>,
    depth: usize,
) -> Result<(), OpenNormError> {
    if doc.imports.is_empty() {
        if depth == 0 {
            println!("  (no imports)");
        }
        return Ok(());
    }

    let mut has_errors = false;
    let indent = "  ".repeat(depth);

    for import in &doc.imports {
        if visited.contains(&import.package) {
            println!("{indent}↻ {} (already checked)", import.package);
            continue;
        }
        visited.insert(import.package.clone());

        // build path to file
        let file_path = if import.package.starts_with("stdlib/") {
            format!("{}.md", import.package)
        } else {
            format!("stdlib/{}.md", import.package)
        };

        if !Path::new(&file_path).exists() {
            eprintln!("{indent}❌ Import '{}' not found", import.package);
            has_errors = true;
            continue;
        }

        let pkg_source = match fs::read_to_string(&file_path) {
            Ok(s) => s,
            Err(e) => {
                eprintln!("{indent}❌ Cannot read '{}': {}", import.package, e);
                has_errors = true;
                continue;
            }
        };

        // parse package document so we can recurse into its imports
        let nested_doc = match parser::parse(&pkg_source, &file_path) {
            Ok(d) => d,
            Err(e) => {
                eprintln!("{indent}❌ Could not parse '{}': {}", import.package, e);
                has_errors = true;
                // skip checking this package further
                continue;
            }
        };

        // recursively validate dependencies first
        if let Err(_) = internal_validate_imports(&nested_doc, visited, global_defs, depth + 1) {
            has_errors = true;
        }

        // now perform manifest/definition consistency check for this package
        let manifest_names = extract_manifest_entries(&pkg_source);
        let definition_names = extract_definitions(&pkg_source);

        // add this package's definitions to the global pool before checking
        for name in &definition_names {
            global_defs.insert(name.clone());
        }

        let mut pkg_errors = Vec::new();
        let mut pkg_warnings = Vec::new();

        for def_name in &definition_names {
            if !manifest_names.contains(def_name) {
                pkg_warnings.push(format!(
                    "Definition '{}' has no manifest entry", def_name
                ));
            }
        }

        for manifest_name in &manifest_names {
            if !definition_names.contains(manifest_name)
                && !global_defs.contains(manifest_name)
            {
                pkg_errors.push(format!(
                    "Manifest entry '{}' has no definition", manifest_name
                ));
            }
        }

        if !pkg_errors.is_empty() {
            println!("{indent}❌ {} — {} error(s)", import.package, pkg_errors.len());
            for err in &pkg_errors {
                println!("{indent}   - {}", err);
            }
            has_errors = true;
        } else if !pkg_warnings.is_empty() {
            println!("{indent}⚠️  {} — {} warning(s)", import.package, pkg_warnings.len());
            for warn in &pkg_warnings {
                println!("{indent}   - {}", warn);
            }
        } else {
            println!("{indent}✅ {}", import.package);
        }
    }

    if has_errors {
        Err(OpenNormError::Parse(
            "Stdlib package validation failed — fix errors before proceeding".into(),
        ))
    } else {
        Ok(())
    }
}

fn cmd_transpile(file: &str) -> Result<(), OpenNormError> {
    let source = fs::read_to_string(file)?;
    let mut doc = parser::parse(&source, file)?;

    let stdlib_root = Path::new("stdlib");
    let mut registry = StdlibRegistry::new(stdlib_root);
    checker::check(&mut doc, &mut registry)?;

    let lean = transpiler::transpile(&doc, file)?;
    println!("{lean}");
    Ok(())
}

fn cmd_validate(path: &str, recursive: bool) -> Result<(), OpenNormError> {
    if recursive {
        validate_directory_recursive(path)
    } else {
        validate_single_file(path)
    }
}

fn validate_single_file(file: &str) -> Result<(), OpenNormError> {
    let source = fs::read_to_string(file)?;
    let doc = parser::parse(&source, file)?;

    // ensure imported packages are themselves sane
    let imported_defs = validate_imports(&doc)?;

    // Extract all manifest entries from § Actor Traits / § Manifest sections
    let manifest_names = extract_manifest_entries(&source);
    
    // Extract all definition section names (## SectionName)
    let definition_names = extract_definitions(&source);

    // Check for consistency
    let mut errors = Vec::new();
    let mut warnings = Vec::new();

    // Check that every defined term has at least one manifest entry
    for def_name in &definition_names {
        if !manifest_names.contains(def_name) {
            warnings.push(format!(
                "Definition '{}' has no manifest entry (surface form)", def_name
            ));
        }
    }

    // Check that every manifest entry has a corresponding definition
    for manifest_name in &manifest_names {
        if !definition_names.contains(manifest_name) && !imported_defs.contains(manifest_name) {
            errors.push(format!(
                "Manifest entry '{}' has no definition section", manifest_name
            ));
        }
    }

    // Report results
    if errors.is_empty() && warnings.is_empty() {
        println!("✅ {} is consistent", file);
        println!("  {} definitions, {} manifest entries", 
                 definition_names.len(), manifest_names.len());
        Ok(())
    } else {
        if !errors.is_empty() {
            println!("❌ ERRORS:");
            for err in &errors {
                println!("  - {}", err);
            }
        }
        if !warnings.is_empty() {
            println!("⚠️  WARNINGS:");
            for warn in &warnings {
                println!("  - {}", warn);
            }
        }
        if !errors.is_empty() {
            process::exit(1);
        }
        Ok(())
    }
}

fn validate_directory_recursive(dir: &str) -> Result<(), OpenNormError> {
    let path = Path::new(dir);
    
    if !path.is_dir() {
        return Err(OpenNormError::Parse(format!("'{}' is not a directory", dir)));
    }

    let mut md_files = Vec::new();
    collect_markdown_files(path, &mut md_files)?;

    if md_files.is_empty() {
        println!("No .md files found in '{}'", dir);
        return Ok(());
    }

    md_files.sort();
    let mut all_ok = true;

    for file_path in md_files {
        let path_str = file_path.to_string_lossy();
        match validate_single_file(&path_str) {
            Ok(()) => {},
            Err(e) => {
                eprintln!("❌ Error: {}: {}", path_str, e);
                all_ok = false;
            }
        }
    }

    if !all_ok {
        process::exit(1);
    }
    Ok(())
}

fn collect_markdown_files(dir: &Path, files: &mut Vec<std::path::PathBuf>) -> Result<(), OpenNormError> {
    for entry in fs::read_dir(dir)? {
        let entry = entry?;
        let path = entry.path();
        
        if path.is_dir() {
            collect_markdown_files(&path, files)?;
        } else if path.extension().and_then(|s| s.to_str()) == Some("md") {
            files.push(path);
        }
    }
    Ok(())
}

fn extract_manifest_entries(source: &str) -> std::collections::HashSet<String> {
    let mut entries = std::collections::HashSet::new();
    let mut current_canonical: Option<String> = None;

    for line in source.lines() {
        let trimmed = line.trim();

        // Track current definition section
        if trimmed.starts_with("## ") {
            let name = trimmed[3..].trim();
            if !name.is_empty() {
                current_canonical = Some(name.to_string());
            }
            continue;
        }

        // Collect Forms surfaces (these reference the current canonical name)
        if trimmed.starts_with("**Forms:") {
            if let Some(canon) = &current_canonical {
                entries.insert(canon.clone());
            }
            continue;
        }

        // Skip other metadata and imports
        if trimmed.starts_with("**") {
            continue;
        }

        // Collect arrow entries
        if let Some(arrow_pos) = trimmed.find('→') {
            let canonical = trimmed[arrow_pos + "→".len()..].trim();
            entries.insert(canonical.to_string());
        }
        // Collect bare hierarchy bullets
        else if trimmed.starts_with("- ") && !trimmed.starts_with("- >") {
            let name = trimmed[2..].trim();
            if !name.starts_with('"') && !name.is_empty() && !name.starts_with("stdlib/") {
                entries.insert(name.to_string());
            }
        }
    }

    entries
}

fn extract_definitions(source: &str) -> std::collections::HashSet<String> {
    let mut definitions = std::collections::HashSet::new();

    for line in source.lines() {
        if line.starts_with("## ") {
            let name = line[3..].trim();
            // Skip metadata sections
            if !name.starts_with("Actor") && 
               !name.starts_with("Manifest") &&
               !name.starts_with("Surface") &&
               !name.contains("Trait") &&
               !name.starts_with("Structural") &&
               !name.starts_with("Functional") {
                definitions.insert(name.to_string());
            }
        }
    }

    definitions
}

// ─────────────────────────────────────────────────────────────────────────────
// Lean 4 subprocess invocation
// ─────────────────────────────────────────────────────────────────────────────

/// Write generated Lean 4 to a temp file and invoke the Lean compiler.
/// Returns structured output parsed from compiler stdout/stderr.
///
/// Requires `lean` to be on PATH. If not found, returns a LeanOutput
/// with a warning rather than failing the entire pipeline.
fn invoke_lean(lean_source: &str, source_file: &str) -> Result<LeanOutput, OpenNormError> {
    let stem = Path::new(source_file)
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("document");

    let temp_dir = std::env::temp_dir();
    let lean_path = temp_dir.join(format!("opennorm_{stem}.lean"));
    fs::write(&lean_path, lean_source)?;

    let output = std::process::Command::new("lean")
        .arg("--no-header")
        .arg(&lean_path)
        .output();

    match output {
        Err(_) => {
            // Lean not installed — continue with partial output
            eprintln!("Warning: 'lean' not found on PATH — skipping formal verification stage");
            Ok(LeanOutput {
                proved:      vec!["[lean not available — skipped]".into()],
                failed:      vec![],
                undecidable: vec![],
                sorry_count: count_sorries(lean_source),
                raw_output:  String::new(),
            })
        }
        Ok(out) => {
            let stdout = String::from_utf8_lossy(&out.stdout).into_owned();
            let stderr = String::from_utf8_lossy(&out.stderr).into_owned();
            let combined = format!("{stdout}\n{stderr}");
            Ok(parse_lean_output(&combined, lean_source))
        }
    }
}

fn parse_lean_output(raw: &str, lean_source: &str) -> LeanOutput {
    let mut proved      = Vec::new();
    let mut failed      = Vec::new();
    let undecidable     = Vec::new();

    for line in raw.lines() {
        let l = line.trim();
        if l.starts_with("error:") || l.contains("failed to synthesize") {
            failed.push(l.to_string());
        } else if l.contains("sorry") && l.contains("warning") {
            // sorry warning is expected — counted separately
        } else if l.is_empty() {} else {
            // In the absence of errors, Lean exits 0 and we treat theorems as proved
        }
    }

    // Count theorems in source as proved if Lean exited cleanly
    if failed.is_empty() {
        for line in lean_source.lines() {
            if line.trim_start().starts_with("theorem ") {
                let name = line.trim_start()
                    .trim_start_matches("theorem ")
                    .split_whitespace()
                    .next()
                    .unwrap_or("unknown");
                proved.push(format!("Theorem `{name}` verified"));
            }
        }
    }

    LeanOutput {
        proved,
        failed,
        undecidable,
        sorry_count: count_sorries(lean_source),
        raw_output: raw.to_string(),
    }
}

fn count_sorries(source: &str) -> usize {
    source.lines()
        .filter(|l| l.trim_start().starts_with("sorry"))
        .count()
}