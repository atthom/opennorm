# Unified Validation Module
# Integrates all validation checks (E050-E053, W020-W023) into a single interface

"""
    ValidationReport

Comprehensive validation report containing all validation results.
"""
struct ValidationReport
    # Exception validation (E050-E052)
    exception_structural_passed::Bool
    exception_structural_errors::Vector{String}
    exception_satisfiability_issues::Vector{Any}  # ValidationResult from smt_validation
    
    # Contradiction detection (E053)
    contradictions::Vector{Any}  # ValidationResult from smt_validation
    
    # Taxonomy validation (W020-W022)
    action_complementarity_issues::Vector{Any}  # TaxonomyValidationResult
    cross_action_issues::Vector{Any}  # TaxonomyValidationResult
    role_hierarchy_issues::Vector{Any}  # TaxonomyValidationResult
    
    # Exhaustiveness validation (W023)
    triple_coverage_gaps::Vector{Any}  # ExhaustivenessResult
    condition_exhaustiveness_issues::Vector{Any}  # ExhaustivenessResult
    
    # Summary
    total_errors::Int
    total_warnings::Int
    validation_timestamp::String
end

"""
    run_all_validations(ir::DocumentIR; max_exhaustiveness_gaps::Int=10) -> ValidationReport

Run all validation checks and return a comprehensive report.
"""
function run_all_validations(ir::DocumentIR; max_exhaustiveness_gaps::Int=10)
    println("Running comprehensive validation checks...")
    println("=" ^ 70)
    
    # Phase 1: Exception Validation (E050-E052)
    println("\n[1/5] Exception Validation (E050-E052)...")
    exception_structural_passed = true
    exception_structural_errors = String[]
    
    try
        validate_exceptions(ir.norms)
        check_circular_exceptions(ir.norms)
        println("  ✓ Structural validation passed")
    catch e
        exception_structural_passed = false
        push!(exception_structural_errors, string(e))
        println("  ✗ Structural validation failed: $(e)")
    end
    
    # E052: Satisfiability (SMT-based)
    exception_satisfiability_issues = validate_all_exceptions_smt(ir.norms, Context())
    if isempty(exception_satisfiability_issues)
        println("  ✓ Satisfiability checks passed")
    else
        println("  ⚠ Found $(length(exception_satisfiability_issues)) satisfiability issues")
    end
    
    # Phase 2: Contradiction Detection (E053)
    println("\n[2/5] Contradiction Detection (E053)...")
    contradictions = detect_all_contradictions(ir.norms, Context())
    if isempty(contradictions)
        println("  ✓ No contradictions detected")
    else
        println("  ⚠ Found $(length(contradictions)) contradictions")
    end
    
    # Phase 3: Taxonomy Validation (W020-W022)
    println("\n[3/5] Taxonomy Validation (W020-W022)...")
    (action_issues, cross_action_issues, role_issues) = run_taxonomy_validation(ir)
    
    taxonomy_total = length(action_issues) + length(cross_action_issues) + length(role_issues)
    if taxonomy_total == 0
        println("  ✓ All taxonomy checks passed")
    else
        println("  ⚠ Found $taxonomy_total taxonomy warnings")
        if !isempty(action_issues)
            println("    - $(length(action_issues)) action complementarity issues (W020)")
        end
        if !isempty(cross_action_issues)
            println("    - $(length(cross_action_issues)) cross-action contradictions (W021)")
        end
        if !isempty(role_issues)
            println("    - $(length(role_issues)) role hierarchy issues (W022)")
        end
    end
    
    # Phase 4: Exhaustiveness Validation (W023)
    println("\n[4/5] Exhaustiveness Validation (W023)...")
    (triple_gaps, condition_gaps) = run_exhaustiveness_validation(ir, max_gaps=max_exhaustiveness_gaps)
    
    exhaustiveness_total = length(triple_gaps) + length(condition_gaps)
    if exhaustiveness_total == 0
        println("  ✓ All exhaustiveness checks passed")
    else
        println("  ⚠ Found $exhaustiveness_total exhaustiveness warnings")
        if !isempty(triple_gaps)
            println("    - $(length(triple_gaps)) triple coverage gaps (W023)")
        end
        if !isempty(condition_gaps)
            println("    - $(length(condition_gaps)) condition exhaustiveness issues (W023-B)")
        end
    end
    
    # Phase 5: Generate Report
    println("\n[5/5] Generating Report...")
    
    total_errors = length(exception_structural_errors) + 
                   length(exception_satisfiability_issues) +
                   length(contradictions)
    
    total_warnings = length(action_issues) + 
                    length(cross_action_issues) +
                    length(role_issues) +
                    length(triple_gaps) +
                    length(condition_gaps)
    
    report = ValidationReport(
        exception_structural_passed,
        exception_structural_errors,
        exception_satisfiability_issues,
        contradictions,
        action_issues,
        cross_action_issues,
        role_issues,
        triple_gaps,
        condition_gaps,
        total_errors,
        total_warnings,
        string(now())
    )
    
    println("\n" * "=" ^ 70)
    println("Validation Summary:")
    println("  Errors: $total_errors")
    println("  Warnings: $total_warnings")
    println("=" ^ 70)
    
    return report
