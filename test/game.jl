using Test
using Yahtzee.Classic
using PrettyTables

using Yahtzee.Classic: ScoreSheet, CHOOSE_CAT, set_catval, ACES

parse(DiceConfig, "12345")
parse(DiceConfig, "--125")

Classic.enum_rolls(parse(DiceConfig, "--125"))
Classic.keep_subset(parse(DiceConfig, "11111"))

s = State(ScoreSheet(), CHOOSE_CAT, parse(DiceConfig, "33334"))
play(s, parse_action("4k"))

# Classic.interactive()