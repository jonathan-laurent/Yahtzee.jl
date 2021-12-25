using Test
using Yahtzee
using StaticArrays

function test()
    # Graph building
    g=build_graph()

    ss=g.rand1[g.init].successors
    @assert length(ss) == binomial(6+5-1,5)
    total_p = 0
    for (p,s) in ss
        if s.dice_values[1] == 5
            @assert p == 1/(6^5)
        end
        total_p += p
        @assert s.to_draw == 0
        for s2 in g.action1[s].successors
            @assert s2.to_draw >= 0 && s2.to_draw <= 5
        end
    end
    @assert total_p > 0.9999999 && total_p < 1.0000001

    @assert length(g.final) == binomial(6+5-1,5)
    for (k,v) in g.final
        @assert k.to_draw == 0
    end

    # Graph filling
    fill_graph!(INITIAL_MACROSTATE, g, _ -> 0)
    println(value_of_initial_state(g))
    state = MicroState(0, SVector(1,1,0,0,0,3))
    println(best_action(g, state, 1))
    println(best_action(g, state, 2))
    println(best_action(g, state, 3))
end

test()