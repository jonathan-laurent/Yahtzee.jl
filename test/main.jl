using Test
using Yahtzee.Classic
using PrettyTables
using Serialization
using StaticArrays

using Yahtzee.Classic: ScoreSheet, CHOOSE_CAT, set_catval, ACES

table = nothing
if isfile("stats.bin")
    table=deserialize("stats.bin")
end

#Classic.interactive(State(ScoreSheet(nothing,4,6,16,15,24,27,nothing,25,30,40,50,25)), table)
Classic.interactive(State(), table)
