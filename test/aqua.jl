using Test
using Aqua

# Note: OpenNorm is not a proper Julia module yet, so we skip Aqua tests
# that require a module. Once the project is restructured as a proper package,
# uncomment and update these tests.

@testset "Aqua.jl Code Quality Tests" begin
    @testset "Method ambiguities" begin
        # Test for method ambiguities in Base and Core
        Aqua.test_ambiguities([Base, Core])
    end
    
    # The following tests require a proper Julia module/package structure
    # Uncomment when OpenNorm is restructured as a package:
    
    # @testset "Unbound type parameters" begin
    #     Aqua.test_unbound_args(OpenNorm)
    # end
    
    # @testset "Undefined exports" begin
    #     Aqua.test_undefined_exports(OpenNorm)
    # end
    
    # @testset "Project structure" begin
    #     Aqua.test_project_extras(OpenNorm)
    #     Aqua.test_stale_deps(OpenNorm)
    # end
    
    # @testset "Persistent tasks" begin
    #     Aqua.test_persistent_tasks(OpenNorm)
    # end
end
