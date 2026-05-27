# Test Taxonomy Constraints in SMT Solver
# Tests for taxonomy subsumption and conflict detection

using Test
using Z3

# Include necessary modules
include("../../src/julia/structures/structures.jl")
include("../../src/julia/codegen/core.jl")
include("../../src/julia/codegen/smt.jl")
include("../../src/julia/SMT_solver.jl")

@testset "Taxonomy Constraint Tests" begin
    
    @testset "Taxonomy Subsumption: Parent-Child Norms" begin
        # Create taxonomy hierarchy
        # Role: Person -> NaturalPerson, LegalPerson
        role_root = Taxon(Role, "Person")
        natural_person = Taxon(role_root, "NaturalPerson")
        legal_person = Taxon(role_root, "LegalPerson")
        
        # Action: Transfer
        action_root = Taxon(Action, "AnyAction")
        transfer = Taxon(action_root, "transfer")
        
        # Object: Asset -> RealEstate, Securities
        object_root = Taxon(Object, "Asset")
        real_estate = Taxon(object_root, "RealEstate")
        securities = Taxon(object_root, "Securities")
        
        admin = Taxon(role_root, "Administration")
        
        # Test 1: Parent norm and child norm with SAME position (no conflict)
        parent_norm = Norm(
            ref_id = "parent-rule",
            package = "test",
            Hohfeld = Right,
            actor = role_root,  # Person (parent)
            action = transfer,
            object = object_root,  # Asset (parent)
            counterparty = admin,
            conditions = NormCondition[],
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = "Person has right to transfer Asset"
        )
        
        child_norm = Norm(
            ref_id = "child-rule",
            package = "test",
            Hohfeld = Right,  # Same position
            actor = natural_person,  # NaturalPerson (child)
            action = transfer,
            object = real_estate,  # RealEstate (child)
            counterparty = admin,
            conditions = NormCondition[],
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = "NaturalPerson has right to transfer RealEstate"
        )
        
        # Create IR
        manifest = Manifest(
            "Test Taxonomy",
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
            norms = [parent_norm, child_norm]
        )
        
        # Run SMT solver
        (s, contradictions) = to_smt(ir)
        
        # Should have no contradictions (same position)
        @test isempty(contradictions)
        println("✓ Test 1 passed: Same position on parent-child taxons - no conflict")
    end
    
    @testset "Taxonomy Subsumption Conflict: Opposite Positions" begin
        # Create taxonomy hierarchy
        role_root = Taxon(Role, "Person")
        natural_person = Taxon(role_root, "NaturalPerson")
        
        action_root = Taxon(Action, "AnyAction")
        transfer = Taxon(action_root, "transfer")
        
        object_root = Taxon(Object, "Asset")
        real_estate = Taxon(object_root, "RealEstate")
        
        admin = Taxon(role_root, "Administration")
        
        # Parent norm: Person has Right to transfer Asset
        parent_norm = Norm(
            ref_id = "parent-right",
            package = "test",
            Hohfeld = Right,
            actor = role_root,  # Person (parent)
            action = transfer,
            object = object_root,  # Asset (parent)
            counterparty = admin,
            conditions = NormCondition[],
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = "Person has right to transfer Asset"
        )
        
        # Child norm: NaturalPerson has NoRight to transfer RealEstate (CONFLICT!)
        child_norm = Norm(
            ref_id = "child-noright",
            package = "test",
            Hohfeld = NoRight,  # Opposite position!
            actor = natural_person,  # NaturalPerson (child)
            action = transfer,
            object = real_estate,  # RealEstate (child)
            counterparty = admin,
            conditions = NormCondition[],
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = "NaturalPerson has no right to transfer RealEstate"
        )
        
        manifest = Manifest(
            "Test Taxonomy Conflict",
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
            norms = [parent_norm, child_norm]
        )
        
        # Run SMT solver
        (s, contradictions) = to_smt(ir)
        
        # Should detect taxonomy subsumption conflict
        @test !isempty(contradictions)
        @test length(contradictions) >= 1
        
        # Check that conflict involves both norms
        conflict = contradictions[1]
        @test conflict.norm1_ref in ["parent-right", "child-noright"]
        @test conflict.norm2_ref in ["parent-right", "child-noright"]
        @test conflict.norm1_pos in ["Right", "NoRight"]
        @test conflict.norm2_pos in ["Right", "NoRight"]
        
        println("✓ Test 2 passed: Opposite positions on parent-child taxons - conflict detected")
        println("  Conflict: $(conflict.norm1_ref) ($(conflict.norm1_pos)) vs $(conflict.norm2_ref) ($(conflict.norm2_pos))")
    end
    
    @testset "Exception Allowed to Contradict Parent via Taxonomy" begin
        # Create taxonomy hierarchy
        role_root = Taxon(Role, "Person")
        natural_person = Taxon(role_root, "NaturalPerson")
        
        action_root = Taxon(Action, "AnyAction")
        transfer = Taxon(action_root, "transfer")
        
        object_root = Taxon(Object, "Asset")
        real_estate = Taxon(object_root, "RealEstate")
        
        admin = Taxon(role_root, "Administration")
        
        # Parent norm: Person has NoRight to transfer Asset
        parent_norm = Norm(
            ref_id = "parent-noright",
            package = "test",
            Hohfeld = NoRight,
            actor = role_root,
            action = transfer,
            object = object_root,
            counterparty = admin,
            conditions = [NormCondition("*Standard* = true")],
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = "Person has no right to transfer Asset"
        )
        
        # Exception: NaturalPerson has Right (exception of parent)
        exception_norm = Norm(
            parent_norm,
            "exception-right",
            text = "NaturalPerson has right to transfer RealEstate (exception)",
            conditions = [NormCondition("*Qualified* = true")]
        )
        
        # Manually adjust to use child taxons
        exception_norm = Norm(
            ref_id = "exception-right",
            package = "test",
            Hohfeld = Right,  # O(NoRight) = Right
            actor = natural_person,  # Child taxon
            action = transfer,
            object = real_estate,  # Child taxon
            counterparty = admin,
            conditions = [NormCondition("*Qualified* = true")],
            overrules = Norm[],
            excepts = "parent-noright",  # Exception of parent
            depth = 1,
            skipped = false,
            text = "NaturalPerson has right to transfer RealEstate (exception)"
        )
        
        manifest = Manifest(
            "Test Exception via Taxonomy",
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
            norms = [parent_norm, exception_norm]
        )
        
        # Run SMT solver
        (s, contradictions) = to_smt(ir)
        
        # Should have NO contradictions (exception is allowed to contradict parent)
        @test isempty(contradictions)
        println("✓ Test 3 passed: Exception allowed to contradict parent via taxonomy")
    end
    
    @testset "Taxonomy Subsumption: Unrelated Taxons" begin
        # Create separate taxonomy branches
        role_root = Taxon(Role, "AnyRole")
        person = Taxon(role_root, "Person")
        organization = Taxon(role_root, "Organization")
        
        action_root = Taxon(Action, "AnyAction")
        transfer = Taxon(action_root, "transfer")
        
        object_root = Taxon(Object, "AnyThing")
        asset = Taxon(object_root, "Asset")
        
        admin = Taxon(role_root, "Administration")
        
        # Norm 1: Person has Right
        norm1 = Norm(
            ref_id = "person-right",
            package = "test",
            Hohfeld = Right,
            actor = person,
            action = transfer,
            object = asset,
            counterparty = admin,
            conditions = NormCondition[],
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = "Person has right"
        )
        
        # Norm 2: Organization has NoRight (unrelated to Person)
        norm2 = Norm(
            ref_id = "org-noright",
            package = "test",
            Hohfeld = NoRight,
            actor = organization,  # Different branch
            action = transfer,
            object = asset,
            counterparty = admin,
            conditions = NormCondition[],
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = "Organization has no right"
        )
        
        manifest = Manifest(
            "Test Unrelated Taxons",
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
            norms = [norm1, norm2]
        )
        
        # Run SMT solver
        (s, contradictions) = to_smt(ir)
        
        # Should have no contradictions (unrelated taxons)
        @test isempty(contradictions)
        println("✓ Test 4 passed: Unrelated taxons - no conflict")
    end
end