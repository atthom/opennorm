using Test

include("../../src/julia/opennorm.jl")

@testset "OpenFisca Code Generation" begin
    @testset "Generate Complete Python Module" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Test that code was generated
        @test !isempty(python_code)
        @test length(split(python_code, '\n')) > 100  # Should be substantial
    end
    
    @testset "Python Imports" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Should contain OpenFisca imports
        @test occursin("from openfisca_core", python_code) || 
              occursin("import openfisca_core", python_code)
    end
    
    @testset "Variable Class Generation" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Should contain Variable class definitions
        @test occursin("class ", python_code)
        @test occursin("(Variable):", python_code)
    end
    
    @testset "Formula Method Generation" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Should contain formula methods
        @test occursin("def formula(", python_code)
        @test occursin("return ", python_code)
    end
    
    @testset "Correct Number of Classes" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Count class definitions
        class_count = length(collect(eachmatch(r"^class \w+\(Variable\):", python_code, overlap=false)))
        
        # Should generate multiple classes (one per procedure)
        @test class_count > 20  # We know CGI Art 156 should have 26 classes
    end
    
    @testset "Valid Python Syntax" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Test basic Python syntax elements
        @test occursin("def ", python_code)
        @test occursin("class ", python_code)
        @test occursin("return ", python_code)
        
        # Should have proper indentation (4 spaces)
        lines = split(python_code, '\n')
        indented_lines = filter(line -> startswith(line, "    "), lines)
        @test length(indented_lines) > 0
    end
    
    @testset "Value Type Definitions" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Should contain value_type definitions
        @test occursin("value_type", python_code)
    end
    
    @testset "Entity Definitions" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Should contain entity definitions
        @test occursin("entity", python_code)
    end
    
    @testset "Definition Period" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Should contain definition_period
        @test occursin("definition_period", python_code)
    end
end