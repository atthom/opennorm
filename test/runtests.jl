using Test
using Pkg

# Activate the project environment
Pkg.activate(".")

# Run Aqua.jl code quality tests first
include("aqua.jl")

# Run parser tests
@testset "Parser Tests" begin
    include("parser/test_manifest.jl")
    include("parser/test_taxonomy.jl")
    include("parser/test_procedures.jl")
    include("parser/test_rulings.jl")
    include("parser/test_translation.jl")
end

# Run import system tests
@testset "Import System Tests" begin
    include("imports/test_all.jl")
end

# Run code generation tests
@testset "Code Generation Tests" begin
    include("codegen/test_all.jl")
end

# Run validation tests
@testset "Validation Tests" begin
    include("validation/test_all.jl")
end

# Run integration tests
@testset "Integration Tests" begin
    include("integration/test_all.jl")
end
