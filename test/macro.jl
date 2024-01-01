using Test
using Yahtzee.Classic
using Serialization
using StaticArrays

upper_sec_total(set_upper_sec_total(MacroState(42), 27))

st = MacroState()
st = set_used(st, Classic.ACES)
st = add_upper_sec(st, 4)
st = add_upper_sec(st, 60)

a = parse_action("4k")
