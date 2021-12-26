module Yahtzee

  using StaticArrays
  using PrettyTables
  using Crayons

  include("game.jl")
  include("macro.jl")
  include("micro.jl")
  include("solver.jl")
  include("ui.jl")

end