end

"""
    print_detailed_report(report::ValidationReport)

Print a detailed validation report with all issues.
"""
function print_detailed_report(report::ValidationReport)
    println("\n" * "=" ^ 70)
    println("DETAILED VALIDATION REPORT")
    println("Generated: $(report.validation_timestamp)")
    println("=" ^ 70)
    
    # Exception Validation
    println("\n## EXCEPTION VALIDATION (E050-E052)")
    println("-" ^ 70)
    
    if report.exception_structural_passed
        println("✓ Structural validation passed (E050-E051)")
    else
        println("✗ Structural validation failed:")
        for error in report.exception_structural_errors
            println("  $error")
        end
    end
    
    if !isempty(report.exception_satisfiability_issues)
        println("\n⚠ Satisfiability Issues (E052):")
        report_smt_validation_results(report.exception_satisfiability_issues, [])
    end
    
    # Contradiction Detection
    println("\n## CONTRADICTION DETECTION (E053)")
    println("-" ^ 70)
    
    if isempty(report.contradictions)
        println("✓ No contradictions detected")
    else
        report_smt_validation_results([], report.contradictions)
    end
    
    # Taxonomy Validation
    println("\n## TAXONOMY VALIDATION (W020-W022)")
    println("-" ^ 70)
    
    if isempty(report.action_complementarity_issues) && 
       isempty(report.cross_action_issues) && 
       isempty(report.role_hierarchy_issues)
        println("✓ All taxonomy checks passed")
    else
        report_taxonomy_validation_results(
            report.action_complementarity_issues,
            report.cross_action_issues,
            report.role_hierarchy_issues
        )
    end
    
    # Exhaustiveness Validation
    println("\n## EXHAUSTIVENESS VALIDATION (W023)")
    println("-" ^ 70)
    
    if isempty(report.triple_coverage_gaps) && 
       isempty(report.condition_exhaustiveness_issues)
        println("✓ All exhaustiveness checks passed")
    else
        report_exhaustiveness_results(
            report.triple_coverage_gaps,
            report.condition_exhaustiveness_issues
        )
    end
    
    # Final Summary
    println("\n" * "=" ^ 70)
    println("FINAL SUMMARY")
    println("=" ^ 70)
    println("Total Errors: $(report.total_errors)")
    println("Total Warnings: $(report.total_warnings)")
    
    if report.total_errors == 0 && report.total_warnings == 0
        println("\n✓✓✓ ALL VALIDATION CHECKS PASSED ✓✓✓")
    elseif report.total_errors == 0
        println("\n✓ No errors, but $(report.total_warnings) warnings to review")
    else
        println("\n✗ $(report.total_errors) errors must be fixed")
    end
    
    println("=" ^ 70)
end

"""
    export_report_json(report::ValidationReport, filename::String)

Export validation report as JSON.
"""
function export_report_json(report::ValidationReport, filename::String)
    # This would require JSON.jl package
    # Placeholder for future implementation
    println("JSON export not yet implemented. Would export to: $filename")
end

"""
    export_report_html(report::ValidationReport, filename::String)

Export validation report as HTML.
"""
function export_report_html(report::ValidationReport, filename::String)
    # Placeholder for future implementation
    println("HTML export not yet implemented. Would export to: $filename")
end

"""
    quick_validate(ir::DocumentIR) -> Bool

Quick validation check - returns true if no errors, false otherwise.
Useful for CI/CD pipelines.
"""
function quick_validate(ir::DocumentIR)
    report = run_all_validations(ir, max_exhaustiveness_gaps=5)
    return report.total_errors == 0
end