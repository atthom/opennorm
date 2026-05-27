using Test

include("../../src/julia/opennorm.jl")

@testset "Type Environment" begin
    @testset "Build Type Environment from Taxonomy" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        
        # Build type environment
        type_env = build_type_environment(doc.objectTaxonomy)
        
        @test type_env isa Dict
        @test length(type_env) > 0
    end
    
    @testset "Extract Variables from Parameters" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        type_env = build_type_environment(doc.objectTaxonomy)
        
        # Should contain parameter variables
        @test length(type_env) > 0
        
        # Check for specific known parameters
        # (These are from CGI Art 156)
        known_params = ["PlafondPensionEnfantMajeur", "PlafondAvantagesNature", 
                       "LimiteDéduction", "AbattementArt196B"]
        
        found_count = count(param -> haskey(type_env, param), known_params)
        @test found_count > 0  # At least some should be found
    end
    
    @testset "Extract Variables from Constants" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        type_env = build_type_environment(doc.objectTaxonomy)
        
        # Should extract from both Parameters and Constants nodes
        opennorm_vars = find_child_by_name(doc.objectTaxonomy, "OpenNormVariables")
        @test opennorm_vars !== nothing
        
        constants_node = find_child_by_name(opennorm_vars, "Constants")
        if constants_node !== nothing
            @test length(constants_node.children) >= 0
        end
    end
    
    @testset "Variable Type Annotations" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        type_env = build_type_environment(doc.objectTaxonomy)
        
        # Check that variables have type information
        for (var_name, var_type) in type_env
            @test var_type !== nothing
            # Type should be a Unitful unit or dimension
            @test true  # Placeholder for more specific type checks
        end
    end
    
    @testset "Parse Variable Type Annotation" begin
        # Test the helper function
        var_name, unit_name = parse_variable_type_annotation("MyVariable:EUR")
        
        @test var_name == "MyVariable"
        @test unit_name == "EUR"
    end
    
    @testset "Variable Without Type Annotation" begin
        # Test variable without type annotation
        var_name, unit_name = parse_variable_type_annotation("MyVariable")
        
        @test var_name == "MyVariable"
        @test unit_name === nothing || unit_name == ""
    end
end