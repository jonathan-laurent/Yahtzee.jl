module Yahtzee
  module Classic
    using StaticArrays
    using PrettyTables
    using Crayons

    include("game.jl")
    include("macro.jl")
    include("micro.jl")
    include("solver.jl")
    include("ui.jl")
  end
  module Yams
    using StaticArrays
    using PrettyTables
    using Crayons

    include("game_yams.jl")
    include("macro.jl")
    include("micro_yams.jl")
    include("solver.jl")
    include("ui.jl")
  end
end