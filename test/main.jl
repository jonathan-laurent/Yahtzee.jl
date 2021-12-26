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

#Yahtzee.interactive(State(ScoreSheet(nothing,4,6,16,15,24,27,nothing,25,30,40,50,25)), table)
Yahtzee.interactive(State(), table)
