using Test
using Yahtzee.Yams
using Serialization
using StaticArrays

g = build_graph()

table = compute_stat_table(g)
println(table[1])
serialize("stats_yams.bin", table)
