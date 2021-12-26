using Printf

export remaining_cats, is_done, is_chance, play, interactive

const NB_SUGGESTIONS = 5

function prompt(s::State)
  is_chance(s) ?
    (crayon"red", "chance> ", crayon"reset") :
    (crayon"green", "play> ", crayon"reset")
end

function state_to_macro_micro(s::State)
    i = 0
    s.stage == CHOOSE_1 && (i = 1)
    s.stage == CHOOSE_2 && (i = 2)
    s.stage == CHOOSE_CAT && (i = 3)
    s.stage == ROLL_1 && (i = 1)
    s.stage == ROLL_2 && (i = 2)
    s.stage == ROLL_3 && (i = 3)
    
    d = s.dices.dices
    #zeros = count(==(0), d)
    ones = count(==(1), d)
    twos = count(==(2), d)
    threes = count(==(3), d)
    fours = count(==(4), d)
    fives = count(==(5), d)
    sixes = count(==(6), d)
    ss = MicroState(ones, twos, threes, fours, fives, sixes)
    
    m = INITIAL_MACROSTATE
    for c in instances(Category)
      if !isnothing(catval(s.scores, c))
        m = set_used(m, c)
      end
    end
    m = set_upper_sec_total(m, upper_score(s))
  
    return (m, ss, i)
  end

function micro_state_to_dice_config(s::MicroState)
    p = Vector{Int}()
    for _ in 1:s.to_draw
        push!(p, 0)
    end
    for (i,v) in enumerate(s.dice_values)
        for _ in 1:v
            push!(p, i)
        end
    end
    return DiceConfig(SVector{NUM_DICES}(p))
end

function suggestions_for_state(table::Vector{Float64}, g::MicroGame, state::State)
  (s, ss, i) = state_to_macro_micro(state)
  if is_chance(state)
      v = value_of_rand_state(table, g, s, ss, i) + total_score(state)
      return ((@sprintf "Expected value: %.2f" v), nothing)
  else
      actions = best_k_actions_for(table, g, s, ss, i, NB_SUGGESTIONS)
      str = ["Suggested actions:"]
      d = nothing
      for (nb,r) in enumerate(actions)
        if i == 3
          ((_,c), v) = r
          v += total_score(state)
          nb == 1 && (d = c)
          push!(str, @sprintf "%s (expected value: %.2f)" (cat_abbrev(c)) v)
        else
          (ms, v) = r
          dc = micro_state_to_dice_config(ms)
          v += total_score(state)
          nb == 1 && (d = dc)
          push!(str, @sprintf "%s (expected value: %.2f)" dc v)
        end
      end
      return (join(str, "\n"), d)
  end
end

function interactive(s::State=State(), table::Union{Nothing,Vector{Float64}}=nothing)
    prediction = _ -> nothing
    if !isnothing(table)
      g = build_graph()
      prediction = (state) -> suggestions_for_state(table, g, state)
    end
    history = [s]
    while !is_done(s)
      print("\n" ^ 20)
      println(s)
      pred = prediction(s)
      default = nothing
      if !isnothing(pred)
        (str, default) = pred
        println("$(str)\n")
      end
      print(prompt(s)...)
      inp = readline()
      inp ∈ ["q", "quit"] && break
      if inp ∈ ["u", "undo"]
        isempty(history) || (s = pop!(history))
        continue
      end
      try
        if isempty(inp)
            if is_chance(s)
                a = s.dices
            else
                a = default
            end
        else
            a = parse_action(inp)
        end
        new_st = play(s, a)
        push!(history, s)
        s = new_st
      catch
      end
    end
  end