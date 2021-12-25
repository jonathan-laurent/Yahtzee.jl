export Category
export DiceConfig
export ScoreSheet, State
export parse_action
export remaining_cats, is_done

#####
#####  Categories
#####

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

#####
#####  ScoreSheet
#####

struct ScoreSheet
  scores :: SVector{NUM_CATEGORIES, Union{Int, Nothing}}
end

ScoreSheet() = ScoreSheet(@SVector[nothing for _ in instances(Category)])

catval(s::ScoreSheet, c::Category) = s.scores[Int(c) + 1]

function Base.show(io::IO, s::ScoreSheet)
  score(s) = isnothing(s) ? "" : string(s)
  data = [score(catval(s, c)) for c in instances(Category)]
  header = [cat_abbrev(c) for c in instances(Category)]
  pretty_table(io, permutedims(data); header)
end

#####
#####  Dice configurations
#####

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

ROLL_EVERYTHING = parse(DiceConfig, "-----")

#####
#####  Game stage
#####

@enum Stage begin
  ROLL_1      # chance
  CHOOSE_1    # action
  ROLL_2      # chance
  CHOOSE_2    # action
  ROLL_3      # chance
  CHOOSE_CAT  # action
end

INIT_STAGE = ROLL_1

#####
#####  State
#####

struct State
  scores :: ScoreSheet
  stage :: Stage
  dices :: DiceConfig
end

State() = State(ScoreSheet(), INIT_STAGE, ROLL_EVERYTHING)

#####
##### Actions
#####

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

#####
##### Game
#####

function remaining_cats(s::State)
  return [Category(i - 1) for (i, s) in enumerate(s.scores) if isnothing(s)]
end

is_done(s) = isempty(remaining_cats(s))

function available_actions(s::State)
end

function play(s::State, a::Action)
end