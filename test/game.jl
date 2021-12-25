using Test
using Yahtzee
using PrettyTables

parse(DiceConfig, "12345")
parse(DiceConfig, "--125")

s = ScoreSheet()
s = State()
is_chance(s)

Yahtzee.enum_rolls(parse(DiceConfig, "--125"))

Yahtzee.keep_subset(parse(DiceConfig, "11111"))