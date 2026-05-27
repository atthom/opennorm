# Test Bilateral Norm Constraint
using Test

# Include necessary modules
include("../../src/julia/structures/structures.jl")
include("../../src/julia/structures/Hohfeldian.jl")
include("../../src/julia/structures/Taxonomies.jl")
include("../../src/julia/structures/IntermediateRepresentation.jl")
include("../../src/julia/parser/validation.jl")

@testset "Bilateral Norm Constraint" begin
    
    @testset "Valid Bilateral Norm" begin
        # Create a valid bilateral norm
        norm = Norm(
            ref_id = "valid-bilateral-norm",
            package = "test.package",
            Hohfeld = Right,
            actor = Taxon(Role, "Propriétaire"),
            action = Taxon(Action, "déclarer"),
            object = Taxon(Object, "RevenuFoncier"),
            counterparty = Taxon(Role, "AdministrationFiscale"),
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = "*Propriétaire* **a le droit de** *déclarer* *RevenuFoncier* envers *AdministrationFiscale*"
        )
        
        # Should pass validation
        @test validate_bilateral_norm(norm) == true
    end
    
    @testset "Invalid: Empty Actor" begin
        # Create norm with empty actor
        norm = Norm(
            ref_id = "invalid-empty-actor",
            package = "test.package",
            Hohfeld = Right,
            actor = Taxon(Role, ""),  # Empty actor
            action = Taxon(Action, "déclarer"),
            object = Taxon(Object, "RevenuFoncier"),
            counterparty = Taxon(Role, "AdministrationFiscale"),
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = ""
        )
        
        # Should throw error
        @test_throws ErrorException validate_bilateral_norm(norm)
        
        # Check error message content
        try
            validate_bilateral_norm(norm)
            @test false  # Should not reach here
        catch e
            @test occursin("Actor cannot be empty", e.msg)
            @test occursin("bilateral relationships", e.msg)
        end
    end
    
    @testset "Invalid: Empty Counterparty" begin
        # Create norm with empty counterparty
        norm = Norm(
            ref_id = "invalid-empty-counterparty",
            package = "test.package",
            Hohfeld = Right,
            actor = Taxon(Role, "Propriétaire"),
            action = Taxon(Action, "imputer"),
            object = Taxon(Object, "DéficitFoncier"),
            counterparty = Taxon(Role, ""),  # Empty counterparty
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = ""
        )
        
        # Should throw error
        @test_throws ErrorException validate_bilateral_norm(norm)
        
        # Check error message content
        try
            validate_bilateral_norm(norm)
            @test false  # Should not reach here
        catch e
            @test occursin("Counterparty cannot be empty", e.msg)
            @test occursin("bilateral relationships", e.msg)
            @test occursin("Procedure", e.msg)  # Should suggest using Procedure
        end
    end
    
    @testset "Invalid: Both Empty" begin
        # Create norm with both empty
        norm = Norm(
            ref_id = "invalid-both-empty",
            package = "test.package",
            Hohfeld = Right,
            actor = Taxon(Role, ""),  # Empty actor
            action = Taxon(Action, "calculer"),
            object = Taxon(Object, "Montant"),
            counterparty = Taxon(Role, ""),  # Empty counterparty
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = ""
        )
        
        # Should throw error (will catch actor first)
        @test_throws ErrorException validate_bilateral_norm(norm)
    end
    
    @testset "Exception Norms Also Validated" begin
        # Create parent norm
        parent = Norm(
            ref_id = "parent-norm",
            package = "test.package",
            Hohfeld = NoRight,
            actor = Taxon(Role, "Propriétaire"),
            action = Taxon(Action, "déduire"),
            object = Taxon(Object, "DéficitFoncier"),
            counterparty = Taxon(Role, "AdministrationFiscale"),
            overrules = Norm[],
            excepts = nothing,
            depth = 0,
            skipped = false,
            text = ""
        )
        
        # Create exception using constructor (should inherit valid bilateral structure)
        exception = Norm(parent, "exception-norm")
        
        # Should pass validation
        @test validate_bilateral_norm(exception) == true
        @test !isempty(exception.actor.name)
        @test !isempty(exception.counterparty.name)
    end
end

println("✓ Bilateral norm constraint tests passed!")