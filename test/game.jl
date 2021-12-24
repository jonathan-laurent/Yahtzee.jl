using Test
using Yahtzee
using PrettyTables

parse(DiceConfig, "12345")
parse(DiceConfig, "125")

x = PlayerState()

m = MultiPlayerState([("Mick", PlayerState()), ("Jo", PlayerState())])