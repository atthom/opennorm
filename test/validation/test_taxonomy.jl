# Test Suite for Taxonomy-Based Validation (W020-W022)
# Tests action complementarity, cross-action contradictions, and role hierarchy consistency

using Test

# Include necessary modules
include("../../src/julia/structures/Taxonomies.jl")
include("../../src/julia/structures/Hohfeldian.jl")
include("../../src/julia/structures/IntermediateRepresentation.jl")
include("../../src/julia/parser/taxonomy_validation.jl")

@testset "Taxonomy-Based Validation (W020-W022)" begin
    
    # Helper function to create test norms
    function create_test_norm(ref_id::String, actor::Taxon{Role}, action::Taxon{Action}, 
                             object::Taxon{Object}, hohfeld::Position=Right)
        counterparty = actor  # Simplified
        
        return Norm(
            ref_id=ref_id,
            package="test",
            Hohfeld=hohfeld,
            actor=actor,
            action=action,
            object=object,
            counterparty=counterparty,
            conditions=NormCondition[],
            overrules=Norm[],
            excepts=nothing,
            depth=0,
            skipped=false,
            text=""
        )
    end
    
    @testset "W020: Action Complementarity - Complete Coverage" begin
        # Create action taxonomy with siblings
        action_root = Taxon(Action, "Transaction")
        action_buy = Taxon(action_root, "Buy")
        action_sell = Taxon(action_root, "Sell")
        
        actor = Taxon(Role, "Trader")
        object = Taxon(Object, "Stock")
        
        # Create norms for both sibling actions
        norm1 = create_test_norm("N1", actor, action_buy, object)
        norm2 = create_test_norm("N2", actor, action_sell, object)
        
        results = check_action_complementarity([norm1, norm2], action_root)
        
        @test isempty(results)  # Both siblings covered, no warning
    end
    
    @testset "W020: Action Complementarity - Incomplete Coverage" begin
        # Create action taxonomy with siblings
        action_root = Taxon(Action, "Transaction")
        action_buy = Taxon(action_root, "Buy")
        action_sell = Taxon(action_root, "Sell")
        action_trade = Taxon(action_root, "Trade")
        
        actor = Taxon(Role, "Trader")
        object = Taxon(Object, "Stock")
        
        # Create norm for only one sibling
        norm1 = create_test_norm("N1", actor, action_buy, object)
        
        results = check_action_complementarity([norm1], action_root)
        
        @test length(results) == 1
        @test results[1].warning_code == "W020"
        @test occursin("Sell", results[1].message) || occursin("Trade", results[1].message)
        @test occursin("complementarity", lowercase(results[1].message))
    end
    
    @testset "W020: Action Complementarity - No Siblings" begin
        # Action with no siblings - no warning expected
        action_root = Taxon(Action, "Transaction")
        action_buy = Taxon(action_root, "Buy")
        
        actor = Taxon(Role, "Trader")
        object = Taxon(Object, "Stock")
        
        norm1 = create_test_norm("N1", actor, action_buy, object)
        
        results = check_action_complementarity([norm1], action_root)
        
        @test isempty(results)  # No siblings, no warning
    end
    
    @testset "W021: Cross-Action Contradictions - Siblings with Opposite Positions" begin
        # Create action taxonomy with siblings
        action_root = Taxon(Action, "Transaction")
        action_buy = Taxon(action_root, "Buy")
        action_sell = Taxon(action_root, "Sell")
        
        actor = Taxon(Role, "Trader")
        object = Taxon(Object, "Stock")
        
        # Create norms with opposite positions on sibling actions
        norm1 = create_test_norm("N1", actor, action_buy, object, Right)
        norm2 = create_test_norm("N2", actor, action_sell, object, NoRight)
        
        results = check_cross_action_contradictions([norm1, norm2])
        
        @test length(results) == 1
        @test results[1].warning_code == "W021"
        @test occursin("contradiction", lowercase(results[1].message))
        @test occursin("Buy", results[1].message)
        @test occursin("Sell", results[1].message)
    end
    
    @testset "W021: Cross-Action Contradictions - Same Position (No Warning)" begin
        # Create action taxonomy with siblings
        action_root = Taxon(Action, "Transaction")
        action_buy = Taxon(action_root, "Buy")
        action_sell = Taxon(action_root, "Sell")
        
        actor = Taxon(Role, "Trader")
        object = Taxon(Object, "Stock")
        
        # Create norms with same position on sibling actions
        norm1 = create_test_norm("N1", actor, action_buy, object, Right)
        norm2 = create_test_norm("N2", actor, action_sell, object, Right)
        
        results = check_cross_action_contradictions([norm1, norm2])
        
        @test isempty(results)  # Same position, no contradiction
    end
    
    @testset "W021: Cross-Action Contradictions - Unrelated Actions" begin
        # Create unrelated actions
        action_buy = Taxon(Action, "Buy")
        action_claim = Taxon(Action, "Claim")
        
        actor = Taxon(Role, "Trader")
        object = Taxon(Object, "Stock")
        
        # Create norms with opposite positions on unrelated actions
        norm1 = create_test_norm("N1", actor, action_buy, object, Right)
        norm2 = create_test_norm("N2", actor, action_claim, object, NoRight)
        
        results = check_cross_action_contradictions([norm1, norm2])
        
        @test isempty(results)  # Unrelated actions, no warning
    end
    
    @testset "W021: Cross-Action Contradictions - Exception Relationship" begin
        # Create action taxonomy with siblings
        action_root = Taxon(Action, "Transaction")
        action_buy = Taxon(action_root, "Buy")
        action_sell = Taxon(action_root, "Sell")
        
        actor = Taxon(Role, "Trader")
        object = Taxon(Object, "Stock")
        
        # Create norms where one is an exception of the other
        norm1 = create_test_norm("N1", actor, action_buy, object, Right)
        norm2 = Norm(
            ref_id="N2",
            package="test",
            Hohfeld=NoRight,
            actor=actor,
            action=action_sell,
            object=object,
            counterparty=actor,
            conditions=NormCondition[],
            overrules=Norm[],
            excepts="N1",  # Exception of N1
            depth=1,
            skipped=false,
            text=""
        )
        
        results = check_cross_action_contradictions([norm1, norm2])
        
        @test isempty(results)  # Exception relationship, no warning
    end
    
    @testset "W022: Role Hierarchy - Prohibition on Parent Role" begin
        # Create role taxonomy with parent-child
        role_root = Taxon(Role, "Person")
        role_employee = Taxon(role_root, "Employee")
        role_manager = Taxon(role_employee, "Manager")
        
        action = Taxon(Action, "Trade")
        object = Taxon(Object, "Stock")
        
        # Create prohibition on parent role
        norm1 = create_test_norm("N1", role_employee, action, object, NoRight)
        
        results = check_role_hierarchy_consistency([norm1], role_root)
        
        @test length(results) == 1
        @test results[1].warning_code == "W022"
        @test occursin("Manager", results[1].message)
        @test occursin("hierarchy", lowercase(results[1].message))
    end
    
    @testset "W022: Role Hierarchy - Prohibition with Exception" begin
        # Create role taxonomy with parent-child
        role_root = Taxon(Role, "Person")
        role_employee = Taxon(role_root, "Employee")
        role_manager = Taxon(role_employee, "Manager")
        
        action = Taxon(Action, "Trade")
        object = Taxon(Object, "Stock")
        
        # Create prohibition on parent role
        norm1 = create_test_norm("N1", role_employee, action, object, NoRight)
        
        # Create exception for child role
        norm2 = Norm(
            ref_id="N2",
            package="test",
            Hohfeld=Right,
            actor=role_manager,
            action=action,
            object=object,
            counterparty=role_manager,
            conditions=NormCondition[],
            overrules=Norm[],
            excepts="N1",
            depth=1,
            skipped=false,
            text=""
        )
        
        results = check_role_hierarchy_consistency([norm1, norm2], role_root)
        
        @test isempty(results)  # Exception exists, no warning
    end
    
    @testset "W022: Role Hierarchy - No Children" begin
        # Create role with no children
        role_employee = Taxon(Role, "Employee")
        
        action = Taxon(Action, "Trade")
        object = Taxon(Object, "Stock")
        
        # Create prohibition on role with no children
        norm1 = create_test_norm("N1", role_employee, action, object, NoRight)
        
        results = check_role_hierarchy_consistency([norm1], role_employee)
        
        @test isempty(results)  # No children, no warning
    end
    
    @testset "W022: Role Hierarchy - Disability Position" begin
        # Create role taxonomy with parent-child
        role_root = Taxon(Role, "Person")
        role_employee = Taxon(role_root, "Employee")
        role_intern = Taxon(role_employee, "Intern")
        
        action = Taxon(Action, "Sign")
        object = Taxon(Object, "Contract")
        
        # Create disability on parent role
        norm1 = create_test_norm("N1", role_employee, action, object, Disability)
        
        results = check_role_hierarchy_consistency([norm1], role_root)
        
        @test length(results) == 1
        @test results[1].warning_code == "W022"
        @test occursin("Intern", results[1].message)
    end
    
    @testset "Integration - Full Taxonomy Validation" begin
        # Create complete taxonomy structure
        role_root = Taxon(Role, "Person")
        role_employee = Taxon(role_root, "Employee")
        role_manager = Taxon(role_employee, "Manager")
        
        action_root = Taxon(Action, "Transaction")
        action_buy = Taxon(action_root, "Buy")
        action_sell = Taxon(action_root, "Sell")
        
        object = Taxon(Object, "Stock")
        
        # Create norms with various issues
        norm1 = create_test_norm("N1", role_employee, action_buy, object, NoRight)  # W022: affects Manager
        norm2 = create_test_norm("N2", role_employee, action_sell, object, Right)   # W021: opposite of norm1
        # Missing norm for action_buy with Right - W020: incomplete coverage
        
        # Create a minimal manifest (positional arguments)
        manifest = Manifest(
            "Test Document",      # title
            "Test",               # description
            "test",               # package
            "contract",           # package_type
            "1.0.0",             # version
            false,                # strict
            Contract,             # normLevel
            Final,                # status
            String[],             # imports
            EN                    # language
        )
        
        ir = DocumentIR(
            manifest=manifest,
            actorTaxonomy=role_root,
            actionTaxonomy=action_root,
            objectTaxonomy=object,
            norms=[norm1, norm2],
            procedures=Procedure[],
            parameters=Parameter[],
            input_variables=InputVariable[]
        )
        
        (action_issues, cross_action_issues, role_issues) = run_taxonomy_validation(ir)
        
        # Should detect role hierarchy issue
        @test !isempty(role_issues)
        @test any(r -> r.warning_code == "W022", role_issues)
        
        # Should detect cross-action contradiction
        @test !isempty(cross_action_issues)
        @test any(r -> r.warning_code == "W021", cross_action_issues)
    end
    
    @testset "Helper Functions - get_sibling_taxons" begin
        # Create taxonomy
        root = Taxon(Action, "Root")
        child1 = Taxon(root, "Child1")
        child2 = Taxon(root, "Child2")
        child3 = Taxon(root, "Child3")
        
        siblings = get_sibling_taxons(child1)
        
        @test length(siblings) == 2
        @test child2 in siblings
        @test child3 in siblings
        @test !(child1 in siblings)
    end
    
    @testset "Helper Functions - get_all_descendants" begin
        # Create taxonomy
        root = Taxon(Role, "Root")
        child1 = Taxon(root, "Child1")
        grandchild1 = Taxon(child1, "Grandchild1")
        child2 = Taxon(root, "Child2")
        
        descendants = get_all_descendants(root)
        
        @test length(descendants) == 3
        @test child1 in descendants
        @test child2 in descendants
        @test grandchild1 in descendants
    end
    
    @testset "Helper Functions - get_ancestor_chain" begin
        # Create taxonomy
        root = Taxon(Role, "Root")
        child = Taxon(root, "Child")
        grandchild = Taxon(child, "Grandchild")
        
        ancestors = get_ancestor_chain(grandchild)
        
        @test length(ancestors) == 2
        @test child == ancestors[1]
        @test root == ancestors[2]
    end
    
    @testset "Reporting - Format Output" begin
        # Create sample results
        action_result = TaxonomyValidationResult(
            false,
            "W020",
            "Test action complementarity message",
            ["N1"],
            ["Action1", "Action2"]
        )
        
        cross_action_result = TaxonomyValidationResult(
            false,
            "W021",
            "Test cross-action contradiction message",
            ["N1", "N2"],
            ["Buy", "Sell"]
        )
        
        role_result = TaxonomyValidationResult(
            false,
            "W022",
            "Test role hierarchy message",
            ["N1"],
            ["Manager", "Director"]
        )
        
        # Test that reporting doesn't crash
        @test_nowarn report_taxonomy_validation_results(
            [action_result],
            [cross_action_result],
            [role_result]
        )
    end
end

println("\n✓ All taxonomy validation tests completed")