module Yahtzee

  using StaticArrays
  using PrettyTables

  include("game.jl")
  include("macro.jl")
  include("micro.jl")
  include("ui.jl")

end