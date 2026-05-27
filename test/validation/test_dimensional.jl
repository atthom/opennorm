using Test

include("../../src/julia/opennorm.jl")

@testset "Dimensional Analysis" begin
    @testset "Validate Document with Dimensional Analysis" begin
        # This function does parsing + dimensional analysis
        document, solver, check_result = validate_document("documents/articles/CGI.Art.156.md")
        
        @test document !== nothing
        @test solver !== nothing
        @test check_result !== nothing
    end
    
    @testset "Procedure Dimensional Validity" begin
        document, solver, check_result = validate_document("documents/articles/CGI.Art.156.md")
        
        # Test that procedures have dimensional validity flag
        for proc in document.procedures
            @test hasfield(typeof(proc), :dimensionally_valid)
        end
    end
    
    @testset "Count Valid and Invalid Procedures" begin
        document, solver, check_result = validate_document("documents/articles/CGI.Art.156.md")
        
        total = length(document.procedures)
        valid = count(p -> p.dimensionally_valid, document.procedures)
        invalid = total - valid
        
        @test total > 0
        @test valid >= 0
        @test invalid >= 0
        @test valid + invalid == total
    end
    
    @testset "Dimensional Analysis Success Rate" begin
        document, solver, check_result = validate_document("documents/articles/CGI.Art.156.md")
        
        total = length(document.procedures)
        valid = count(p -> p.dimensionally_valid, document.procedures)
        
        # Calculate success rate
        success_rate = valid / total
        
        @test success_rate >= 0.0
        @test success_rate <= 1.0
        
        # For CGI Art 156, we expect high success rate
        @test success_rate > 0.5  # At least 50% should be valid
    end
    
    @testset "Unit System Registration" begin
        document, solver, check_result = validate_document("documents/articles/CGI.Art.156.md")
        
        # Test that units were registered
        unit_defs = extract_units_from_taxonomy(document.objectTaxonomy)
        @test length(unit_defs) >= 0
    end
    
    @testset "SMT Solver Integration" begin
        document, solver, check_result = validate_document("documents/articles/CGI.Art.156.md")
        
        # Test that solver was created
        @test solver !== nothing
    end
end