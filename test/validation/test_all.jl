using Test

include("../../src/julia/opennorm.jl")

@testset "Validation" begin
    @testset "Parse and Validate CGI Article 156" begin
        # Test that document can be parsed and validated
        doc = parse_document("documents/articles/CGI.Art.156.md")
        
        @test doc !== nothing
        @test doc.objectTaxonomy !== nothing
    end
    
    @testset "Procedure Structure" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        
        # Test that procedures have expected structure
        if length(doc.procedures) > 0
            proc = doc.procedures[1]
            @test proc.name !== nothing
            @test proc.expression_text !== nothing
        end
    end
    
    # Include advanced validation test suites
    println("\n=== Running Advanced SMT Validation Tests ===")
    include("test_advanced_smt.jl")
    
    println("\n=== Running Taxonomy Validation Tests (W020-W022) ===")
    include("test_taxonomy.jl")
    
    println("\n=== Running SMT-Enhanced Exhaustiveness Tests (W023-B) ===")
    include("test_exhaustiveness_smt.jl")
    
    println("\n=== Running Type Environment Tests ===")
    include("test_type_env.jl")
    
    println("\n=== Running Dimensional Analysis Tests ===")
    include("test_dimensional.jl")
end
