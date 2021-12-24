export Category
export DiceConfig

@enum Category begin
  ACES
  TWOS
  THREES
  FOURS
  FIVES
  SIXES
  THREE_OF_A_KIND
  FOUR_OF_A_KIND
  FULL_HOUSE
  SMALL_STRAIGHT
  LARGE_STRAIGHT
  YAHTZEE
  CHANCE
end

NUM_CATEGORIES = length(instances(Category))

struct PlayerState
  scores :: SVector{NUM_CATEGORIES, Union{Int, Nothing}}
end

struct MultiPlayerState
  players :: Vector{Tuple{String, PlayerState}}
end

ROLL_AGAIN = 0
MIN_DICE_VALUE = 1
MAX_DICE_VALUE = 6
NUM_DICES = 5

struct DiceConfig
  dices :: SVector{NUM_DICES, Int}
end

function Base.parse(::Type{DiceConfig}, s::AbstractString)
  digits = sort([parse(Int, c) for c in s])
  @assert all(MIN_DICE_VALUE <= d <= MAX_DICE_VALUE for d in digits)
  k = length(digits)
  @assert k <= NUM_DICES
  digits = vcat(repeat([ROLL_AGAIN], NUM_DICES - k), digits)
  return DiceConfig(SVector{NUM_DICES}(digits))
end

full_config(c::DiceConfig) = all(d > 0 for d in c.dices)

function Base.show(io::IO, c::DiceConfig)
  print(io, join(string(d) for d in c.dices))
end

