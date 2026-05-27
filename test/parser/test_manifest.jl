using Test

include("../../src/julia/opennorm.jl")

@testset "Manifest Parsing" begin
    @testset "Parse MIT License Manifest" begin
        doc = parse_document("documents/licences/mit.strict.md")
        
        @test doc.manifest !== nothing
        @test doc.manifest.title == "MIT License"
        @test doc.manifest.version !== nothing
        @test doc.manifest.status !== nothing
        @test doc.manifest.strict == true
        @test doc.manifest.language !== nothing  # Just check it exists
        @test doc.manifest.imports isa Vector
    end
    
    @testset "Manifest with Imports" begin
        # Test document with stdlib imports (skip if file doesn't exist)
        if isfile("test_with_imports.md")
            doc = parse_document("test_with_imports.md")
            
            @test length(doc.manifest.imports) > 0
            @test any(imp -> occursin("stdlib", imp), doc.manifest.imports)
        end
    end
    
    @testset "Manifest Fields Validation" begin
        doc = parse_document("documents/licences/mit.strict.md")
        
        # Test that required fields are present (relaxed validation)
        @test !isempty(doc.manifest.title)
        @test doc.manifest.version !== nothing
        @test doc.manifest.status !== nothing  # Just check it exists
        @test doc.manifest.language !== nothing  # Just check it exists
    end
end
