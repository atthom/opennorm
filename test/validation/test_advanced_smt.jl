# Test Advanced SMT Validation
# Tests for E050-E053 validation checks

using Test

# Include the parser and validation modules
include("../../src/julia/structures/structures.jl")
include("../../src/julia/parser/exception_validation.jl")
include("../../src/julia/parser/smt_validation.jl")

@testset "Advanced SMT Validation Tests" begin
    
    @testset "E050: Structural Invariants (already implemented)" begin
        # Create test taxonomies
        role_root = Taxon(Role, "AnyRole")
        proprietaire = Taxon(role_root, "Propriétaire")
        admin = Taxon(role_root, "AdministrationFiscale")
        
        action_root = Taxon(Action, "AnyAction")
        deduire = Taxon(action_root, "déduire")
        
        object_root = Taxon(Object, "AnyThing")
        deficit = Taxon(object_root, "DéficitFoncier")
        
        # Create base norm
        base_norm = Norm(
            ref_id = "base-rule",
            package = "test",
            Hohfeld = NoRight,
            actor = proprietaire,
            action = deduire,
            object = deficit,
            counterparty = admin,
            conditions = [NormCondition("*TypePropriété* = *Standard*")],
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = "Base rule"
        )
        
        # Create valid exception using constructor
        exception_norm = Norm(
            base_norm,
            "exception-rule",
            text = "Exception rule",
            conditions = [NormCondition("*TypePropriété* = *MonumentHistorique*")]
        )
        
        # Test that exception has correct structure
        @test exception_norm.excepts == "base-rule"
        @test exception_norm.depth == 1
        @test exception_norm.Hohfeld == Right  # O(NoRight) = Right
        @test exception_norm.actor.name == "Propriétaire"
        @test exception_norm.action.name == "déduire"
        @test exception_norm.object.name == "DéficitFoncier"
        @test exception_norm.counterparty.name == "AdministrationFiscale"
        
        # Test validation passes
        norms = [base_norm, exception_norm]
        @test validate_exceptions(norms) == true
    end
    
    @testset "E051: Condition Differentiation" begin
        # Create test taxonomies
        role_root = Taxon(Role, "AnyRole")
        proprietaire = Taxon(role_root, "Propriétaire")
        admin = Taxon(role_root, "AdministrationFiscale")
        
        action_root = Taxon(Action, "AnyAction")
        deduire = Taxon(action_root, "déduire")
        
        object_root = Taxon(Object, "AnyThing")
        deficit = Taxon(object_root, "DéficitFoncier")
        
        # Create base norm with condition
        base_norm = Norm(
            ref_id = "base-rule",
            package = "test",
            Hohfeld = NoRight,
            actor = proprietaire,
            action = deduire,
            object = deficit,
            counterparty = admin,
            conditions = [NormCondition("*TypePropriété* = *Standard*")],
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = "Base rule"
        )
        
        # Test 1: Exception with DIFFERENT condition (should pass)
        exception_different = Norm(
            base_norm,
            "exception-different",
            text = "Exception with different condition",
            conditions = [NormCondition("*TypePropriété* = *MonumentHistorique*")]
        )
        
        norms_pass = [base_norm, exception_different]
        @test validate_exceptions(norms_pass) == true
        
        # Test 2: Exception with SAME condition (should fail E051)
        exception_same = Norm(
            ref_id = "exception-same",
            package = "test",
            Hohfeld = Right,
            actor = proprietaire,
            action = deduire,
            object = deficit,
            counterparty = admin,
            conditions = [NormCondition("*TypePropriété* = *Standard*")],  # Same as parent!
            overrules = Norm[],
            excepts = "base-rule",
            depth = 1,
            skipped = false,
            text = "Exception with same condition"
        )
        
        norms_fail = [base_norm, exception_same]
        @test_throws ErrorException validate_exceptions(norms_fail)
    end
    
    @testset "E052: Exception Satisfiability (framework)" begin
        using Z3
        ctx = Context()
        
        # Create test norms
        role_root = Taxon(Role, "AnyRole")
        proprietaire = Taxon(role_root, "Propriétaire")
        admin = Taxon(role_root, "AdministrationFiscale")
        
        action_root = Taxon(Action, "AnyAction")
        deduire = Taxon(action_root, "déduire")
        
        object_root = Taxon(Object, "AnyThing")
        deficit = Taxon(object_root, "DéficitFoncier")
        
        base_norm = Norm(
            ref_id = "base-rule",
            package = "test",
            Hohfeld = NoRight,
            actor = proprietaire,
            action = deduire,
            object = deficit,
            counterparty = admin,
            conditions = [NormCondition("*TypePropriété* = *Standard*")],
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = "Base rule"
        )
        
        exception_norm = Norm(
            base_norm,
            "exception-rule",
            text = "Exception rule",
            conditions = [NormCondition("*TypePropriété* = *MonumentHistorique*")]
        )
        
        # Test satisfiability check (currently returns "not yet implemented")
        result = validate_exception_satisfiability(exception_norm, base_norm, ctx)
        @test result.passed == true  # Should pass for now (not yet implemented)
        @test occursin("not yet implemented", result.message)
    end
    
    @testset "E053: Direct Contradiction Detection" begin
        using Z3
        ctx = Context()
        
        # Create test taxonomies
        role_root = Taxon(Role, "AnyRole")
        proprietaire = Taxon(role_root, "Propriétaire")
        admin = Taxon(role_root, "AdministrationFiscale")
        
        action_root = Taxon(Action, "AnyAction")
        deduire = Taxon(action_root, "déduire")
        
        object_root = Taxon(Object, "AnyThing")
        deficit = Taxon(object_root, "DéficitFoncier")
        
        # Test 1: Two norms with opposite positions, no conditions (should detect contradiction)
        norm1 = Norm(
            ref_id = "norm1",
            package = "test",
            Hohfeld = Right,
            actor = proprietaire,
            action = deduire,
            object = deficit,
            counterparty = admin,
            conditions = NormCondition[],
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = "Norm 1"
        )
        
        norm2 = Norm(
            ref_id = "norm2",
            package = "test",
            Hohfeld = NoRight,  # Opposite of Right
            actor = proprietaire,
            action = deduire,
            object = deficit,
            counterparty = admin,
            conditions = NormCondition[],
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = "Norm 2"
        )
        
        result = detect_direct_contradiction(norm1, norm2, ctx)
        @test result.passed == false
        @test result.error_code == "E053"
        @test occursin("Direct contradiction", result.message)
        
        # Test 2: Exception of parent (should NOT detect contradiction)
        base_norm = Norm(
            ref_id = "base",
            package = "test",
            Hohfeld = NoRight,
            actor = proprietaire,
            action = deduire,
            object = deficit,
            counterparty = admin,
            conditions = [NormCondition("*TypePropriété* = *Standard*")],
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = "Base"
        )
        
        exception = Norm(
            base_norm,
            "exception",
            text = "Exception",
            conditions = [NormCondition("*TypePropriété* = *MonumentHistorique*")]
        )
        
        result2 = detect_direct_contradiction(base_norm, exception, ctx)
        @test result2.passed == true
        @test occursin("exception", result2.message)
        
        # Test 3: Different relationships (should NOT detect contradiction)
        norm3 = Norm(
            ref_id = "norm3",
            package = "test",
            Hohfeld = Right,
            actor = proprietaire,
            action = deduire,
            object = deficit,
            counterparty = admin,
            conditions = NormCondition[],
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = "Norm 3"
        )
        
        # Different action
        reporter = Taxon(action_root, "reporter")
        norm4 = Norm(
            ref_id = "norm4",
            package = "test",
            Hohfeld = NoRight,
            actor = proprietaire,
            action = reporter,  # Different action
            object = deficit,
            counterparty = admin,
            conditions = NormCondition[],
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = "Norm 4"
        )
        
        result3 = detect_direct_contradiction(norm3, norm4, ctx)
        @test result3.passed == true
        @test occursin("different relationships", result3.message)
    end
    
    @testset "Integration: run_advanced_smt_validation" begin
        # Create a simple document IR with test norms
        role_root = Taxon(Role, "AnyRole")
        proprietaire = Taxon(role_root, "Propriétaire")
        admin = Taxon(role_root, "AdministrationFiscale")
        
        action_root = Taxon(Action, "AnyAction")
        deduire = Taxon(action_root, "déduire")
        
        object_root = Taxon(Object, "AnyThing")
        deficit = Taxon(object_root, "DéficitFoncier")
        
        base_norm = Norm(
            ref_id = "base",
            package = "test",
            Hohfeld = NoRight,
            actor = proprietaire,
            action = deduire,
            object = deficit,
            counterparty = admin,
            conditions = [NormCondition("*TypePropriété* = *Standard*")],
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = "Base"
        )
        
        exception = Norm(
            base_norm,
            "exception",
            text = "Exception",
            conditions = [NormCondition("*TypePropriété* = *MonumentHistorique*")]
        )
        
        manifest = Manifest(
            "Test Document",
            "Test",
            "test",
            "test",
            "1.0",
            false,
            Contract,
            Review,
            String[],
            EN
        )
        
        ir = DocumentIR(
            manifest = manifest,
            actorTaxonomy = role_root,
            actionTaxonomy = action_root,
            objectTaxonomy = object_root,
            norms = [base_norm, exception]
        )
        
        # Run validation
        (exception_issues, contradictions) = run_advanced_smt_validation(ir)
        
        # Should have no issues (conditions are different, no contradictions)
        @test isempty(exception_issues)
        @test isempty(contradictions)
    end
end