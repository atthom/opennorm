# OpenNorm Test Suite

This directory contains the comprehensive test suite for the OpenNorm project, using Julia's Test.jl framework and Aqua.jl for code quality checks.

## Running Tests

To run the entire test suite:

```bash
julia --project=. test/runtests.jl
```

To run specific test categories:

```bash
# Parser tests only
julia --project=. -e 'using Test; include("test/parser/test_manifest.jl")'

# Code generation tests only
julia --project=. -e 'using Test; include("test/codegen/test_openfisca.jl")'
```

## Test Structure

```
test/
├── runtests.jl              # Main test runner
├── aqua.jl                  # Aqua.jl code quality tests
├── parser/                  # Parser tests
│   ├── test_manifest.jl     # Manifest parsing
│   ├── test_taxonomy.jl     # Taxonomy parsing
│   ├── test_procedures.jl   # Procedure parsing
│   ├── test_rulings.jl      # Ruling parsing
│   └── test_translation.jl  # Translation system
├── imports/                 # Import system tests
│   ├── test_path_resolution.jl
│   ├── test_version_parsing.jl
│   ├── test_circular_deps.jl
│   └── test_taxonomy_merge.jl
├── codegen/                 # Code generation tests
│   ├── test_expressions.jl  # Expression code generation
│   ├── test_openfisca.jl    # OpenFisca Python generation
│   └── test_yaml.jl         # YAML generation
├── validation/              # Validation tests
│   ├── test_type_env.jl     # Type environment
│   └── test_dimensional.jl  # Dimensional analysis
└── integration/             # Integration tests
    ├── test_full_pipeline.jl
    └── test_cgi_art156.jl
```

## Test Categories

### 1. Aqua.jl Code Quality Tests
- Method ambiguities
- Unbound type parameters
- Undefined exports
- Project structure consistency
- Persistent tasks

### 2. Parser Tests
- Manifest parsing and validation
- Taxonomy structure and navigation
- Procedure extraction from operational layer
- Ruling parsing with Hohfeldian relations
- Translation system (French to English)

### 3. Import System Tests
- Path resolution (stdlib, relative, absolute)
- Version parsing
- Circular dependency detection
- Taxonomy merging and conflict detection

### 4. Code Generation Tests
- Expression code generation (booleans, operators)
- OpenFisca Python module generation
- YAML output generation

### 5. Validation Tests
- Type environment building
- Dimensional analysis
- SMT solver integration

### 6. Integration Tests
- Full pipeline (parse → validate → generate)
- CGI Article 156 specific tests
- Multi-document processing

## Test Conventions

- All tests use `@testset` for organization
- Tests use `@test` for assertions
- Error cases use `@test_throws`
- Tests are self-contained and can run independently
- Test files include the main module with `include("../../src/julia/opennorm.jl")`

## Adding New Tests

1. Create a new test file in the appropriate category directory
2. Follow the naming convention: `test_<feature>.jl`
3. Use `@testset` to organize related tests
4. Add the test file to `runtests.jl` in the appropriate section
5. Ensure tests are deterministic and don't depend on external state

## CI/CD Integration

The test suite is designed to be CI/CD friendly:
- Exit code 0 on success, non-zero on failure
- Clear test output with pass/fail indicators
- Reasonable execution time
- No external dependencies beyond Julia packages

## Troubleshooting

If tests fail:
1. Check that you're in the project root directory
2. Ensure all dependencies are installed: `julia --project=. -e 'using Pkg; Pkg.instantiate()'`
3. Check for file path issues (tests assume execution from project root)
4. Review test output for specific failure messages