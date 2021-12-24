export Category
export DiceConfig
export PlayerState, MultiPlayerState
export parse_action

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

CAT_ABBREV = Dict(
  ACES => "1",
  TWOS => "2",
  THREES => "3",
  FOURS => "4",
  FIVES => "5",
  SIXES => "6",
  THREE_OF_A_KIND => "3k",
  FOUR_OF_A_KIND => "4k",
  FULL_HOUSE => "f",
  SMALL_STRAIGHT => "ss",
  LARGE_STRAIGHT => "ls",
  YAHTZEE => "y",
  CHANCE => "c")

CAT_ABBREV_REV = Dict(a=>c for (c, a) in CAT_ABBREV)

parse_cat_abbrev(s::String) = CAT_ABBREV_REV[s]
cat_abbrev(c::Category) = CAT_ABBREV[c]

struct PlayerState
  scores :: SVector{NUM_CATEGORIES, Union{Int, Nothing}}
end

catval(s::PlayerState, c::Category) = s.scores[Int(c) + 1]

function PlayerState()
  scores = @SVector[nothing for _ in instances(Category)]
  return PlayerState(scores)
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
  s = replace(s, "-" => "0")
  digits = sort([parse(Int, c) for c in s])
  @assert all(
    MIN_DICE_VALUE <= d <= MAX_DICE_VALUE || d == ROLL_AGAIN
    for d in digits)
  @assert length(digits) == NUM_DICES
  return DiceConfig(SVector{NUM_DICES}(digits))
end

full_config(c::DiceConfig) = all(d > 0 for d in c.dices)

function Base.show(io::IO, c::DiceConfig)
  print(io, join(string(d) for d in c.dices))
end

function Base.show(io::IO, s::MultiPlayerState)
  score(s) = isnothing(s) ? "" : string(s)
  data = [
    score(catval(s, c))
    for c in instances(Category), (_ , s) in s.players]
  data = hcat([string(c) for c in instances(Category)], data)
  header = [" "; [name for (name, _) in s.players]]
  pretty_table(io, data; header)
end

function Base.show(io::IO, s::PlayerState)
  show(io, MultiPlayerState([("Score", s)]))
end

abstract type Action end

struct KeepDices <: Action
  keep :: DiceConfig
end

struct ChooseCategory <: Action
  cat :: Category
end

function parse_action(s)
  try
    return KeepDices(parse(DiceConfig, s))
  catch
    return ChooseCategory(parse_cat_abbrev(s))
  end
end

