
using StaticArrays

export build_graph

struct MicroState
    to_draw::Int8
    dice_values::SVector{6,Int8}
end

MicroFinalState = Tuple{MicroState,Category}

mutable struct MicroStateValue
    value::Int8
    successors::Vector{MicroState}
end

MicroStep = Dict{MicroState, MicroStateValue}

mutable struct MicroFinalStateValue
    value::Int8
    successors::Vector{MicroFinalState}
end

MicroFinalStep = Dict{MicroState, MicroFinalStateValue}

struct MicroGame
    init::MicroState
    rand1::MicroStep
    action1::MicroStep
    rand2::MicroStep
    action2::MicroStep
    rand3::MicroStep
    final::MicroFinalStep
end

function micro_final_state_to_macro_state(initial_macro, state::MicroFinalState)

end

function draw_one(state::MicroState)
    nb = state.to_draw-1
    dice_values = state.dice_values
    return Set(MicroState(nb, setindex(dice_values, dice_values[i]+1, i)) for i in 1:6)
end

function rand_step_successors(state::MicroState)
    succ = Set([state])
    for _ in 1:state.to_draw
        succ = union((draw_one(s) for s in succ)...)
    end
    return succ
end

function remove_one(state::MicroState)
    nb = state.to_draw+1
    dice_values = state.dice_values
    return Set(MicroState(nb, setindex(dice_values, dice_values[i]-1, i)) for i in 1:6 if dice_values[i]>0)
end

function action_step_successors(state::MicroState)
    succ = Set([state])
    for _ in 1:5
        succ = union(succ, union((remove_one(s) for s in succ)...))
    end
    return succ
end

function build_graph_step(succ::Set{MicroState}, f)
    r = Dict{MicroState, MicroStateValue}()
    new_succ = Set{MicroState}()
    for s in succ
        cur_succ = f(s)
        r[s] = MicroStateValue(0, collect(cur_succ))
        new_succ = union(new_succ, cur_succ)
    end
    return (r, new_succ)
end

function build_graph()
    init = MicroState(5, SVector(0, 0, 0, 0, 0, 0))
    (rand1, succ) = build_graph_step(Set([init]), rand_step_successors)
    (action1, succ) = build_graph_step(succ, action_step_successors)
    (rand2, succ) = build_graph_step(succ, rand_step_successors)
    (action2, succ) = build_graph_step(succ, action_step_successors)
    (rand3, succ) = build_graph_step(succ, rand_step_successors)
    final = Dict((s, MicroFinalStateValue(0, [(s, c) for c in instances(Category)])) for s in succ)
    return MicroGame(init, rand1, action1, rand2, action2, rand3, final)
end

function fill_graph()

end
