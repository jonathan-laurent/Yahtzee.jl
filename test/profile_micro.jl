using Test
using Yahtzee
using StaticArrays
using BenchmarkTools
#using ProfileView

function test()
    g = build_graph()
    @btime fill_graph!($INITIAL_MACROSTATE, $g, _ -> Stat())
    #ProfileView.@profview fill_graph!(INITIAL_MACROSTATE, g, _ -> Stat())
end

test()