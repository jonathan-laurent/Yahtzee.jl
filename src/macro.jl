export MacroState, INITIAL_MACROSTATE
export upper_sec_total, set_upper_sec_total, add_upper_sec
export is_used, set_used
export compute_value_table

using ThreadsX

# We represent a macrostate as a bit field.
# The first NUM_CATEGORIES bits indicate whether or not each category
# is already used (1 if used and 0 otherwise). The next bits indicate the
# points total in the upper section.
struct MacroState
  val:: UInt32
end

MacroState() = MacroState(0)

INITIAL_MACROSTATE = MacroState()

# We use 6 bits to store a counter for the total score in the upper section
NUM_UPPER_SEC_COUNTER_BITS = 6
MAX_UPPER_SEC_COUNTER = (1 << NUM_UPPER_SEC_COUNTER_BITS) - 1
UPPER_SEC_COUNTER_MASK = MAX_UPPER_SEC_COUNTER
CATEGORIES_MASK = (1 << NUM_CATEGORIES) - 1
NUM_MACROSTATE = 1 << (NUM_CATEGORIES+NUM_UPPER_SEC_COUNTER_BITS)

function upper_sec_total(s::MacroState)
  return (s.val >> NUM_CATEGORIES) & UPPER_SEC_COUNTER_MASK
end

function set_upper_sec_total(s::MacroState, tot)
  tot = clamp(tot, 0, MAX_UPPER_SEC_COUNTER)
  return MacroState((s.val & CATEGORIES_MASK) | (tot << NUM_CATEGORIES))
end

function add_upper_sec(s::MacroState, delta)
  return set_upper_sec_total(s, upper_sec_total(s) + delta)
end

function is_used(s::MacroState, cat::Category)
  return s.val & (1 << Int(cat)) != 0
end

function set_used(s::MacroState, cat::Category)
  return MacroState(s.val | (1 << Int(cat)))
end

function Base.show(io::IO, s::MacroState)
  upper = upper_sec_total(s)
  remaining = [cat_abbrev(c) for c in instances(Category) if !is_used(s, c)]
  remaining = join(remaining, ", ")
  print(io, "{upper: $(upper); remaining: $(remaining)}")
end

#####
##### SOLVING
#####

function num_used(s::MacroState)
  return count(c -> is_used(s,c), instances(Category))
end

function enumerate_states_of_turn(n::Int64)
  return (MacroState(i) for i in 0:NUM_MACROSTATE-1 if num_used(MacroState(i)) == n)
end

function compute_value_for(table, g, s)
  fill_graph!(s, g, ss -> table[ss.val+1])
  table[s.val+1] = value_of_initial_state(g)
end

function compute_value_table()
  table = Array{Float64}(undef, NUM_MACROSTATE)
  g = build_graph()

  for s in enumerate_states_of_turn(NUM_CATEGORIES)
    table[s.val+1] = upper_sec_total(s) >= 63 ? 35 : 0
  end
  println("Leaves initialized.")
  for i in NUM_CATEGORIES-1:-1:0
    ThreadsX.foreach(enumerate_states_of_turn(i)) do s
      compute_value_for(table, g, s)
    end
    println(i)
  end
  return table
end
