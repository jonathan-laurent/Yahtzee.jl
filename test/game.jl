using Test
using Yahtzee
using PrettyTables

parse(DiceConfig, "12345")
parse(DiceConfig, "45677999")
parse(DiceConfig, "")
parse(DiceConfig, "125")