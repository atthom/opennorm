using Test

include("../../src/julia/opennorm.jl")

@testset "Import System" begin
    @testset "Document with Imports" begin
        # Test that documents with imports can be parsed
        # (Skip if test file doesn't exist)
        if isfile("test_with_imports.md")
            doc = parse_document("test_with_imports.md")
            @test doc !== nothing
            @test length(doc.manifest.imports) > 0
        end
    end
    
    @testset "Stdlib Path Exists" begin
        # Test that stdlib directory exists
        @test isdir("stdlib")
        @test isdir("stdlib/frameworks")
        @test isdir("stdlib/frameworks/universal")
    end
end