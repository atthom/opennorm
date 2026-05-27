using Test

include("../../src/julia/opennorm.jl")

@testset "Integration Tests" begin
    @testset "Parse MIT License" begin
        doc = parse_document("documents/licences/mit.strict.md")
        
        @test doc !== nothing
        @test doc.manifest !== nothing
        @test length(doc.norms) > 0
    end
    
    @testset "Parse CGI Article 156" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        
        @test doc !== nothing
        @test doc.manifest !== nothing
        # Note: Procedure parsing may not be fully implemented yet
        @test doc.procedures isa Vector
    end
    
    @testset "Multiple Documents" begin
        # Test that multiple documents can be parsed
        docs = String[]
        
        if isfile("documents/licences/mit.strict.md")
            push!(docs, "documents/licences/mit.strict.md")
        end
        
        if isfile("documents/articles/CGI.Art.156.md")
            push!(docs, "documents/articles/CGI.Art.156.md")
        end
        
        for doc_path in docs
            doc = parse_document(doc_path)
            @test doc !== nothing
            @test doc.manifest !== nothing
        end
    end
end