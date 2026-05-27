# Test Malformed Norm Syntax Detection
using Test

# Include necessary modules
include("../../src/julia/structures/structures.jl")
include("../../src/julia/structures/Hohfeldian.jl")
include("../../src/julia/structures/Taxonomies.jl")
include("../../src/julia/structures/IntermediateRepresentation.jl")
include("../../src/julia/parser/validation.jl")
include("../../src/julia/parser/norms.jl")

@testset "Malformed Norm Syntax Detection" begin
    
    @testset "Valid Single Preposition" begin
        # This should parse successfully
        ref_id = "valid-norm"
        norm_text = "*Propriétaire* **a le droit de** *déclarer* le *RevenuFoncier* envers *AdministrationFiscale*"
        
        # Should not throw error
        norm = parse_norm_body(ref_id, norm_text, false, Norm[], "test.package", Norm[])
        @test norm !== nothing
        @test norm.actor.name == "Propriétaire"
        @test norm.counterparty.name == "AdministrationFiscale"
    end
    
    @testset "Invalid: Multiple Prepositions (à + envers)" begin
        # This is the problematic syntax from the user
        ref_id = "art156-I-3-imputation-foncier"
        norm_text = "*Propriétaire* **a le droit de** *imputer* le *DéficitFoncier* à *AdministrationFiscale* envers *RevenuFoncier*"
        
        # Should throw error about multiple prepositions
        @test_throws ErrorException parse_norm_body(ref_id, norm_text, false, Norm[], "test.package", Norm[])
        
        # Check error message content
        try
            parse_norm_body(ref_id, norm_text, false, Norm[], "test.package", Norm[])
            @test false  # Should not reach here
        catch e
            @test occursin("Malformed norm syntax", e.msg)
            @test occursin("multiple prepositions", e.msg)
            @test occursin("'à'", e.msg)
            @test occursin("'envers'", e.msg)
            @test occursin("exactly one counterparty", e.msg)
            @test occursin("Procedure", e.msg)
        end
    end
    
    @testset "Invalid: Multiple Prepositions (de + envers)" begin
        ref_id = "invalid-multiple-de-envers"
        norm_text = "*Acteur* **a le devoir de** *transférer* le *Montant* de *PartieA* envers *PartieB*"
        
        # Should throw error
        @test_throws ErrorException parse_norm_body(ref_id, norm_text, false, Norm[], "test.package", Norm[])
        
        try
            parse_norm_body(ref_id, norm_text, false, Norm[], "test.package", Norm[])
            @test false
        catch e
            @test occursin("multiple prepositions", e.msg)
            @test occursin("'de'", e.msg)
            @test occursin("'envers'", e.msg)
        end
    end
    
    @testset "Invalid: Three Prepositions" begin
        ref_id = "invalid-three-preps"
        norm_text = "*Acteur* **a le droit de** *faire* le *Action* à *PartieA* de *PartieB* envers *PartieC*"
        
        # Should throw error
        @test_throws ErrorException parse_norm_body(ref_id, norm_text, false, Norm[], "test.package", Norm[])
        
        try
            parse_norm_body(ref_id, norm_text, false, Norm[], "test.package", Norm[])
            @test false
        catch e
            @test occursin("multiple prepositions", e.msg)
            # Should mention at least two of the prepositions
            @test occursin("'à'", e.msg) || occursin("'de'", e.msg) || occursin("'envers'", e.msg)
        end
    end
    
    @testset "Valid: Preposition in Object Name" begin
        # Preposition within an object name should be OK
        ref_id = "valid-prep-in-object"
        norm_text = "*Propriétaire* **a le droit de** *déduire* les *Frais de gestion* envers *AdministrationFiscale*"
        
        # The "de" in "Frais de gestion" is inside the asterisks, so it shouldn't be counted
        # This should parse successfully
        norm = parse_norm_body(ref_id, norm_text, false, Norm[], "test.package", Norm[])
        @test norm !== nothing
        @test norm.object.name == "Frais de gestion"
    end
    
    @testset "Error Message Quality" begin
        ref_id = "test-error-message"
        norm_text = "*A* **has right to** *do* *X* à *B* envers *C*"
        
        try
            parse_norm_body(ref_id, norm_text, false, Norm[], "test.package", Norm[])
            @test false
        catch e
            # Check that error message is helpful
            @test occursin("Malformed norm syntax", e.msg)
            @test occursin("test-error-message", e.msg)  # Includes ref_id
            @test occursin("Invalid syntax:", e.msg)  # Shows the problematic text
            @test occursin("Consider splitting", e.msg)  # Provides guidance
            @test occursin("bilateral relationship", e.msg)  # Explains concept
        end
    end
end

println("✓ Malformed norm syntax detection tests passed!")