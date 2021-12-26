export compute_value_table, value_of_macro_state, value_of_rand_state, best_action_for

function fill_graph_for!(table, g, s)
    fill_graph!(s, g, ss -> table[ss.val+1])
end
  
function compute_value_table(g::MicroGame)
    table = Array{Float64}(undef, NUM_MACROSTATE)
  
    for s in enumerate_states_of_turn(NUM_CATEGORIES)
      table[s.val+1] = upper_sec_total(s) >= 63 ? 35 : 0
    end
    println("Leaves initialized.")
    for i in NUM_CATEGORIES-1:-1:0
      ThreadsX.foreach(enumerate_states_of_turn(i)) do s
        fill_graph_for!(table, g, s)
        table[s.val+1] = value_of_initial_state(g)
      end
      println(i)
    end
    return table
  end
  
function value_of_macro_state(table::Vector{Float64}, s::MacroState)
    return table[s.val+1]
end

function value_of_rand_state(table::Vector{Float64}, g::MicroGame, s::MacroState, ss::MicroState, i::Int64)
    fill_graph_for!(table, g, s)
    return value_of_rand_state(g, ss, i)
end
  
function best_action_for(table::Vector{Float64}, g::MicroGame, s::MacroState, ss::MicroState, i::Int64)
    fill_graph_for!(table, g, s)
    return best_action(g, ss, i)
end
