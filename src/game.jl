export Category, UPPER_CATEGORIES
export DiceConfig
export ScoreSheet, State
export parse_action
export remaining_cats, is_done, is_chance, play

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

const UPPER_CATEGORIES = [ACES, TWOS, THREES, FOURS, FIVES, SIXES]

const NUM_CATEGORIES = length(instances(Category))

const CAT_ABBREV = Dict(
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

const CAT_ABBREV_REV = Dict(a=>c for (c, a) in CAT_ABBREV)

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

set_catval(s::ScoreSheet, c::Category, v) =
  ScoreSheet(setindex(s.scores, v, Int(c) + 1))

function Base.show(io::IO, s::ScoreSheet)
  score(s) = isnothing(s) ? "" : string(s)
  data = [score(catval(s, c)) for c in instances(Category)]
  header = [cat_abbrev(c) for c in instances(Category)]
  pretty_table(io, permutedims(data); header)
end

#####
#####  Dice configurations
#####

const ROLL_AGAIN = 0
const MIN_DICE_VALUE = 1
const MAX_DICE_VALUE = 6
const DICE_VALUES = MIN_DICE_VALUE:MAX_DICE_VALUE
const NUM_DICES = 5

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

const ROLL_EVERYTHING = parse(DiceConfig, "-----")

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

const INIT_STAGE = ROLL_1

stage_msg(s::Stage) = replace(string(s), "_" => " ")

is_chance(s::Stage) = s == ROLL_1 || s == ROLL_2 || s == ROLL_3

const NEXT_STAGE = Dict(
  ROLL_1 => CHOOSE_1,
  CHOOSE_1 => ROLL_2,
  ROLL_2 => CHOOSE_2,
  CHOOSE_2 => ROLL_3,
  ROLL_3 => CHOOSE_CAT,
  CHOOSE_CAT => ROLL_1)

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

const Action = Union{DiceConfig, Category}

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
  return [
    Category(i - 1) for (i, s) in enumerate(s.scores.scores)
    if isnothing(s)]
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
  if is_chance(s.stage)
    return enum_rolls(s.dices)
  elseif s.stage == CHOOSE_1 || s.stage == CHOOSE_2
    return keep_subset(s.dices)
  elseif s.stage == CHOOSE_CAT
    return remaining_cats(s)
  end
  @assert false
end

count_val(v, dices) = count(==(v), dices)

score_upper(dices, val) = count_val(val, dices) * val

has_k_of_a_kind(dices, k) = any(v -> count_val(v, dices) >= k, DICE_VALUES)

has_exactly_k_of_a_kind(dices, k) = any(v -> count_val(v, dices) == k, DICE_VALUES)

score_k(dices, k) = has_k_of_a_kind(dices, k) ? sum(dices) : 0

score_y(dices) = has_k_of_a_kind(dices, 5) ? 50 : 0

score_f(dices) = has_k_of_a_kind(dices, 5) ||
                (has_exactly_k_of_a_kind(dices, 3) && has_exactly_k_of_a_kind(dices, 2)) ? 25 : 0

const LARGE_STRAIGHTS = map(s -> parse(DiceConfig, s), ["12345", "23456"])

function is_small_straight(dices)
  has(k) = count_val(k, dices) >= 1
  hasall(ks) = all(has, ks)
  return (hasall([1, 2, 3, 4]) || hasall([2, 3, 4, 5]) || hasall([3, 4, 5, 6]))
end

score_ss(dices) = is_small_straight(dices) : 30 : 0

score_ls(dices) = dices ∈ LARGE_STRAIGHTS : 40 : 0

function score_dices(d::DiceConfig, c::Category)
  d = d.dices
  (c == ACES)   && (return score_upper(d, 1))
  (c == TWOS)   && (return score_upper(d, 2))
  (c == THREES) && (return score_upper(d, 3))
  (c == FOURS)  && (return score_upper(d, 4))
  (c == FIVES)  && (return score_upper(d, 5))
  (c == SIXES)  && (return score_upper(d, 6))
  (c == THREE_OF_A_KIND) && (return score_k(d, 3))
  (c == FOUR_OF_A_KIND)  && (return score_k(d, 4))
  (c == FULL_HOUSE) && (return score_f(d))
  (c == CHANCE)  && (return sum(d))
  (c == YAHTZEE) && (return score_y(d))
  (c == SMALL_STRAIGHT) && (return score_ss(d))
  (c == LARGE_STRAIGHT) && (return score_ls(d))
  @assert false
end

function play(s::State, a::Action)
  @assert a ∈ available_actions(s)
  scores, dices = s.scores, s.dices
  if is_chance(s.stage) || s.stage == CHOOSE_1 || s.stage == CHOOSE_2
    @assert isa(a, DiceConfig)
    dices = a
  elseif s.stage == CHOOSE_CAT
    @assert isa(a, Category)
    scores = set_catval(scores, a, score_dices(dices, a))
  end
  return State(scores, NEXT_STAGE[s.stage], dices)
end

function prompt(s::State)
  is_chance(s) ?
    (crayon"red", "chance> ", crayon"reset") :
    (crayon"green", "play> ", crayon"reset")
end
