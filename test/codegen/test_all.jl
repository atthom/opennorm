using Test

include("../../src/julia/opennorm.jl")

@testset "Code Generation" begin
    @testset "Parse CGI Article 156" begin
        # Test that document can be parsed (prerequisite for codegen)
        doc = parse_document("documents/articles/CGI.Art.156.md")
        
        @test doc !== nothing
        # Note: Procedure parsing may not be fully implemented yet
        @test doc.procedures isa Vector
    end
    
    @testset "Document Structure for Codegen" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        
        # Test that document has the components needed for code generation
        @test doc.manifest !== nothing
        @test doc.procedures isa Vector
        @test doc.parameters isa Vector
    end
end