using Test
using Yahtzee
using Serialization
using StaticArrays

upper_sec_total(set_upper_sec_total(MacroState(42), 27))

st = MacroState()
st = set_used(st, Yahtzee.ACES)
st = add_upper_sec(st, 4)
st = add_upper_sec(st, 60)

a = parse_action("4k")

g = build_graph()

#table = compute_value_table(g)
#println(table[1])
#serialize("expected_values.bin", table)

table = deserialize("expected_values.bin")
println(value_of_macro_state(table, INITIAL_MACROSTATE))
ss = MicroState(3,0,1,0,0,1)
println(best_action_for(table, g, INITIAL_MACROSTATE, ss, 1))
