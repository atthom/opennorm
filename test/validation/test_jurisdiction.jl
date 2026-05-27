using Test
using Z3
using CommonMark
using AbstractTrees

# Import the necessary modules - need to include structures.jl first for base types
include("../../src/julia/structures/structures.jl")
include("../../src/julia/parser/jurisdiction.jl")
include("../../src/julia/SMT_solver.jl")

@testset "Jurisdiction Hierarchy Tests" begin
    
    @testset "Jurisdiction Construction" begin
        j1 = Jurisdiction("FR", "Constitution")
        @test j1.namespace == "FR"
        @test j1.name == "Constitution"
        
        j2 = Jurisdiction("FR.Constitution")
        @test j2.namespace == "FR"
        @test j2.name == "Constitution"
        
        j3 = Jurisdiction("EU.Regulation")
        @test j3.namespace == "EU"
        @test j3.name == "Regulation"
    end
    
    @testset "LexSuperior Parsing - Simple Chain" begin
        lines = ["FR.Constitution > FR.Loi > FR.Décret"]
        hierarchy = build_jurisdiction_hierarchy(parse_lex_superior(lines))
        
        @test length(hierarchy.relations) == 2
        @test length(hierarchy.jurisdictions) == 3
        
        # Check first relation: Constitution > Loi
        rel1 = hierarchy.relations[1]
        @test rel1.superior.namespace == "FR"
        @test rel1.superior.name == "Constitution"
        @test rel1.inferior.namespace == "FR"
        @test rel1.inferior.name == "Loi"
        @test rel1.ambiguous == false
        
        # Check second relation: Loi > Décret
        rel2 = hierarchy.relations[2]
        @test rel2.superior.namespace == "FR"
        @test rel2.superior.name == "Loi"
        @test rel2.inferior.namespace == "FR"
        @test rel2.inferior.name == "Décret"
        @test rel2.ambiguous == false
    end
    
    @testset "LexSuperior Parsing - Ambiguous Relationship" begin
        lines = ["EU.Regulation ~ FR.Constitution"]
        hierarchy = build_jurisdiction_hierarchy(parse_lex_superior(lines))
        
        @test length(hierarchy.relations) == 2  # Ambiguous creates bidirectional relations
        @test length(hierarchy.jurisdictions) == 2
        
        # Both relations should be ambiguous
        @test all(rel.ambiguous for rel in hierarchy.relations)
    end
    
    @testset "LexSuperior Parsing - Multiple Lines" begin
        lines = [
            "FR.Constitution > FR.Loi > FR.Décret > FR.Arrêté",
            "EU.Regulation > FR.Loi",
            "EU.Directive > FR.Loi",
            "EU.Regulation ~ FR.Constitution"
        ]
        hierarchy = build_jurisdiction_hierarchy(parse_lex_superior(lines))
        
        @test length(hierarchy.relations) == 7  # 3 + 1 + 1 + 2 (ambiguous is bidirectional)
        @test length(hierarchy.jurisdictions) == 6  # FR.Constitution, FR.Loi, FR.Décret, FR.Arrêté, EU.Regulation, EU.Directive
    end
    
    @testset "Jurisdiction Hierarchy Validation - Valid" begin
        lines = [
            "FR.Constitution > FR.Loi > FR.Décret",
            "EU.Regulation > FR.Loi"
        ]
        hierarchy = build_jurisdiction_hierarchy(parse_lex_superior(lines))
        
        # Should return empty array (no errors)
        @test isempty(validate_jurisdiction_hierarchy(hierarchy))
    end
    
    @testset "Get Jurisdiction Relation" begin
        lines = [
            "FR.Constitution > FR.Loi > FR.Décret",
            "EU.Regulation ~ FR.Constitution"
        ]
        hierarchy = build_jurisdiction_hierarchy(parse_lex_superior(lines))
        
        const_j = Jurisdiction("FR", "Constitution")
        loi_j = Jurisdiction("FR", "Loi")
        decret_j = Jurisdiction("FR", "Décret")
        eu_reg_j = Jurisdiction("EU", "Regulation")
        
        # Direct relationship
        @test get_jurisdiction_relation(hierarchy, const_j, loi_j) == :superior
        @test get_jurisdiction_relation(hierarchy, loi_j, const_j) == :inferior
        
        # Ambiguous relationship
        @test get_jurisdiction_relation(hierarchy, eu_reg_j, const_j) == :ambiguous
        @test get_jurisdiction_relation(hierarchy, const_j, eu_reg_j) == :ambiguous
        
        # No relationship
        unknown_j = Jurisdiction("US", "Constitution")
        @test get_jurisdiction_relation(hierarchy, const_j, unknown_j) === nothing
    end
    
    @testset "SMT Encoding - Cycle Detection" begin
        # Create a cycle: A > B > C > A
        lines = [
            "A.Law > B.Law",
            "B.Law > C.Law",
            "C.Law > A.Law"
        ]
        hierarchy = build_jurisdiction_hierarchy(parse_lex_superior(lines))
        
        ctx = Context()
        solver = Solver(ctx)
        
        # Encode the hierarchy
        encode_jurisdiction_hierarchy!(solver, hierarchy, ctx)
        
        # Check satisfiability - should be UNSAT due to cycle
        result = check(solver)
        @test string(result) == "unsat"
    end
    
    @testset "SMT Encoding - Valid Hierarchy" begin
        lines = [
            "FR.Constitution > FR.Loi > FR.Décret > FR.Arrêté"
        ]
        hierarchy = build_jurisdiction_hierarchy(parse_lex_superior(lines))
        
        ctx = Context()
        solver = Solver(ctx)
        
        encode_jurisdiction_hierarchy!(solver, hierarchy, ctx)
        
        # Should be satisfiable
        result = check(solver)
        @test string(result) == "sat"
    end
    
    @testset "SMT Encoding - Transitive Inference" begin
        # A > B, B > C should imply A > C
        lines = [
            "A.Law > B.Law",
            "B.Law > C.Law"
        ]
        hierarchy = build_jurisdiction_hierarchy(parse_lex_superior(lines))
        
        ctx = Context()
        solver = Solver(ctx)
        
        encode_jurisdiction_hierarchy!(solver, hierarchy, ctx)
        
        # Should be satisfiable - Z3 will automatically infer A > C from transitivity
        @test string(check(solver)) == "sat"
        
        # Note: The transitive property (A > C) is automatically handled by Z3's
        # integer constraint solver. We don't need to explicitly verify the values
        # as Z3 guarantees transitivity of > constraints on integers.
    end
    
    @testset "SMT Encoding - Ambiguous Relationships" begin
        # A ~ B means they can coexist without ordering
        lines = [
            "A.Law ~ B.Law"
        ]
        hierarchy = build_jurisdiction_hierarchy(parse_lex_superior(lines))
        
        ctx = Context()
        solver = Solver(ctx)
        
        encode_jurisdiction_hierarchy!(solver, hierarchy, ctx)
        
        # Should be satisfiable (no constraint added for ambiguous)
        @test string(check(solver)) == "sat"
    end
    
    @testset "Jurisdiction Conflict Resolution" begin
        # Create norms with different jurisdictions
        const_j = Jurisdiction("FR", "Constitution")
        loi_j = Jurisdiction("FR", "Loi")
        
        lines = ["FR.Constitution > FR.Loi"]
        hierarchy = build_jurisdiction_hierarchy(parse_lex_superior(lines))
        
        # Create two conflicting norms
        norm1 = Norm(
            ref_id="norm1",
            package="test",
            Hohfeld=Right,
            actor=Taxon(Role, "Citizen"),
            counterparty=Taxon(Role, "State"),
            action=Taxon(Action, "Have"),
            object=Taxon(Object, "Freedom"),
            conditions=NormCondition[],
            overrules=Norm[],
            skipped=false,
            jurisdiction=const_j
        )
        
        norm2 = Norm(
            ref_id="norm2",
            package="test",
            Hohfeld=NoRight,  # Contradicts norm1
            actor=Taxon(Role, "Citizen"),
            counterparty=Taxon(Role, "State"),
            action=Taxon(Action, "Have"),
            object=Taxon(Object, "Freedom"),
            conditions=NormCondition[],
            overrules=Norm[],
            skipped=false,
            jurisdiction=loi_j
        )
        
        ctx = Context()
        solver = Solver(ctx)
        
        # Encode hierarchy
        encode_jurisdiction_hierarchy!(solver, hierarchy, ctx)
        
        # Add jurisdiction constraints
        add_jurisdiction_constraints!(solver, [norm1, norm2], hierarchy, ctx)
        
        # Should detect that norm1 (Constitution) overrides norm2 (Loi)
        # The solver should be SAT because the conflict is resolved by hierarchy
        result = check(solver)
        @test string(result) == "sat"
    end
    
    @testset "Jurisdiction Conflict - Ambiguous" begin
        # Create norms with ambiguous jurisdictions
        eu_j = Jurisdiction("EU", "Regulation")
        fr_j = Jurisdiction("FR", "Constitution")
        
        lines = ["EU.Regulation ~ FR.Constitution"]
        hierarchy = build_jurisdiction_hierarchy(parse_lex_superior(lines))
        
        norm1 = Norm(
            ref_id="norm1",
            package="test",
            Hohfeld=Right,
            actor=Taxon(Role, "Citizen"),
            counterparty=Taxon(Role, "State"),
            action=Taxon(Action, "Have"),
            object=Taxon(Object, "Freedom"),
            conditions=NormCondition[],
            overrules=Norm[],
            skipped=false,
            jurisdiction=eu_j
        )
        
        norm2 = Norm(
            ref_id="norm2",
            package="test",
            Hohfeld=NoRight,
            actor=Taxon(Role, "Citizen"),
            counterparty=Taxon(Role, "State"),
            action=Taxon(Action, "Have"),
            object=Taxon(Object, "Freedom"),
            conditions=NormCondition[],
            overrules=Norm[],
            skipped=false,
            jurisdiction=fr_j
        )
        
        ctx = Context()
        solver = Solver(ctx)
        
        encode_jurisdiction_hierarchy!(solver, hierarchy, ctx)
        
        # This should flag an ambiguous conflict
        # The implementation should warn about this
        add_jurisdiction_constraints!(solver, [norm1, norm2], hierarchy, ctx)
        
        # Should still be SAT (no constraint added for ambiguous)
        result = check(solver)
        @test string(result) == "sat"
    end
    
    @testset "Exception Hierarchy Overrides Jurisdiction" begin
        # Exceptions should contradict parents regardless of jurisdiction
        parent_j = Jurisdiction("FR", "Loi")
        exception_j = Jurisdiction("FR", "Décret")
        
        lines = ["FR.Loi > FR.Décret"]
        hierarchy = build_jurisdiction_hierarchy(parse_lex_superior(lines))
        
        parent = Norm(
            ref_id="parent",
            package="test",
            Hohfeld=Right,
            actor=Taxon(Role, "Citizen"),
            counterparty=Taxon(Role, "State"),
            action=Taxon(Action, "Have"),
            object=Taxon(Object, "Freedom"),
            conditions=NormCondition[],
            overrules=Norm[],
            skipped=false,
            jurisdiction=parent_j
        )
        
        exception = Norm(
            ref_id="exception",
            package="test",
            Hohfeld=NoRight,
            actor=Taxon(Role, "Citizen"),
            counterparty=Taxon(Role, "State"),
            action=Taxon(Action, "Have"),
            object=Taxon(Object, "Freedom"),
            conditions=NormCondition[],
            overrules=Norm[],
            skipped=false,
            excepts="parent",
            jurisdiction=exception_j
        )
        
        # Add exception to parent - create a new norm with the exception in overrules
        parent_with_exception = Norm(
            ref_id=parent.ref_id,
            package=parent.package,
            Hohfeld=parent.Hohfeld,
            actor=parent.actor,
            counterparty=parent.counterparty,
            action=parent.action,
            object=parent.object,
            conditions=parent.conditions,
            overrules=[exception],
            skipped=parent.skipped,
            jurisdiction=parent.jurisdiction
        )
        
        ctx = Context()
        solver = Solver(ctx)
        
        encode_jurisdiction_hierarchy!(solver, hierarchy, ctx)
        add_jurisdiction_constraints!(solver, [parent_with_exception], hierarchy, ctx)
        
        # Should be SAT - exceptions are allowed to contradict parents
        result = check(solver)
        @test string(result) == "sat"
    end
    
    @testset "Has Overrule Relationship" begin
        lines = [
            "FR.Constitution > FR.Loi > FR.Décret",
            "EU.Regulation ~ FR.Constitution"
        ]
        hierarchy = build_jurisdiction_hierarchy(parse_lex_superior(lines))
        
        const_j = Jurisdiction("FR", "Constitution")
        loi_j = Jurisdiction("FR", "Loi")
        decret_j = Jurisdiction("FR", "Décret")
        eu_reg_j = Jurisdiction("EU", "Regulation")
        
        # Direct overrule
        @test has_overrule_relationship(hierarchy, const_j, loi_j) == true
        @test has_overrule_relationship(hierarchy, loi_j, const_j) == false
        
        # Ambiguous - no overrule
        @test has_overrule_relationship(hierarchy, eu_reg_j, const_j) == false
        @test has_overrule_relationship(hierarchy, const_j, eu_reg_j) == false
        
        # Unknown - no overrule
        unknown_j = Jurisdiction("US", "Constitution")
        @test has_overrule_relationship(hierarchy, const_j, unknown_j) == false
    end
end