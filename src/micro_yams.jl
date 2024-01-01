
using StaticArrays
using StatsBase

export build_graph, fill_graph!
export stat_of_initial_state, stat_of_rand_state, best_action, best_k_actions, micro_category_state_to_macro_state
export MicroState, MicroGame, Stat

mutable struct Stat
    value::Float64
    variance::Float64
end

Stat() = Stat(0,0)
Stat(s::Stat) = Stat(s.value,s.variance)

struct MicroState
    to_draw::Int8
    dice_values::SVector{6,Int8}
end

MicroState(one::Int64,two::Int64,three::Int64,four::Int64,five::Int64,six::Int64) =
    MicroState(Int8(5-(one+two+three+four+five+six)),
        SVector(Int8(one), Int8(two), Int8(three), Int8(four), Int8(five), Int8(six)))

MicroCategoryState = Tuple{MicroState,Category}

struct MicroActionStateValue
    stat::Stat
    successors::Vector{MicroState}
end

struct MicroRandStateValue
    stat::Stat
    successors::Vector{Tuple{Float64,MicroState}}
end

struct MicroCategoryStateValue
    stat::Stat
    successors::Vector{MicroCategoryState}
end

struct MicroFinalStateValue
    stat::Stat
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
        push!(dices, "-")
    end
    str = join(dices, "")
    print(io, str)
  end

function micro_category_state_to_macro_state(initial::MacroState, cat_state::MicroCategoryState)
    (state, cat) = cat_state
    if is_used(initial, cat)
        return nothing
    end
    final = set_used(initial, cat)
    n = findfirst(==(cat), UPPER_CATEGORIES)
    if !isnothing(n)
        final = add_upper_sec(final, state.dice_values[n]*n)
    end
    return final
end

function score_of_category_state(cat_state::MicroCategoryState)
    (state, cat) = cat_state
    n = findfirst(==(cat), UPPER_CATEGORIES)
    dice_values = state.dice_values
    if !isnothing(n)
        return dice_values[n]*n
    elseif cat == THREE_OF_A_KIND
        return any(>=(3), dice_values) ? sum(i*n for (i,n) in enumerate(dice_values)) : 0
    elseif cat == FOUR_OF_A_KIND
        return any(>=(4), dice_values) ? 40 : 0
    elseif cat == FULL_HOUSE
        return (any(==(3), dice_values) && any(==(2), dice_values)) || any(==(5), dice_values) ? 30 : 0
    elseif cat == SMALL_STRAIGHT
        return all(<=(1), dice_values) && (dice_values[6] == 0) ? 15 : 0
    elseif cat == LARGE_STRAIGHT
        return all(<=(1), dice_values) && (dice_values[1] == 0) ? 20 : 0
    elseif cat == YAMS
        return any(>=(5), dice_values) ? 50 : 0
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
        r[s] = MicroActionStateValue(Stat(), collect(cur_succ))
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
        r[s] = MicroRandStateValue(Stat(), [(v/total_card, k) for (k,v) in cur_succ])
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
    action3 = Dict((s, MicroCategoryStateValue(Stat(), [(s, c) for c in instances(Category)])) for s in succ)
    final = Dict(((s,c), MicroFinalStateValue(Stat())) for c in instances(Category) for s in succ)
    return MicroGame(init, rand1, action1, rand2, action2, rand3, action3, final)
end

function propagate_action_step!(step::Union{MicroActionStep,MicroCategoryStep}, next_step::MicroStep)
    for (_, v) in step
        stat = argmax(v -> v.value, next_step[s].stat for s in v.successors)
        v.stat.value = stat.value
        v.stat.variance = stat.variance
    end
end

function propagate_rand_step!(step::MicroRandStep, next_step::MicroStep)
    for (_, v) in step
        succs = [s for s in v.successors]
        ps = Weights([p for (p,_) in succs])
        es = [next_step[s].stat.value for (_,s) in succs]
        vs = [next_step[s].stat.variance for (_,s) in succs]
        v.stat.value = StatsBase.mean(es, ps)
        v.stat.variance = StatsBase.varm(es, ps, v.stat.value, corrected=false) + StatsBase.mean(vs, ps)
    end
end

function fill_graph!(initial::MacroState, g::MicroGame, macro_stats)
    # Fill final states
    for (s,v) in g.final
        final_macro = micro_category_state_to_macro_state(initial, s)
        if !isnothing(final_macro)
            stat = macro_stats(final_macro)
            v.stat.value = score_of_category_state(s) + stat.value
            v.stat.variance = stat.variance
        else
            v.stat.value = -Inf64
            v.stat.variance = 0.0
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

function stat_of_initial_state(g::MicroGame)
    return Stat(g.rand1[g.init].stat)
end

function stat_of_rand_state(g::MicroGame, s::MicroState, i::Int64)
    @assert i == 1 || i == 2 || i == 3
    if i == 1
        step = g.rand1
    elseif i == 2
        step = g.rand2
    else
        step = g.rand3
    end
    return Stat(step[s].stat)
end

function actions(g::MicroGame, s::MicroState, i::Int64)
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
    return [(ss,Stat(next_step[ss].stat)) for ss in step[s].successors]
end

function best_k_actions(g::MicroGame, s::MicroState, i::Int64, k::Int64)
    a = actions(g,s,i)
    sort!(a, by=((_,v),) -> v.value, rev=true)
    return a[1:min(k,length(a))]
end

function best_action(g::MicroGame, s::MicroState, i::Int64)
    a = actions(g,s,i)
    return argmax(((_,v),) -> v.value, a)
end
