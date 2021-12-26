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

Yahtzee.interactive(State(), table)
