# ============================================================================
# Intermediate Norm Generation
# ============================================================================
# Generates intermediate norms to bridge orphan norms to the grundnorm
# when direct exception relationships would violate Hohfeldian constraints

"""
    find_grundnorm(norms::Vector{Norm})

Find the grundnorm (universal-permission) in the norms vector.
Returns the grundnorm or nothing if not found.
"""
function find_grundnorm(norms::Vector{Norm})
    for norm in norms
        if norm.ref_id == "universal-permission" || 
           contains(lowercase(norm.ref_id), "grundnorm")
            return norm
        end
    end
    return nothing
end

"""
    find_orphan_norms(norms::Vector{Norm}, grundnorm::Norm)

Find norms that are orphaned (not properly connected to the exception hierarchy).
A norm is considered orphaned if:
- excepts === nothing, OR
- excepts references a non-existent norm, OR
- explicitly marked as "exception de grundnorm"
"""
function find_orphan_norms(norms::Vector{Norm}, grundnorm::Norm)
    orphans = Norm[]
    norm_refs = Set(n.ref_id for n in norms)
    
    for norm in norms
        # Skip the grundnorm itself
        if norm.ref_id == grundnorm.ref_id
            continue
        end
        
        # Check if orphaned
        is_orphan = false
        
        if norm.excepts === nothing
            is_orphan = true
        elseif norm.excepts == "grundnorm" || norm.excepts == grundnorm.ref_id
            # Explicitly marked as exception of grundnorm
            is_orphan = true
        elseif !(norm.excepts in norm_refs)
            # References non-existent parent
            @warn "Norm $(norm.ref_id) references non-existent parent: $(norm.excepts)"
            is_orphan = true
        end
        
        if is_orphan
            push!(orphans, norm)
        end
    end
    
    return orphans
end

"""
    calculate_o_path(from_pos::Position, to_pos::Position)

Calculate the Hohfeldian O-path from one position to another.
Returns a vector of intermediate positions needed (excluding from and to).

Since we only have the O() operator (opposite), the path is:
- If to_pos == O(from_pos): Direct connection, no intermediates needed
- If to_pos == from_pos: Need one intermediate at O(from_pos)
- Otherwise: Need one intermediate
"""
function calculate_o_path(from_pos::Position, to_pos::Position)
    # Direct opposite - no intermediate needed
    if to_pos == O(from_pos)
        return Position[]
    end
    
    # Same position - need to go through opposite and back
    if to_pos == from_pos
        return [O(from_pos)]
    end
    
    # Otherwise, need one intermediate at the opposite of from
    return [O(from_pos)]
end

"""
    generate_ref_id(position::Position, orphan::Norm)

Generate a predictable ref_id for an intermediate norm based on:
- The position name (lowercase)
- The action name from the orphan
- The object name from the orphan

Format: generated-{position}-{action}-{object}
"""
function generate_ref_id(position::Position, orphan::Norm)
    pos_name = lowercase(position_name(position))
    action_name = lowercase(replace(orphan.action.name, r"\s+" => "-"))
    object_name = lowercase(replace(orphan.object.name, r"\s+" => "-"))
    
    return "generated-$(pos_name)-$(action_name)-$(object_name)"
end

"""
    create_intermediate_norm(grundnorm::Norm, orphan::Norm, position::Position, depth::Int)

Create a single intermediate norm with the specified position.
Inherits actor, action, object, counterparty from the orphan.
Belongs to the grundnorm's package.
"""
function create_intermediate_norm(grundnorm::Norm, orphan::Norm, position::Position, depth::Int)
    ref_id = generate_ref_id(position, orphan)
    
    return Norm(
        ref_id = ref_id,
        package = grundnorm.package,  # Inherit package from grundnorm
        Hohfeld = position,
        actor = orphan.actor,
        action = orphan.action,
        object = orphan.object,
        counterparty = orphan.counterparty,
        conditions = NormCondition[],  # No conditions on intermediate norms
        overrules = Norm[],
        excepts = nothing,  # Will be set later
        depth = depth,
        skipped = false,
        text = "Generated intermediate norm: $(position_name(position))"
    )
end

