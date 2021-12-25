module Yahtzee

  using StaticArrays
  using PrettyTables
  using Crayons

  include("game.jl")
  include("macro.jl")
  include("micro.jl")
  include("ui.jl")

end