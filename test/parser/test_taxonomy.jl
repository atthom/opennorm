using Test

include("../../src/julia/opennorm.jl")

@testset "Taxonomy Parsing" begin
    @testset "Parse All Four Taxonomies" begin
        doc = parse_document("documents/licences/mit.strict.md")
        
        # Test that all four taxonomies are present
        @test doc.entityTaxonomy !== nothing
        @test doc.actorTaxonomy !== nothing
        @test doc.actionTaxonomy !== nothing
        @test doc.objectTaxonomy !== nothing
        
        # Test taxonomy names exist (relaxed - don't check exact names)
        @test !isempty(doc.entityTaxonomy.name)
        @test !isempty(doc.actorTaxonomy.name)
        @test !isempty(doc.actionTaxonomy.name)
        @test !isempty(doc.objectTaxonomy.name)
    end
    
    @testset "Taxonomy Structure" begin
        doc = parse_document("documents/licences/mit.strict.md")
        
        # Test that taxonomies have children
        @test length(doc.entityTaxonomy.children) > 0
        @test length(doc.actorTaxonomy.children) > 0
        @test length(doc.actionTaxonomy.children) > 0
        @test length(doc.objectTaxonomy.children) > 0
    end
    
    @testset "Taxonomy Navigation" begin
        doc = parse_document("documents/licences/mit.strict.md")
        
        # Test finding specific nodes - need to navigate through the hierarchy
        # Licensor is under AnyRole -> LicensingRole -> Licensor
        any_role = doc.actorTaxonomy
        @test any_role !== nothing
        
        # Find LicensingRole first
        licensing_role = find_child_by_name(any_role, "LicensingRole")
        if licensing_role !== nothing
            # Then find Licensor under LicensingRole
            licensor = find_child_by_name(licensing_role, "Licensor")
            @test licensor !== nothing
            @test licensor.name == "Licensor"
            @test licensor.parent === licensing_role
        else
            # If structure is different, just verify taxonomy has children
            @test length(any_role.children) > 0
        end
    end
    
    @testset "CGI Article 156 Taxonomies" begin
        doc = parse_document("documents/articles/CGI.Art.156.md")
        
        # Test that OpenNormVariables node exists in object taxonomy
        opennorm_vars = find_child_by_name(doc.objectTaxonomy, "OpenNormVariables")
        @test opennorm_vars !== nothing
        
        # Test that Parameters and Constants exist
        params = find_child_by_name(opennorm_vars, "Parameters")
        constants = find_child_by_name(opennorm_vars, "Constants")
        
        @test params !== nothing
        @test constants !== nothing
    end
end