
using StaticArrays

export build_graph, fill_graph!
export value_of_initial_state, best_action, micro_category_state_to_macro_state
export MicroState

struct MicroState
    to_draw::Int8
    dice_values::SVector{6,Int8}
end

MicroCategoryState = Tuple{MicroState,Category}

mutable struct MicroActionStateValue
    value::Float64
    successors::Vector{MicroState}
end

mutable struct MicroRandStateValue
    value::Float64
    successors::Vector{Tuple{Float64,MicroState}}
end

mutable struct MicroCategoryStateValue
    value::Float64
    successors::Vector{MicroCategoryState}
end

mutable struct MicroFinalStateValue
    value::Float64
end

MicroStateValue = Union{MicroActionStateValue, MicroRandStateValue, MicroCategoryStateValue, MicroFinalStateValue}

MicroActionStep = Dict{MicroState, MicroActionStateValue}
MicroRandStep = Dict{MicroState, MicroRandStateValue}
MicroCategoryStep = Dict{MicroState, MicroCategoryStateValue}
MicroFinalStep = Dict{MicroCategoryState, MicroFinalStateValue}

MicroStep = Union{MicroActionStep, MicroRandStep, MicroCategoryStep, MicroFinalStep}

struct MicroGame
    init::MicroState
    rand1::MicroRandStep
    action1::MicroActionStep
    rand2::MicroRandStep
    action2::MicroActionStep
    rand3::MicroRandStep
    action3::MicroCategoryStep
    final::MicroFinalStep
end

function Base.show(io::IO, s::MicroState)
    dices = Vector{String}()
    for (i,v) in enumerate(s.dice_values)
        for _ in 1:v
            push!(dices, string(i))
        end
    end
    for _ in 1:s.to_draw
        push!(dices, "X")
    end
    str = join(dices, "")
    print(io, str)
  end

UPPER_CATEGORIES = [ACES, TWOS, THREES, FOURS, FIVES, SIXES]

function micro_category_state_to_macro_state(initial::MacroState, state::MicroCategoryState)
    (state, cat) = state
    if is_used(initial, cat)
        return nothing
    end
    final = set_used(initial, cat)
    n = findfirst(x -> x == cat, UPPER_CATEGORIES)
    if n !== nothing
        final = add_upper_sec(final, state.dice_values[n]*n)
    end
    return final
end

function score_of_category_state(state::MicroCategoryState)
    (state, cat) = state
    n = findfirst(x -> x == cat, UPPER_CATEGORIES)
    dice_values = state.dice_values
    if n !== nothing
        return dice_values[n]*n
    elseif cat == THREE_OF_A_KIND
        return any(x -> x >= 3, dice_values) ? sum(i*n for (i,n) in enumerate(dice_values)) : 0
    elseif cat == FOUR_OF_A_KIND
        return any(x -> x >= 4, dice_values) ? sum(i*n for (i,n) in enumerate(dice_values)) : 0
    elseif cat == FULL_HOUSE
        return any(x -> x == 3, dice_values) && any(x -> x == 2, dice_values) ? 25 : 0
    elseif cat == SMALL_STRAIGHT
        for i in 1:3
            if dice_values[i] >= 1 && dice_values[i+1] >= 1 && dice_values[i+2] >= 1 && dice_values[i+3] >= 1
                return 30
            end
        end
        return 0
    elseif cat == LARGE_STRAIGHT
        for i in 1:2
            if dice_values[i] >= 1 && dice_values[i+1] >= 1 && dice_values[i+2] >= 1 &&
                dice_values[i+3] >= 1 && dice_values[i+4] >= 1
                return 40
            end
        end
        return 0
        #return all(x -> x <= 1, dice_values) && (dice_values[1] == 0 || dice_values[6] == 0) ? 40 : 0
    elseif cat == YAHTZEE
        return any(x -> x >= 5, dice_values) ? 50 : 0
    elseif cat == CHANCE
        return sum(i*n for (i,n) in enumerate(dice_values))
    end
end

function draw_one(state::MicroState)
    nb = state.to_draw-1
    dice_values = state.dice_values
    return [MicroState(nb, setindex(dice_values, dice_values[i]+1, i)) for i in 1:6]
end

