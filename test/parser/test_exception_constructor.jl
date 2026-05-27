# Test Exception Norm Constructor
using Test

# Include necessary modules
include("../../src/julia/structures/structures.jl")
include("../../src/julia/structures/Hohfeldian.jl")
include("../../src/julia/structures/Taxonomies.jl")
include("../../src/julia/structures/IntermediateRepresentation.jl")

@testset "Exception Norm Constructor" begin
    # Create a parent norm
    parent = Norm(
        ref_id = "base-rule",
        package = "test.package",
        Hohfeld = NoRight,
        actor = Taxon(Role, "Propriétaire"),
        action = Taxon(Action, "déduire"),
        object = Taxon(Object, "déficit foncier"),
        counterparty = Taxon(Role, "Administration fiscale"),
        overrules = Norm[],
        excepts = nothing,
        depth = 0,
        skipped = false,
        text = "*Propriétaire* **n'a pas le droit de** *déduire* *déficit foncier* envers *Administration fiscale*"
    )
    
    @testset "Minimal Exception Constructor" begin
        # Create exception using constructor
        exception = Norm(parent, "exception-rule", text="exception de #base-rule")
        
        # Test inherited fields
        @test exception.ref_id == "exception-rule"
        @test exception.package == parent.package
        @test exception.actor.name == parent.actor.name
        @test exception.action.name == parent.action.name
        @test exception.object.name == parent.object.name
        @test exception.counterparty.name == parent.counterparty.name
        
        # Test auto-computed fields
        @test exception.Hohfeld == O(parent.Hohfeld)  # Should be Right (opposite of NoRight)
        @test exception.Hohfeld == Right
        @test exception.excepts == parent.ref_id
        @test exception.depth == parent.depth + 1
        @test exception.depth == 1
        
        # Test other fields
        @test exception.skipped == false
        @test exception.text == "exception de #base-rule"
        @test isempty(exception.overrules)
    end
    
    @testset "Exception Depth Propagation" begin
        # Create first-level exception
        exception1 = Norm(parent, "exception-1")
        @test exception1.depth == 1
        @test exception1.Hohfeld == Right  # Opposite of NoRight
        
        # Create second-level exception (exception to exception)
        exception2 = Norm(exception1, "exception-2")
        @test exception2.depth == 2
        @test exception2.Hohfeld == NoRight  # Back to parent's position
        @test exception2.excepts == exception1.ref_id
        
        # Create third-level exception
        exception3 = Norm(exception2, "exception-3")
        @test exception3.depth == 3
        @test exception3.Hohfeld == Right  # Opposite again
        @test exception3.excepts == exception2.ref_id
    end
    
    @testset "Relationship Functions" begin
        exception = Norm(parent, "exception-rule")
        
        # Test same_norm_relationship
        @test same_norm_relationship(parent, exception)
        
        # Test are_equal_norms (should be false - different positions)
        @test !are_equal_norms(parent, exception)
        
        # Create another norm with same position as parent
        same_as_parent = Norm(
            ref_id = "same-rule",
            package = parent.package,
            Hohfeld = parent.Hohfeld,
            actor = parent.actor,
            action = parent.action,
            object = parent.object,
            counterparty = parent.counterparty,
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = ""
        )
        @test are_equal_norms(parent, same_as_parent)
    end
end

println("✓ Exception norm constructor tests passed!")