using Test
using Yahtzee
using PrettyTables

using Yahtzee: ScoreSheet, CHOOSE_CAT, set_catval, ACES

parse(DiceConfig, "12345")
parse(DiceConfig, "--125")

Yahtzee.enum_rolls(parse(DiceConfig, "--125"))
Yahtzee.keep_subset(parse(DiceConfig, "11111"))

s = State(ScoreSheet(), CHOOSE_CAT, parse(DiceConfig, "33334"))
play(s, parse_action("4k"))

# Yahtzee.interactive()