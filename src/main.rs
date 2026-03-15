//! OpenNorm CLI entry point - Simplified for stdlib packages

mod ast;
mod checker;
mod error;
mod parser;
mod parser_md;  // Markdown-rs based parser (prototype)
mod report;
mod stdlib;
mod transpiler;

use std::{env, fs, process};
use chrono::Utc;

use error::OpenNormError;
use report::{LeanOutput, PipelineOutputs};

fn main() {
    if let Err(e) = run() {
        eprintln!("opennorm: {e}");
        process::exit(1);
    }
}

fn run() -> Result<(), OpenNormError> {
    let args: Vec<String> = env::args().collect();

    match args.as_slice() {
        [_, cmd, file] if cmd == "check" || cmd == "transpile" => {
            cmd_check_or_transpile(cmd, file)
        }
        _ => {
            eprintln!("Usage:\n  opennorm check <file.md>\n  opennorm transpile <file.md>");
            process::exit(1);
        }
    }
}

fn cmd_check_or_transpile(cmd: &str, file: &str) -> Result<(), OpenNormError> {
    let source = fs::read_to_string(file)?;

    // Stage 1: Parse
    let doc = parser::parse(&source, file)?;

    // Stage 2: Check
    let checker_result = checker::check(&doc)?;

    // Stage 3: Transpile
    let lean_source = transpiler::transpile(&doc, file)?;

    if cmd == "transpile" {
        // Just output Lean code
        println!("{}", lean_source);
        return Ok(());
    }

    // Stage 4: Invoke Lean 4
    let lean_output = invoke_lean(&lean_source, file)?;

    // Stage 5: Report
    let outputs = PipelineOutputs {
        document:    &doc,
        source_file: file,
        checker:     checker_result,
        lean_output: Some(lean_output),
        lean_source: lean_source.clone(),
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

fn invoke_lean(lean_source: &str, _source_file: &str) -> Result<LeanOutput, OpenNormError> {
    // For now, just count sorry statements
    let sorry_count = lean_source.lines()
        .filter(|line| line.trim().starts_with("sorry"))
        .count();

    Ok(LeanOutput {
        proved:      vec![],
        failed:      vec![],
        undecidable: vec![],
        sorry_count,
        raw_output:  String::new(),
    })
}