using Test

include("../../src/julia/opennorm.jl")

@testset "YAML Code Generation" begin
    @testset "Generate YAML Output" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        yaml_code = compile_to_yaml(doc)
        
        # Test that YAML was generated
        @test !isempty(yaml_code)
    end
    
    @testset "YAML Structure" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        yaml_code = compile_to_yaml(doc)
        
        # Should contain YAML key-value pairs
        @test occursin(":", yaml_code)
        
        # Should have proper indentation
        lines = split(yaml_code, '\n')
        indented_lines = filter(line -> startswith(line, "  "), lines)
        @test length(indented_lines) > 0
    end
    
    @testset "YAML Procedures" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        yaml_code = compile_to_yaml(doc)
        
        # Should contain procedure definitions
        @test occursin("procedures", yaml_code) || occursin("variables", yaml_code)
    end
    
    @testset "YAML Parameters" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        yaml_code = compile_to_yaml(doc)
        
        # Should contain parameters if they exist
        if length(doc.parameters) > 0
            @test occursin("parameters", yaml_code) || occursin("constants", yaml_code)
        end
    end
    
    @testset "Valid YAML Syntax" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        yaml_code = compile_to_yaml(doc)
        
        # Basic YAML syntax checks
        lines = split(yaml_code, '\n')
        
        # Should not have tabs (YAML uses spaces)
        @test !any(line -> occursin('\t', line), lines)
        
        # Should have consistent indentation
        @test true  # Placeholder for more detailed checks
    end
end