function rand_step_successors(state::MicroState)
    succ = Dict([(state, 1)])
    for _ in 1:state.to_draw
        new_succ = Dict{MicroState,Int64}()
        for (s,c) in succ
            for ss in draw_one(s)
                cc = haskey(new_succ, ss) ? new_succ[ss] : 0
                new_succ[ss] = cc + c
            end
        end
        succ = new_succ
    end
    return succ
end

function remove_one(state::MicroState)
    nb = state.to_draw+1
    dice_values = state.dice_values
    return [MicroState(nb, setindex(dice_values, dice_values[i]-1, i)) for i in 1:6 if dice_values[i]>0]
end

function action_step_successors(state::MicroState)
    succ = Set([state])
    for _ in 1:5
        succ = union(succ, union((Set(remove_one(s)) for s in succ)...))
    end
    return succ
end

function build_graph_action_step(succ::Set{MicroState})
    r = Dict{MicroState, MicroActionStateValue}()
    new_succ = Set{MicroState}()
    for s in succ
        cur_succ = action_step_successors(s)
        r[s] = MicroActionStateValue(0.0, collect(cur_succ))
        new_succ = union(new_succ, cur_succ)
    end
    return (r, new_succ)
end

function build_graph_rand_step(succ::Set{MicroState})
    r = Dict{MicroState, MicroRandStateValue}()
    new_succ = Set{MicroState}()
    for s in succ
        cur_succ = rand_step_successors(s)
        total_card = sum(v for (_,v) in cur_succ)
        r[s] = MicroRandStateValue(0.0, [(v/total_card, k) for (k,v) in cur_succ])
        cur_succ = Set(k for (k,_) in cur_succ)
        new_succ = union(new_succ, cur_succ)
    end
    return (r, new_succ)
end

function build_graph()
    init = MicroState(5, SVector(0, 0, 0, 0, 0, 0))
    (rand1, succ) = build_graph_rand_step(Set([init]))
    (action1, succ) = build_graph_action_step(succ)
    (rand2, succ) = build_graph_rand_step(succ)
    (action2, succ) = build_graph_action_step(succ)
    (rand3, succ) = build_graph_rand_step(succ)
    action3 = Dict((s, MicroCategoryStateValue(0.0, [(s, c) for c in instances(Category)])) for s in succ)
    final = Dict(((s,c), MicroFinalStateValue(0.0)) for c in instances(Category) for s in succ)
    return MicroGame(init, rand1, action1, rand2, action2, rand3, action3, final)
end

function propagate_action_step!(step::Union{MicroActionStep,MicroCategoryStep}, next_step::MicroStep)
    for (_, v) in step
        val = 0.0
        for s in v.successors
            score = next_step[s].value
            val = max(val, score)
        end
        v.value = val
    end
end

function propagate_rand_step!(step::MicroRandStep, next_step::MicroStep)
    for (_, v) in step
        val = 0.0
        for (p,s) in v.successors
            score = next_step[s].value
            val += p*score;
        end
        v.value = val
    end
end

function fill_graph!(initial::MacroState, g::MicroGame, macro_values)
    # Fill final states
    for (s,v) in g.final
        final_macro = micro_category_state_to_macro_state(initial, s)
        if final_macro !== nothing
            v.value = score_of_category_state(s) + macro_values(final_macro)
        else
            v.value = -Inf64
        end
    end
    # Propagate
    propagate_action_step!(g.action3, g.final)
    propagate_rand_step!(g.rand3, g.action3)
    propagate_action_step!(g.action2, g.rand3)
    propagate_rand_step!(g.rand2, g.action2)
    propagate_action_step!(g.action1, g.rand2)
    propagate_rand_step!(g.rand1, g.action1)
end

function value_of_initial_state(g::MicroGame)
    return g.rand1[g.init].value;
end

function best_action(g::MicroGame, s::MicroState, i::Int64)
    @assert i == 1 || i == 2 || i == 3
    if i == 1
        step = g.action1
        next_step = g.rand2
    elseif i == 2
        step = g.action2
        next_step = g.rand3
    else
        step = g.action3
        next_step = g.final
    end
    return argmax(((_,v),) -> v, (ss,next_step[ss].value) for ss in step[s].successors)
end
