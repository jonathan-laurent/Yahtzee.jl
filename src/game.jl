export Category
export DiceConfig
export ScoreSheet, State
export parse_action
export remaining_cats, is_done, is_chance

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
DICE_VALUES = MIN_DICE_VALUE:MAX_DICE_VALUE
NUM_DICES = 5

struct DiceConfig
  dices :: SVector{NUM_DICES, Int}
  DiceConfig(dices) = new(sort(dices))
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
  print(io, replace(join(string(d) for d in c.dices), "0" => "-"))
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

stage_msg(s::Stage) = replace(string(s), "_" => " ")

is_chance(s::Stage) = s == ROLL_1 || s == ROLL_2 || s == ROLL_3

#####
#####  State
#####

struct State
  scores :: ScoreSheet
  stage :: Stage
  dices :: DiceConfig
end

State(s::ScoreSheet) = State(s, INIT_STAGE, ROLL_EVERYTHING)
State() = State(ScoreSheet())

function Base.show(io::IO, s::State)
  println(io, s.scores)
  println(io, "$(stage_msg(s.stage)):  $(s.dices)")
end

#####
##### Actions
#####

Action = Union{DiceConfig, Category}

function parse_action(s)
  try
    return parse(DiceConfig, s)
  catch
    return parse_cat_abbrev(s)
  end
end

#####
##### Game
#####

function remaining_cats(s::State)
  return [Category(i - 1) for (i, s) in enumerate(s.scores) if isnothing(s)]
end

is_done(s::State) = isempty(remaining_cats(s))

is_chance(s::State) = is_chance(s.stage)

function enum_rolls(s::DiceConfig)
  if ROLL_AGAIN ∉ s.dices
    return [s]
  else
    ds = [
      DiceConfig(replace(s.dices, ROLL_AGAIN=>v, count=1))
      for v in DICE_VALUES]
    ds = [x for d in ds for x in enum_rolls(d)]
    return collect(Set(ds))
  end
end

function keep_subset_aux(dices, i)
  if i > length(dices)
    return [dices]
  else
    reroll = setindex(dices, ROLL_AGAIN, i)
    return [keep_subset_aux(reroll, i+1); keep_subset_aux(dices, i+1)]
  end
end

function keep_subset(s::DiceConfig)
  cs = [DiceConfig(c) for c in keep_subset_aux(s.dices, 1)]
  return collect(Set(cs))
end

function available_actions(s::State)
  if is_chance(s)
    return enum_rolls(s.dices)
  elseif s == CHOOSE_1 || s == CHOOSE_2
    return
  elseif s == CHOOSE_CAT

  end
  @assert false
end

function play(s::State, a::Action)
end