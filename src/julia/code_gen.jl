# Backend dispatch via multiple dispatch
abstract type Backend end
struct OpenFiscaBackend <: Backend end
struct SMT2Backend <: Backend end
struct ReportBackend <: Backend end

# Each backend implements generate for each IR node type
function generate(::OpenFiscaBackend, rule::Ruling)::Union{String, Nothing}
    rule.skipped && return nothing  # excluded rules generate nothing
    
    """
    class $(to_snake_case(rule.ref_id))(Variable):
        value_type = bool
        entity = $(resolve_entity(rule.actor))
        definition_period = $(resolve_period(rule.temporal))
        label = "$(rule.ref_id)"
        reference = "opennorm://$(rule.ref_id)"
        
        def formula(person, period, parameters):
            $(generate_formula(rule.conditions))
    """
end

function generate(::ReportBackend, rule::Ruling)::String
    status = rule.skipped ? "⚠️ SKIPPED" : "✅ Verified"
    """
    | `#$(rule.ref_id)` | $(position_name(rule.position)) | $(status) |
    """
end

# Running all backends
function compile(ir::DocumentIR)
    s = to_smt(ir)
    result = check(s)
    
    if result == Z3.unsat
        core = unsat_core(s)
        return generate_conflict_report(ir, core)
    end
    
    # SAT — generate all backends
    openfisca_files = [generate(OpenFiscaBackend(), n) 
                       for n in ir.rulings]
    report = generate_report(ir, s)
    
    (openfisca=filter(!isnothing, openfisca_files), 
     report=report)
end