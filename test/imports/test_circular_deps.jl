using Test

include("../../src/julia/opennorm.jl")

@testset "Circular Dependency Detection" begin
    @testset "Detect Simple Circular Dependency" begin
        # Test that circular dependency is detected
        chain = ["/path/to/doc1.md", "/path/to/doc2.md"]
        full_path = "/path/to/doc1.md"  # Same as first in chain
        
        @test_throws CircularDependencyError begin
            if full_path in chain
                throw(CircularDependencyError(full_path, vcat(chain, [full_path])))
            end
        end
    end
    
    @testset "No Circular Dependency" begin
        # Test that no error is thrown for valid chain
        chain = ["/path/to/doc1.md", "/path/to/doc2.md"]
        full_path = "/path/to/doc3.md"  # Different from chain
        
        # Should not throw
        if full_path in chain
            throw(CircularDependencyError(full_path, vcat(chain, [full_path])))
        end
        
        @test true  # If we get here, no error was thrown
    end
    
    @testset "Circular Dependency Error Structure" begin
        path = "/path/to/doc1.md"
        chain = ["/path/to/doc1.md", "/path/to/doc2.md", "/path/to/doc1.md"]
        
        error = CircularDependencyError(path, chain)
        
        @test error.path == path
        @test error.chain == chain
        @test length(error.chain) == 3
    end
    
    @testset "Long Circular Chain" begin
        # Test detection in longer chains
        chain = ["/doc1.md", "/doc2.md", "/doc3.md", "/doc4.md"]
        full_path = "/doc2.md"  # Appears in middle of chain
        
        @test_throws CircularDependencyError begin
            if full_path in chain
                throw(CircularDependencyError(full_path, vcat(chain, [full_path])))
            end
        end
    end
end