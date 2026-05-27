using Test

include("../../src/julia/opennorm.jl")

@testset "Full Pipeline Integration" begin
    @testset "Parse → Validate → Generate OpenFisca" begin
        # Full pipeline: parse document, validate, generate code
        doc_path = "documents/articles/CGI.Art.156.md"
        
        # Step 1: Parse
        document = parse_document(doc_path)
        @test document !== nothing
        @test length(document.procedures) > 0
        
        # Step 2: Validate (with dimensional analysis)
        document, solver, check_result = validate_document(doc_path)
        @test document !== nothing
        @test solver !== nothing
        
        # Step 3: Generate OpenFisca code
        python_code = compile_to_openfisca(document)
        @test !isempty(python_code)
        @test occursin("class ", python_code)
    end
    
    @testset "Parse → Generate YAML" begin
        doc_path = "documents/articles/CGI.Art.156.md"
        
        # Parse and generate YAML
        document = parse_document(doc_path)
        yaml_code = compile_to_yaml(document)
        
        @test !isempty(yaml_code)
        @test occursin(":", yaml_code)
    end
    
    @testset "Document with Imports Pipeline" begin
        # Test full pipeline with a document that has imports
        doc_path = "test_with_imports.md"
        
        if isfile(doc_path)
            document = parse_document(doc_path)
            
            @test document !== nothing
            @test length(document.manifest.imports) > 0
            
            # Test that imported taxonomies were merged
            @test document.entityTaxonomy !== nothing
            @test document.actorTaxonomy !== nothing
        end
    end
    
    @testset "MIT License Full Pipeline" begin
        doc_path = "documents/licences/mit.strict.md"
        
        # Parse
        document = parse_document(doc_path)
        @test document !== nothing
        
        # Check all components
        @test document.manifest !== nothing
        @test document.entityTaxonomy !== nothing
        @test document.actorTaxonomy !== nothing
        @test document.actionTaxonomy !== nothing
        @test document.objectTaxonomy !== nothing
        @test length(document.rulings) > 0
    end
    
    @testset "Error Handling in Pipeline" begin
        # Test that pipeline handles errors gracefully
        @test_throws Exception parse_document("nonexistent_file.md")
    end
    
    @testset "Multiple Documents Pipeline" begin
        # Test processing multiple documents
        docs = [
            "documents/licences/mit.strict.md",
            "documents/articles/CGI.Art.156.md"
        ]
        
        for doc_path in docs
            if isfile(doc_path)
                document = parse_document(doc_path)
                @test document !== nothing
                @test document.manifest !== nothing
            end
        end
    end
end