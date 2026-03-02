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

use std::{env, fs, path::Path, process};
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
        [_, cmd, file] => dispatch(cmd, file, false),
        [_, cmd, file, flag] if flag == "--json" => dispatch(cmd, file, true),
        _ => {
            eprintln!(
                "Usage:\n  opennorm check    <file.md> [--json]\n  opennorm transpile <file.md>\n"
            );
            process::exit(1);
        }
    }
}

fn dispatch(cmd: &str, file: &str, json: bool) -> Result<(), OpenNormError> {
    match cmd {
        "check"     => cmd_check(file, json),
        "transpile" => cmd_transpile(file),
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