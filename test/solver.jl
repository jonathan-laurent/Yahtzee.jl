using Test
using Yahtzee
using Serialization
using StaticArrays

g = build_graph()

table = compute_stat_table(g)
println(table[1])
serialize("stats.bin", table)

# table = deserialize("stats.bin")
# println(value_of_macro_state(table, INITIAL_MACROSTATE))
# ss = MicroState(3,0,1,0,0,1)
# println(best_action_for(table, g, INITIAL_MACROSTATE, ss, 1))
