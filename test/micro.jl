using Test
using Yahtzee
using PrettyTables

function test()
    g=build_graph()

    ss=g.rand1[g.init].successors
    @assert length(ss) == binomial(6+5-1,5)
    total_p = 0
    for (p,s) in ss
        total_p += p
        @assert s.to_draw == 0
        for s2 in g.action1[s].successors
            @assert s2.to_draw >= 0 && s2.to_draw <= 5
        end
    end
    print(total_p)

    @assert length(g.final) == binomial(6+5-1,5)
    for (k,v) in g.final
        @assert k.to_draw == 0
    end
end

test()