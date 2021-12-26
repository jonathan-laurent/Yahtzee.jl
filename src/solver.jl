export compute_stat_table, stat_of_macro_state, stat_of_rand_state, best_action_for, best_k_actions_for

function fill_graph_for!(table::Vector{Stat}, g::MicroGame, s::MacroState)
    fill_graph!(s, g, ss -> table[ss.val+1])
end
  
function compute_stat_table(g::MicroGame)
    table = Array{Stat}(undef, NUM_MACROSTATE)
  
    for s in enumerate_states_of_turn(NUM_CATEGORIES)
      table[s.val+1] = Stat(upper_sec_total(s) >= 63 ? 35 : 0, 0)
    end
    println("Leaves initialized.")
    for i in NUM_CATEGORIES-1:-1:0
      ThreadsX.foreach(enumerate_states_of_turn(i)) do s
        fill_graph_for!(table, g, s)
        table[s.val+1] = stat_of_initial_state(g)
      end
      println(i)
    end
    return table
  end
  
function stat_of_macro_state(table::Vector{Stat}, s::MacroState)
    return table[s.val+1]
end

function stat_of_rand_state(table::Vector{Stat}, g::MicroGame, s::MacroState, ss::MicroState, i::Int64)
    fill_graph_for!(table, g, s)
    return stat_of_rand_state(g, ss, i)
end
  
function best_k_actions_for(table::Vector{Stat}, g::MicroGame, s::MacroState, ss::MicroState, i::Int64, k::Int64)
  fill_graph_for!(table, g, s)
  return best_k_actions(g, ss, i, k)
end

function best_action_for(table::Vector{Stat}, g::MicroGame, s::MacroState, ss::MicroState, i::Int64)
    fill_graph_for!(table, g, s)
    return best_action(g, ss, i)
end
