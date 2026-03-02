//! Unified error and diagnostic types for the OpenNorm pipeline.

use thiserror::Error;
use serde::{Deserialize, Serialize};
use crate::ast::Location;

// ── Pipeline errors ───────────────────────────────────────────────────────────

#[derive(Debug, Error)]
pub enum OpenNormError {
    #[error("Parse error: {0}")]
    Parse(String),

    #[error("Stdlib load error for package '{package}': {message}")]
    StdlibLoad { package: String, message: String },

    #[error("Transpilation error: {0}")]
    Transpile(String),

    #[error("Lean invocation error: {0}")]
    Lean(String),

    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Serialisation error: {0}")]
    Serde(#[from] serde_json::Error),
}

// ── Diagnostic severity ───────────────────────────────────────────────────────

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub enum Severity {
    Info,
    Warning,
    Error,
}

impl std::fmt::Display for Severity {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Severity::Info    => write!(f, "INFO"),
            Severity::Warning => write!(f, "WARN"),
            Severity::Error   => write!(f, "ERROR"),
        }
    }
}

// ── Diagnostic codes ──────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Diagnostic {
    pub severity:   Severity,
    /// Short code for CI / editor filtering. E-series = errors, W-series = warnings.
    pub code:       &'static str,
    pub message:    String,
    pub location:   Location,
    pub suggestion: Option<String>,
}

impl std::fmt::Display for Diagnostic {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "[{}] {} L{}:{} — {}",
            self.severity,
            self.code,
            self.location.line,
            self.location.column,
            self.message,
        )?;
        if let Some(s) = &self.suggestion {
            write!(f, "\n  suggestion: {s}")?;
        }
        Ok(())
    }
}