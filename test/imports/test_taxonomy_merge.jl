using Test

include("../../src/julia/opennorm.jl")

@testset "Taxonomy Merging" begin
    @testset "Merge Compatible Taxonomies" begin
        # Create two taxonomies with same structure
        base = Taxon(Role, "Role")
        licensor1 = Taxon(base, "Licensor")
        
        imported = Taxon(Role, "Role")
        licensor2 = Taxon(imported, "Licensor")  # Same parent!
        
        # Should merge successfully
        result = merge_taxonomies(base, imported, "Role")
        
        @test result !== nothing
        @test result.name == "Role"
        @test length(result.children) > 0
    end
    
    @testset "Detect Taxonomy Conflict" begin
        # Create two taxonomies with conflicting terms
        base = Taxon(Role, "Role")
        licensor1 = Taxon(base, "Licensor")
        
        imported = Taxon(Role, "Role")
        rights_holder = Taxon(imported, "RightsHolder")
        licensor2 = Taxon(rights_holder, "Licensor")  # Different parent!
        
        # Should throw TaxonomyMergeConflict
        @test_throws TaxonomyMergeConflict merge_taxonomies(base, imported, "Role")
    end
    
    @testset "Taxonomy Merge Conflict Error Structure" begin
        term = "Licensor"
        taxonomy_type = "Role"
        locations = ["base:Role/Licensor", "imported:Role/RightsHolder/Licensor"]
        
        error = TaxonomyMergeConflict(term, taxonomy_type, locations)
        
        @test error.term == term
        @test error.taxonomy_type == taxonomy_type
        @test error.locations == locations
    end
    
    @testset "Merge Empty Taxonomies" begin
        # Create two empty taxonomies
        base = Taxon(Role, "Role")
        imported = Taxon(Role, "Role")
        
        # Should merge successfully
        result = merge_taxonomies(base, imported, "Role")
        
        @test result !== nothing
        @test result.name == "Role"
        @test length(result.children) == 0
    end
    
    @testset "Merge with Additional Terms" begin
        # Base has some terms, imported has additional terms
        base = Taxon(Role, "Role")
        licensor = Taxon(base, "Licensor")
        
        imported = Taxon(Role, "Role")
        licensor2 = Taxon(imported, "Licensor")
        licensee = Taxon(imported, "Licensee")  # Additional term
        
        # Should merge successfully and include both terms
        result = merge_taxonomies(base, imported, "Role")
        
        @test result !== nothing
        @test length(result.children) >= 2
    end
    
    @testset "Deep Taxonomy Merge" begin
        # Create taxonomies with multiple levels
        base = Taxon(Role, "Role")
        person = Taxon(base, "Person")
        licensor = Taxon(person, "Licensor")
        
        imported = Taxon(Role, "Role")
        person2 = Taxon(imported, "Person")
        licensor2 = Taxon(person2, "Licensor")
        
        # Should merge successfully
        result = merge_taxonomies(base, imported, "Role")
        
        @test result !== nothing
        @test result.name == "Role"
    end
end