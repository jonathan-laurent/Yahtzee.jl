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
    max_v = 0
    max_dices = nothing
    for s in g.action1[state].successors
        v = g.rand2[s].value
        if v > max_v
            max_v = v
            max_dices = s.dice_values
        end
    end
    println(max_dices)
end

test()