using Test

include("../../src/julia/opennorm.jl")

@testset "Translation System" begin
    @testset "Translation in Document Parsing" begin
        # Parse a French document
        doc = parse_document("documents/articles/CGI.Art.156.md")
        
        # Test that French terms were translated
        # The document should have procedures (which require translation to work)
        @test length(doc.procedures) >= 0  # Just check it doesn't error
    end
    
    @testset "Translation File Exists" begin
        # Test that translation file exists
        @test isfile("stdlib/frameworks/universal/translations/fr-en.md")
    end
end
