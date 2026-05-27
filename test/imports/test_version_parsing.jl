using Test

include("../../src/julia/opennorm.jl")

@testset "Version Parsing" begin
    @testset "Parse Import with Version" begin
        path, version = parse_import_spec("stdlib/frameworks/universal/core@2.0")
        
        @test path == "stdlib/frameworks/universal/core"
        @test version == "2.0"
    end
    
    @testset "Parse Import without Version" begin
        path, version = parse_import_spec("stdlib/frameworks/universal/core")
        
        @test path == "stdlib/frameworks/universal/core"
        @test version === nothing
    end
    
    @testset "Parse Import with Complex Version" begin
        path, version = parse_import_spec("stdlib/frameworks/universal/core@1.2.3")
        
        @test path == "stdlib/frameworks/universal/core"
        @test version == "1.2.3"
    end
    
    @testset "Parse Import with Relative Path and Version" begin
        path, version = parse_import_spec("../other/document@3.0")
        
        @test path == "../other/document"
        @test version == "3.0"
    end
    
    @testset "Multiple @ Symbols" begin
        # Test that only the last @ is treated as version separator
        path, version = parse_import_spec("path/with@symbol/file@1.0")
        
        @test path == "path/with@symbol/file"
        @test version == "1.0"
    end
end