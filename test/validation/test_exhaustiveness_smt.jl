# Test Suite for SMT-Enhanced Exhaustiveness Validation (W023-B)
# Tests mutual exclusivity and exhaustiveness checks using Z3

using Test
using Z3

# Include necessary modules
include("../../src/julia/structures/Taxonomies.jl")
include("../../src/julia/structures/Hohfeldian.jl")
include("../../src/julia/structures/IntermediateRepresentation.jl")
include("../../src/julia/parser/condition_parser.jl")
include("../../src/julia/parser/condition_smt_encoder.jl")
include("../../src/julia/parser/exhaustiveness_validation.jl")

@testset "SMT-Enhanced Exhaustiveness Validation (W023-B)" begin
    
    # Helper function to create test norms
    function create_test_norm(ref_id::String, actor_name::String, action_name::String, 
                             object_name::String, condition_text::String="")
        actor = Taxon(Role, actor_name)
        action = Taxon(Action, action_name)
        object = Taxon(Object, object_name)
        counterparty = Taxon(Role, actor_name)
        
        conditions = if isempty(condition_text)
            NormCondition[]
        else
            [parse_norm_condition(condition_text)]
        end
        
        return Norm(
            ref_id=ref_id,
            package="test",
            Hohfeld=Right,
            actor=actor,
            action=action,
            object=object,
            counterparty=counterparty,
            conditions=conditions,
            overrules=Norm[],
            excepts=nothing,
            depth=0,
            skipped=false,
            text=""
        )
    end
    
    @testset "Mutual Exclusivity - No Overlap (Should Pass)" begin
        # Two norms with mutually exclusive conditions
        norm1 = create_test_norm("N1", "Taxpayer", "Deduct", "Expense", "*PropertyType* = *Historic*")
        norm2 = create_test_norm("N2", "Taxpayer", "Deduct", "Expense", "*PropertyType* = *Standard*")
        
        ctx = Context()
        triple = NormativeTriple("Taxpayer", "Deduct", "Expense", "Taxpayer")
        
        results = check_conditions_mutually_exclusive([norm1, norm2], triple, ctx)
        
        @test isempty(results)  # No overlap, so no warnings
    end
    
    @testset "Mutual Exclusivity - Overlap Detected (Should Warn)" begin
        # Two norms with overlapping conditions
        norm1 = create_test_norm("N1", "Taxpayer", "Deduct", "Expense", "*Amount* > 1000")
        norm2 = create_test_norm("N2", "Taxpayer", "Deduct", "Expense", "*Amount* > 500")
        
        ctx = Context()
        triple = NormativeTriple("Taxpayer", "Deduct", "Expense", "Taxpayer")
        
        results = check_conditions_mutually_exclusive([norm1, norm2], triple, ctx)
        
        @test length(results) == 1
        @test results[1].warning_code == "W023-B-1"
        @test occursin("overlap", lowercase(results[1].message))
        @test occursin("N1", results[1].message)
        @test occursin("N2", results[1].message)
    end
    
    @testset "Mutual Exclusivity - Identical Conditions (Should Warn)" begin
        # Two norms with identical conditions
        norm1 = create_test_norm("N1", "Taxpayer", "Deduct", "Expense", "*PropertyType* = *Historic*")
        norm2 = create_test_norm("N2", "Taxpayer", "Deduct", "Expense", "*PropertyType* = *Historic*")
        
        ctx = Context()
        triple = NormativeTriple("Taxpayer", "Deduct", "Expense", "Taxpayer")
        
        results = check_conditions_mutually_exclusive([norm1, norm2], triple, ctx)
        
        @test length(results) == 1
        @test results[1].warning_code == "W023-B-1"
    end
    
    @testset "Mutual Exclusivity - Complex Logical Conditions" begin
        # Two norms with complex conditions that overlap
        norm1 = create_test_norm("N1", "Taxpayer", "Deduct", "Expense", 
                                "*PropertyType* = *Historic* et *Amount* > 1000")
        norm2 = create_test_norm("N2", "Taxpayer", "Deduct", "Expense", 
                                "*PropertyType* = *Historic* et *Amount* > 500")
        
        ctx = Context()
        triple = NormativeTriple("Taxpayer", "Deduct", "Expense", "Taxpayer")
        
        results = check_conditions_mutually_exclusive([norm1, norm2], triple, ctx)
        
        @test length(results) == 1  # Should detect overlap
        @test results[1].warning_code == "W023-B-1"
    end
    
    @testset "Exhaustiveness - Complete Coverage (Should Pass)" begin
        # Two norms that together cover all cases
        norm1 = create_test_norm("N1", "Taxpayer", "Deduct", "Expense", "*PropertyType* = *Historic*")
        norm2 = create_test_norm("N2", "Taxpayer", "Deduct", "Expense", "*PropertyType* != *Historic*")
        
        ctx = Context()
        triple = NormativeTriple("Taxpayer", "Deduct", "Expense", "Taxpayer")
        
        result = check_conditions_cover_all_cases([norm1, norm2], triple, ctx)
        
        @test isnothing(result)  # No gap, so no warning
    end
    
    @testset "Exhaustiveness - Gap Detected (Should Warn)" begin
        # Two norms that don't cover all cases
        norm1 = create_test_norm("N1", "Taxpayer", "Deduct", "Expense", "*Amount* > 1000")
        norm2 = create_test_norm("N2", "Taxpayer", "Deduct", "Expense", "*Amount* < 500")
        
        ctx = Context()
        triple = NormativeTriple("Taxpayer", "Deduct", "Expense", "Taxpayer")
        
        result = check_conditions_cover_all_cases([norm1, norm2], triple, ctx)
        
        @test !isnothing(result)
        @test result.warning_code == "W023-B-2"
        @test occursin("gap", lowercase(result.message))
        @test occursin("not cover all possible cases", result.message)
    end
    
    @testset "Exhaustiveness - Boolean Coverage" begin
        # Test with boolean conditions
        norm1 = create_test_norm("N1", "Taxpayer", "Deduct", "Expense", "*IsHistoric* = Oui")
        norm2 = create_test_norm("N2", "Taxpayer", "Deduct", "Expense", "*IsHistoric* = Non")
        
        ctx = Context()
        triple = NormativeTriple("Taxpayer", "Deduct", "Expense", "Taxpayer")
        
        result = check_conditions_cover_all_cases([norm1, norm2], triple, ctx)
        
        @test isnothing(result)  # Complete coverage
    end
    
    @testset "Exhaustiveness - Partial Boolean Coverage (Gap)" begin
        # Only one boolean case covered
        norm1 = create_test_norm("N1", "Taxpayer", "Deduct", "Expense", "*IsHistoric* = Oui")
        
        ctx = Context()
        triple = NormativeTriple("Taxpayer", "Deduct", "Expense", "Taxpayer")
        
        result = check_conditions_cover_all_cases([norm1], triple, ctx)
        
        @test !isnothing(result)
        @test result.warning_code == "W023-B-2"
    end
    
    @testset "Full Check - Multiple Issues" begin
        # Three norms: two overlap, and together they don't cover all cases
        norm1 = create_test_norm("N1", "Taxpayer", "Deduct", "Expense", "*Amount* > 1000")
        norm2 = create_test_norm("N2", "Taxpayer", "Deduct", "Expense", "*Amount* > 500")
        norm3 = create_test_norm("N3", "Taxpayer", "Deduct", "Expense", "*Amount* < 100")
        
        ctx = Context()
        
        results = check_condition_exhaustiveness([norm1, norm2, norm3], ctx)
        
        # Should detect both overlap (N1 and N2) and gap (500-1000 range not fully covered)
        @test length(results) >= 1
        
        # Check for overlap warning
        overlap_warnings = filter(r -> r.warning_code == "W023-B-1", results)
        @test !isempty(overlap_warnings)
        
        # Check for gap warning
        gap_warnings = filter(r -> r.warning_code == "W023-B-2", results)
        @test !isempty(gap_warnings)
    end
    
    @testset "No Conditions - Should Skip" begin
        # Norm with no conditions covers everything
        norm1 = create_test_norm("N1", "Taxpayer", "Deduct", "Expense", "")
        norm2 = create_test_norm("N2", "Taxpayer", "Deduct", "Expense", "*Amount* > 1000")
        
        ctx = Context()
        
        results = check_condition_exhaustiveness([norm1, norm2], ctx)
        
        # Should not report exhaustiveness gap (norm1 covers everything)
        # But might report overlap if norm2's condition is checked
        gap_warnings = filter(r -> r.warning_code == "W023-B-2", results)
        @test isempty(gap_warnings)
    end
    
    @testset "Single Norm - No Check Needed" begin
        # Only one norm for a triple - no need to check
        norm1 = create_test_norm("N1", "Taxpayer", "Deduct", "Expense", "*Amount* > 1000")
        
        ctx = Context()
        
        results = check_condition_exhaustiveness([norm1], ctx)
        
        @test isempty(results)  # No warnings for single norm
    end
    
    @testset "Different Triples - No Interaction" begin
        # Norms for different triples should not be checked against each other
        norm1 = create_test_norm("N1", "Taxpayer", "Deduct", "Expense", "*Amount* > 1000")
        norm2 = create_test_norm("N2", "Taxpayer", "Claim", "Refund", "*Amount* > 1000")
        
        ctx = Context()
        
        results = check_condition_exhaustiveness([norm1, norm2], ctx)
        
        @test isempty(results)  # Different actions, no checks
    end
    
    @testset "Complex Logical Expressions - Exhaustiveness" begin
        # Test with AND/OR combinations
        norm1 = create_test_norm("N1", "Taxpayer", "Deduct", "Expense", 
                                "*PropertyType* = *Historic* et *Amount* > 1000")
        norm2 = create_test_norm("N2", "Taxpayer", "Deduct", "Expense", 
                                "*PropertyType* = *Historic* et *Amount* <= 1000")
        norm3 = create_test_norm("N3", "Taxpayer", "Deduct", "Expense", 
                                "*PropertyType* != *Historic*")
        
        ctx = Context()
        triple = NormativeTriple("Taxpayer", "Deduct", "Expense", "Taxpayer")
        
        result = check_conditions_cover_all_cases([norm1, norm2, norm3], triple, ctx)
        
        @test isnothing(result)  # Should be exhaustive
    end
    
    @testset "Integration - Full Validation Pipeline" begin
        # Create a complete IR with multiple norms
        actor_tax = Taxon(Role, "Taxpayer")
        action_tax = Taxon(Action, "Deduct")
        object_tax = Taxon(Object, "Expense")
        
        norm1 = create_test_norm("N1", "Taxpayer", "Deduct", "Expense", "*Amount* > 1000")
        norm2 = create_test_norm("N2", "Taxpayer", "Deduct", "Expense", "*Amount* > 500")
        
        ir = DocumentIR(
            package="test",
            version="1.0.0",
            lang=EN,
            status=Final,
            norm_level=Contract,
            actorTaxonomy=actor_tax,
            actionTaxonomy=action_tax,
            objectTaxonomy=object_tax,
            norms=[norm1, norm2],
            procedures=Procedure[],
            parameters=Parameter[],
            input_variables=InputVariable[]
        )
        
        (triple_gaps, condition_gaps) = run_exhaustiveness_validation(ir, max_gaps=10)
        
        # Should detect overlap in conditions
        @test !isempty(condition_gaps)
        overlap_found = any(r -> r.warning_code == "W023-B-1", condition_gaps)
        @test overlap_found
    end
end

println("\n✓ All SMT-enhanced exhaustiveness validation tests completed")