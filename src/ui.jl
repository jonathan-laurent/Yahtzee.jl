export remaining_cats, is_done, is_chance, play, interactive

function state_to_macro_micro(s::State)
    i = 0
    s.stage == CHOOSE_1 && (i = 1)
    s.stage == CHOOSE_2 && (i = 2)
    s.stage == CHOOSE_CAT && (i = 3)
    
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
    score = sum(catval(s.scores, c) for c in UPPER_CATEGORIES if !isnothing(catval(s.scores, c)); init=0)
    m = set_upper_sec_total(m, score)
  
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

function interactive(s::State=State(), table::Union{Nothing,Vector{Float64}}=nothing)
    prediction = _ -> nothing
    if !isnothing(table)
      g = build_graph()
      prediction = function (s)
        (s, ss, i) = state_to_macro_micro(s)
        if i == 0
            return nothing
        else
            res = best_action_for(table, g, s, ss, i)
            if i == 3
                ((_,c), v) = res
                return ("$(cat_abbrev(c)) (expected value: $(v))", c)
            else
                (ms, v) = res
                dc = micro_state_to_dice_config(ms)
                return ("$(dc) (expected value: $(v))", dc)
            end
        end
      end
    end
    history = [s]
    while !is_done(s)
      print("\n" ^ 20)
      println(s)
      pred = prediction(s)
      default = nothing
      if !isnothing(pred)
        (str, default) = pred
        println("Recommended action: $(str)")
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