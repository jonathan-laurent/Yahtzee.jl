using Test
using Yahtzee
using PrettyTables

g=build_graph()

ss=g.rand1[g.init].successors
@assert length(ss) == binomial(6+5-1,5)
for s in ss
    @assert s.to_draw == 0
    for s2 in g.action1[s].successors
        @assert s2.to_draw >= 0 && s2.to_draw <= 5
    end
end

@assert length(g.final) == binomial(6+5-1,5)
for (k,v) in g.final
    @assert k.to_draw == 0
end


