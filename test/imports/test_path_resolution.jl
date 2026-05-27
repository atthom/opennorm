using Test

include("../../src/julia/opennorm.jl")

@testset "Import Path Resolution" begin
    @testset "Stdlib Path Resolution" begin
        project_root = pwd()
        base_dir = joinpath(project_root, "documents/licences")
        
        # Test resolving stdlib path
        full_path, version = resolve_import_path(
            "stdlib/frameworks/universal/core",
            base_dir,
            project_root
        )
        
        @test isfile(full_path)
        @test endswith(full_path, ".md")
        @test occursin("stdlib", full_path)
    end
    
    @testset "Relative Path Resolution" begin
        project_root = pwd()
        base_dir = joinpath(project_root, "documents/articles")
        
        # Test resolving relative path
        full_path, version = resolve_import_path(
            "../licences/mit.strict",
            base_dir,
            project_root
        )
        
        @test isfile(full_path)
        @test occursin("mit.strict.md", full_path)
    end
    
    @testset "Absolute Path Resolution" begin
        project_root = pwd()
        base_dir = joinpath(project_root, "documents")
        
        # Test resolving absolute path from project root
        full_path, version = resolve_import_path(
            "/documents/licences/mit.strict",
            base_dir,
            project_root
        )
        
        @test isfile(full_path)
    end
    
    @testset "Path with Version" begin
        project_root = pwd()
        base_dir = joinpath(project_root, "documents/licences")
        
        # Test path with version specifier
        full_path, version = resolve_import_path(
            "stdlib/frameworks/universal/core@2.0",
            base_dir,
            project_root
        )
        
        @test isfile(full_path)
        @test version == "2.0"
    end
    
    @testset "Invalid Path Error" begin
        project_root = pwd()
        base_dir = joinpath(project_root, "documents")
        
        # Test that invalid path throws error
        @test_throws ImportPathError resolve_import_path(
            "nonexistent/path/to/file",
            base_dir,
            project_root
        )
    end
end