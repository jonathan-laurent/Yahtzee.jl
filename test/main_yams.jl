using Test
using Yahtzee.Yams
using PrettyTables
using Serialization
using StaticArrays

table = nothing
if isfile("stats_yams.bin")
    table=deserialize("stats_yams.bin")
end

Yams.interactive(State(), table)
