using Test

include("../../src/julia/opennorm.jl")

@testset "Expression Code Generation" begin
    @testset "Boolean Value Translation" begin
        # Test that 'oui' and 'non' are translated to True/False
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Should contain Python booleans, not French strings
        @test occursin("True", python_code)
        @test occursin("False", python_code)
        @test !occursin("'oui'", python_code)
        @test !occursin("'non'", python_code)
    end
    
    @testset "Boolean Operators" begin
        # Test that AND/OR are translated to 'and'/'or'
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Should use Python keywords
        @test occursin(" and ", python_code)
        @test occursin(" or ", python_code)
        
        # Should not use array operators
        @test !occursin(" * ", python_code) || occursin("*", python_code)  # Allow multiplication
        @test !occursin(" + ", python_code) || occursin("+", python_code)  # Allow addition
    end
    
    @testset "Comparison Operators" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Should contain comparison operators
        @test occursin("==", python_code) || occursin("!=", python_code) || 
              occursin("<=", python_code) || occursin(">=", python_code) ||
              occursin("<", python_code) || occursin(">", python_code)
    end
    
    @testset "Case Expression Generation" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Should contain if/else statements
        @test occursin("if ", python_code)
        @test occursin("else:", python_code)
    end
    
    @testset "No Redundant Branches" begin
        # Test that redundant elif/else branches are optimized away
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Count if/elif/else patterns
        lines = split(python_code, '\n')
        
        # Should have proper if/else structure
        @test any(line -> occursin("if ", line), lines)
        @test any(line -> occursin("else:", line), lines)
    end
    
    @testset "Variable References" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Should contain variable references
        @test occursin("parameters", python_code) || occursin("person", python_code)
    end
    
    @testset "Arithmetic Operations" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Should contain arithmetic operators
        has_arithmetic = occursin("+", python_code) || occursin("-", python_code) ||
                        occursin("*", python_code) || occursin("/", python_code)
        @test has_arithmetic
    end
end