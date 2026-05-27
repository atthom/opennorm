using Test

include("../../src/julia/opennorm.jl")

@testset "Norm Parsing" begin
    @testset "Parse MIT License Norms" begin
        doc = parse_document("documents/licences/mit.strict.md")
        
        # Test that norms were found (use 'norms' not 'rulings')
        @test length(doc.norms) > 0
        
        # Test norm structure
        for norm in doc.norms
            @test norm.ref_id !== nothing
            @test !isempty(norm.ref_id)
            @test norm.Hohfeld !== nothing
            @test norm.actor !== nothing
            @test norm.action !== nothing
            @test norm.object !== nothing
            @test norm.counterparty !== nothing
        end
    end
    
    @testset "Hohfeldian Relations" begin
        doc = parse_document("documents/licences/mit.strict.md")
        
        # Test that Hohfeldian relations are valid Position instances
        valid_positions = [Right, Duty, Privilege, NoRight, Power, Liability, Immunity, Disability]
        
        for norm in doc.norms
            @test norm.Hohfeld in valid_positions
        end
    end
    
    @testset "Norm References" begin
        doc = parse_document("documents/licences/mit.strict.md")
        
        # Test that reference IDs follow expected format
        for norm in doc.norms
            @test occursin(r"^[A-Za-z0-9._-]+$", norm.ref_id)
        end
    end
    
    @testset "Norm Taxonomy References" begin
        doc = parse_document("documents/licences/mit.strict.md")
        
        # Test that norm components are Taxon nodes (simplified check)
        for norm in doc.norms
            # Just check that they are Taxon types
            @test norm.actor isa Taxon
            @test norm.action isa Taxon
            @test norm.object isa Taxon
            @test norm.counterparty isa Taxon
        end
    end
end
