using Test
using Yahtzee
using PrettyTables
using Serialization
using StaticArrays

using Yahtzee: ScoreSheet, CHOOSE_CAT, set_catval, ACES

table = nothing
if isfile("expected_values.bin")
    table=deserialize("expected_values.bin")
end

#Yahtzee.interactive(State(ScoreSheet(SVector{13, Union{Int, Nothing}}(0,0,0,0,0,0,27,27,25,30,40,nothing,nothing))), table)
Yahtzee.interactive(State(), table)
