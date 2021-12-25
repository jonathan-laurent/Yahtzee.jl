using Test
using Yahtzee
using StaticArrays
using BenchmarkTools
#using ProfileView

function test()
    g = build_graph()
    @btime fill_graph!($INITIAL_MACROSTATE, $g, _ -> 0)
    #ProfileView.@profview fill_graph!(INITIAL_MACROSTATE, g, _ -> 0)
end

test()