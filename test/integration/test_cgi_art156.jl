using Test

include("../../src/julia/opennorm.jl")

@testset "CGI Article 156 Specific Tests" begin
    @testset "Parse CGI Article 156" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        
        @test doc !== nothing
        @test doc.manifest.title !== nothing
        @test occursin("156", doc.manifest.title) || occursin("CGI", doc.manifest.title)
    end
    
    @testset "CGI Art 156 Procedures Count" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        
        # Should have 26 procedures
        @test length(doc.procedures) == 26
    end
    
    @testset "CGI Art 156 Procedure Names" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        
        # Check for some known procedure names
        proc_names = [p.name for p in doc.procedures]
        
        # Should contain deficit-related procedures
        has_deficit_procs = any(name -> occursin("Deficit", name) || occursin("Déficit", name), proc_names)
        @test has_deficit_procs
    end
    
    @testset "CGI Art 156 OpenFisca Generation" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Should generate 26 Variable classes
        class_count = length(collect(eachmatch(r"^class \w+\(Variable\):", python_code, overlap=false)))
        @test class_count == 26
    end
    
    @testset "CGI Art 156 Boolean Values" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Should use Python booleans
        @test occursin("True", python_code)
        @test occursin("False", python_code)
        @test !occursin("'oui'", python_code)
        @test !occursin("'non'", python_code)
    end
    
    @testset "CGI Art 156 Boolean Operators" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Should use Python boolean operators
        @test occursin(" and ", python_code)
        @test occursin(" or ", python_code)
    end
    
    @testset "CGI Art 156 Parameters Extraction" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        
        # Should have parameters
        @test length(doc.parameters) > 0
        
        # Build type environment
        type_env = build_type_environment(doc.objectTaxonomy)
        @test length(type_env) > 0
    end
    
    @testset "CGI Art 156 Dimensional Analysis" begin
        document, solver, check_result = validate_document("documents/articles/CGI.Art.156.md")
        
        total = length(document.procedures)
        valid = count(p -> p.dimensionally_valid, document.procedures)
        
        # Should have high success rate
        success_rate = valid / total
        @test success_rate > 0.5
    end
    
    @testset "CGI Art 156 Code Quality" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        python_code = compile_to_openfisca(doc)
        
        # Should be substantial code
        lines = split(python_code, '\n')
        @test length(lines) > 300
        
        # Should have proper structure
        @test occursin("from openfisca_core", python_code)
        @test occursin("def formula(", python_code)
        @test occursin("return ", python_code)
    end
end