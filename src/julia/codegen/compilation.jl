# Top-level Compilation Functions
# Orchestrates code generation for complete documents

# ============================================================================
# OPENFISCA COMPILATION
# ============================================================================

"""
    code_gen(::OpenFiscaBackend, ir::DocumentIR)::String

Generate complete OpenFisca Python file from DocumentIR.
This is the top-level compilation function that orchestrates
generation of all components (parameters, input variables, procedures).

# Arguments
- `backend::OpenFiscaBackend`: The OpenFisca backend instance
- `ir::DocumentIR`: The document IR to compile

# Returns
- `String`: Complete Python file content with all Variable classes
"""
function code_gen(backend::OpenFiscaBackend, ir::DocumentIR)::String
    # Header with imports
    header = """
# -*- coding: utf-8 -*-
# Generated from OpenNorm document
# Title: $(ir.manifest.title)
# Package: $(ir.manifest.package)
# Version: $(ir.manifest.version)
# Status: $(ir.manifest.status)

from openfisca_core.model_api import *
from openfisca_france.model.base import *

"""
    
    # Generate code for all components using code_gen dispatch
    
    # Parameters first (constants)
    param_code = [code_gen(backend, p) for p in ir.parameters]
    
    # Input variables
    input_code = [code_gen(backend, v) for v in ir.input_variables]
    
    # Computed variables (procedures)
    proc_code = [code_gen(backend, p) for p in ir.procedures]
    
    # Combine all (filter out empty strings)
    all_code = filter(!isempty, vcat(param_code, input_code, proc_code))
    
    return header * join(all_code, "\n\n")
end

# ============================================================================
# PUBLIC API
# ============================================================================

"""
    compile_to_openfisca(ir::DocumentIR)::String

Main compilation function - generates OpenFisca code.
Extracts parameters from taxonomy and adds them as input variables.

# Arguments
- `ir::DocumentIR`: The document IR to compile

# Returns
- `String`: Complete Python file content with all Variable classes
"""
function compile_to_openfisca(ir::DocumentIR)::String
    # Extract parameters from taxonomy and add as input variables
    extracted_params = extract_parameters_from_taxonomy(ir.objectTaxonomy)
    
    # Create new DocumentIR with extracted parameters as input variables
    ir_with_inputs = DocumentIR(
        manifest=ir.manifest,
        entityTaxonomy=ir.entityTaxonomy,
        actorTaxonomy=ir.actorTaxonomy,
        actionTaxonomy=ir.actionTaxonomy,
        objectTaxonomy=ir.objectTaxonomy,
        norms=ir.norms,
        procedures=ir.procedures,
        parameters=ir.parameters,
        input_variables=vcat(ir.input_variables, extracted_params)
    )
    
    backend = OpenFiscaBackend()
    return code_gen(backend, ir_with_inputs)
end

"""
Extract Parameters from the Object taxonomy and convert to InputVariables.
Returns a vector of InputVariable structs.
"""
function extract_parameters_from_taxonomy(object_taxonomy)::Vector{InputVariable}
    input_vars = InputVariable[]
    
    # Find OpenNormVariables node
    opennorm_vars = find_child_by_name(object_taxonomy, "OpenNormVariables")
    if opennorm_vars === nothing
        return input_vars
    end
    
    # Find Parameters node
    params_node = find_child_by_name(opennorm_vars, "Parameters")
    if params_node === nothing
        return input_vars
    end
    
    # Extract each parameter
    for param_node in params_node.children
        # Parse "Name = value Unit" format
        text = param_node.name
        
        # Match pattern: "Name = value Unit"
        m = match(r"^([^=]+?)\s*=\s*(.+?)\s+([A-Za-zÀ-ÿ/]+)$", text)
        if m !== nothing
            name = strip(m.captures[1])
            value = strip(m.captures[2])
            unit = strip(m.captures[3])
            
            # Create InputVariable (positional arguments, not keyword arguments)
            input_var = InputVariable(name, unit, nothing)
            push!(input_vars, input_var)
        end
    end
    
    return input_vars
end