"""
    generate_intermediate_norms(norms::Vector{Norm})

Main entry point for intermediate norm generation.
Finds orphan norms and generates intermediate norms to connect them to the grundnorm.

Returns the updated norms vector with generated intermediate norms added.
"""
function generate_intermediate_norms(norms::Vector{Norm})
    # Find the grundnorm
    grundnorm = find_grundnorm(norms)
    if grundnorm === nothing
        @warn "Grundnorm not found - skipping intermediate norm generation"
        return norms
    end
    
    # Find orphan norms
    orphans = find_orphan_norms(norms, grundnorm)
    
    if isempty(orphans)
        return norms
    end
    
    println("Found $(length(orphans)) orphan norm(s) to connect to grundnorm")
    
    # Track generated intermediates to avoid duplicates
    generated_intermediates = Dict{String, Norm}()
    
    # Track orphans that need to be replaced with updated versions
    orphans_to_replace = Dict{String, Norm}()
    
    # Process each orphan
    for orphan in orphans
        # Calculate O-path from grundnorm to orphan
        intermediate_positions = calculate_o_path(grundnorm.Hohfeld, orphan.Hohfeld)
        
        if isempty(intermediate_positions)
            # Direct connection possible - create updated orphan
            updated_orphan = Norm(
                ref_id = orphan.ref_id,
                package = orphan.package,
                Hohfeld = orphan.Hohfeld,
                actor = orphan.actor,
                action = orphan.action,
                object = orphan.object,
                counterparty = orphan.counterparty,
                conditions = orphan.conditions,
                overrules = orphan.overrules,
                excepts = grundnorm.ref_id,
                depth = grundnorm.depth + 1,
                skipped = orphan.skipped,
                text = orphan.text
            )
            orphans_to_replace[orphan.ref_id] = updated_orphan
            println("  - $(orphan.ref_id): Direct connection to grundnorm")
        else
            # Need intermediate norms
            current_parent = grundnorm
            current_depth = grundnorm.depth
            
            for (i, pos) in enumerate(intermediate_positions)
                current_depth += 1
                
                # Generate intermediate norm
                intermediate = create_intermediate_norm(grundnorm, orphan, pos, current_depth)
                
                # Check if we already generated this intermediate
                if haskey(generated_intermediates, intermediate.ref_id)
                    # Reuse existing intermediate
                    intermediate = generated_intermediates[intermediate.ref_id]
                else
                    # Create intermediate with proper parent link
                    intermediate = Norm(
                        ref_id = intermediate.ref_id,
                        package = intermediate.package,
                        Hohfeld = intermediate.Hohfeld,
                        actor = intermediate.actor,
                        action = intermediate.action,
                        object = intermediate.object,
                        counterparty = intermediate.counterparty,
                        conditions = intermediate.conditions,
                        overrules = intermediate.overrules,
                        excepts = current_parent.ref_id,
                        depth = current_depth,
                        skipped = intermediate.skipped,
                        text = intermediate.text
                    )
                    
                    # Add to norms and track it
                    push!(norms, intermediate)
                    generated_intermediates[intermediate.ref_id] = intermediate
                    
                    println("  - Generated: $(intermediate.ref_id) ($(position_name(pos))) → excepts $(current_parent.ref_id)")
                end
                
                current_parent = intermediate
            end
            
            # Create updated orphan linked to last intermediate
            updated_orphan = Norm(
                ref_id = orphan.ref_id,
                package = orphan.package,
                Hohfeld = orphan.Hohfeld,
                actor = orphan.actor,
                action = orphan.action,
                object = orphan.object,
                counterparty = orphan.counterparty,
                conditions = orphan.conditions,
                overrules = orphan.overrules,
                excepts = current_parent.ref_id,
                depth = current_depth + 1,
                skipped = orphan.skipped,
                text = orphan.text
            )
            orphans_to_replace[orphan.ref_id] = updated_orphan
            println("  - $(orphan.ref_id): Connected via intermediate chain")
        end
    end
    
    # Replace orphans with updated versions in the norms vector
    updated_norms = Norm[]
    for norm in norms
        if haskey(orphans_to_replace, norm.ref_id)
            push!(updated_norms, orphans_to_replace[norm.ref_id])
        else
            push!(updated_norms, norm)
        end
    end
    
    println("Generated $(length(generated_intermediates)) intermediate norm(s)")
    
    return updated_norms
end
