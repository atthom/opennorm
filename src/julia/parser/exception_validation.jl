# Exception Validation
# Validates exception relationships between norms

"""
Compute the expected position for an exception based on parent's position and depth.
For odd depth exceptions (depth 1, 3, 5...), apply O (opposite).
For even depth exceptions (depth 2, 4, 6...), keep same position as root.
"""
function compute_exception_position(parent_norm::Norm)
    if parent_norm.depth % 2 == 0
        # Even depth parent → odd depth child → opposite position
        return O(parent_norm.Hohfeld)
    else
        # Odd depth parent → even depth child → same as root
        # This maintains the alternating pattern
        return parent_norm.Hohfeld
    end
end

"""
Validate all exception relationships in a set of norms.
Checks:
1. Parent exists (E050-1)
2. Depth is parent.depth + 1 (E050-2)
3. Position is correctly computed from parent (E050-3)
4. Same relationship (actor/action/object/counterparty) as parent (E050-4)
5. Conditions differ from parent (E051)
"""
function validate_exceptions(norms::Vector{Norm})
    # Build ref_id → norm lookup
    norm_map = Dict(n.ref_id => n for n in norms)
    
    errors = []
    warnings = []
    
    for norm in norms
        if !isnothing(norm.excepts)
            # Check parent exists (E050-1)
            if !haskey(norm_map, norm.excepts)
                push!(errors, "E050-1: Exception $(norm.ref_id) references non-existent parent: $(norm.excepts)")
                continue  # Can't validate further without parent
            end
            parent = norm_map[norm.excepts]
            
            # Validate depth (E050-2)
            expected_depth = parent.depth + 1
            if norm.depth != expected_depth
                push!(errors, "E050-2: Exception $(norm.ref_id) has depth $(norm.depth), " *
                      "expected $(expected_depth) (parent $(norm.excepts) depth + 1)")
            end
            
            # Validate position relationship (E050-3)
            expected_position = compute_exception_position(parent)
            if norm.Hohfeld != expected_position
                depth_type = parent.depth % 2 == 0 ? "opposite" : "same"
                push!(errors, "E050-3: Exception $(norm.ref_id) has position $(position_name(norm.Hohfeld)), " *
                      "but should have $(position_name(expected_position)) " *
                      "($(depth_type) as parent $(norm.excepts) with $(position_name(parent.Hohfeld)))")
            end
            
            # Validate same relationship (E050-4)
            if !same_norm_relationship(norm, parent)
                push!(errors, "E050-4: Exception $(norm.ref_id) must have same actor/action/object/counterparty as parent $(norm.excepts). " *
                      "Found: actor=$(norm.actor.name) vs $(parent.actor.name), " *
                      "action=$(norm.action.name) vs $(parent.action.name), " *
                      "object=$(norm.object.name) vs $(parent.object.name), " *
                      "counterparty=$(norm.counterparty.name) vs $(parent.counterparty.name)")
            end
            
            # Validate condition differentiation (E051)
            if same_conditions(norm, parent)
                push!(errors, "E051: Exception $(norm.ref_id) has identical conditions to parent $(norm.excepts). " *
                      "An exception must have at least one different condition to be meaningful.")
            end
            
            # Check if exception has no conditions at all
            if isempty(norm.conditions) && isempty(parent.conditions)
                push!(warnings, "W051: Exception $(norm.ref_id) and parent $(norm.excepts) both have no conditions. " *
                      "Consider adding conditions to differentiate when the exception applies.")
            end
        end
    end
    
    # Report errors and warnings
    if !isempty(errors)
        error_msg = "Exception validation failed:\n" * join(errors, "\n")
        error(error_msg)
    end
    
    if !isempty(warnings)
        println("Exception validation warnings:")
        for warning in warnings
            println("  ", warning)
        end
    end
    
    return true
end

"""
Check for circular exception dependencies.
An exception cannot directly or indirectly except itself.
"""
function check_circular_exceptions(norms::Vector{Norm})
    norm_map = Dict(n.ref_id => n for n in norms)
    
    for norm in norms
        if !isnothing(norm.excepts)
            visited = Set{String}()
            current = norm.ref_id
            
            # Follow the exception chain
            while !isnothing(current) && haskey(norm_map, current)
                if current in visited
                    error("Circular exception dependency detected involving $(norm.ref_id)")
                end
                push!(visited, current)
                
                current_norm = norm_map[current]
                current = current_norm.excepts
            end
        end
    end
    
    return true
end