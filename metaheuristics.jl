include("heuristic.jl")
include("change_one_agent.jl")
include("change_two_agents.jl")
include("swap_two_tasks.jl")
include("swap_three_tasks.jl")

function descente_VND(r, b, m, t, c, opt, x, list_of_agent)
    @assert verify_sol(x, r, b)
    initial_cost = cost_sol(c, x)
    best_cost = initial_cost
    stop = false
    it = 0  
    while !stop && it < 1000
        it += 1
        stop = true
        stop, best_cost, x, list_of_agent = RL_change_one_agent(list_of_agent, x, r, b, m, c, best_cost, stop)
        if stop
            stop, best_cost, x, list_of_agent = RL_swap_tasks(list_of_agent, x, r, b, m, c, best_cost, stop)
        end
        if stop
            stop, best_cost, x, list_of_agent = RL_swap_three_tasks(list_of_agent, x, r, b, m, c, best_cost, stop)
        end
        @assert verify_sol(x, r, b)
        # println(best_cost, " ",  cost_sol(c, x))
        if best_cost == opt
            stop = true
            println("OPTIMAL FOUND")
        end
    end
    final_cost = cost_sol(c, x)
    @assert final_cost == best_cost
    @assert best_cost >= initial_cost
    @assert verify_sol(x, r, b)
    
    # println("number of iterations: $it")
    # println("improvement: \n final cost: $best_cost VS opt : $opt")
    return x
end


function descente_tabou_change_agent(x, list_of_agent, r, b, m, t, c, taboulen, opt)
    x_current = x
    list_of_agent_current = list_of_agent
    x_best = copy(x_current)
    list_of_agents_best = copy(list_of_agent_current)
    best_cost = cost_sol(c, x_current)
    current_cost = copy(best_cost)
    tabou_list = Vector{Int64}()
    it = 0  
    stop = false
    while !stop && it < 1000
        it += 1
        stop, x_current, list_of_agent_current, tabou_list, new_cost = RL_tabou_change_one_agent(list_of_agent_current, x_current, r, b, m, c, tabou_list, taboulen, best_cost)
        if !stop
            current_cost = new_cost
            if new_cost > best_cost
                x_best = copy(x_current)
                list_of_agents_best = copy(list_of_agent_current)
                best_cost = copy(new_cost)
            end
            @assert verify_sol(x_current, r, b)
        end
        if (best_cost == opt)
            println("OPTIMAL FOUND")
            stop = true
        end
    end
    final_cost = cost_sol(c, x_best)
    @assert final_cost == best_cost
    @assert verify_sol(x_best, r, b)
    return x_best, list_of_agents_best
end

function descente_tabou_after_descente_swap(r, b, m, t, c, opt, taboulen)
    sorted_task, sorted_agent = backpack_sorted(r, b, m, t)
    x, list_of_agent = glouton_heuristic(r, b, m, t, sorted_task, sorted_agent)
    ## descente swap
    x, list_of_agent = descente_VND(r, b, m, t, c, opt, x, list_of_agent)
    @assert verify_sol(x, r, b)
    cost_after_descente = cost_sol(c, x)
    println("Cost after descente sol: ", cost_after_descente, " VS OPT: ", opt, "==> GAP = ", opt-cost_after_descente)
    if cost_sol(c, x) < opt
        println("Descente tabou")
        ## descente tabou
        x, list_of_agent = descente_tabou_change_agent(x, list_of_agent, r, b, m, t, c, taboulen, opt)
    end
    @assert verify_sol(x, r, b)
    println("Cost final sol: ", cost_sol(c, x), " VS OPT: ", opt, " Tabou improvement", cost_sol(c, x) - cost_after_descente, "==> GAP = ", opt-cost_sol(c,x) )
    return x
end


function descente_change_agent(r, b, m, t, c, opt, x, list_of_agent)
    @assert verify_sol(x, r, b)
    initial_cost = cost_sol(c, x)
    best_cost = initial_cost
    stop = false
    it = 0  
    while !stop && it < 1000
        it += 1
        stop = true
        stop, best_cost, x, list_of_agent = RL_change_one_agent(list_of_agent, x, r, b, m, c, best_cost, stop)
        @assert verify_sol(x, r, b)
        # println(best_cost, " ",  cost_sol(c, x))
        if best_cost == opt
            stop = true
            println("OPTIMAL FOUND")
        end
    end
    final_cost = cost_sol(c, x)
    @assert final_cost == best_cost
    @assert best_cost >= initial_cost
    @assert verify_sol(x, r, b)
    
    # println("number of iterations: $it")
    # println("improvement: \n final cost: $best_cost VS opt : $opt")
    return x
end


function descente_tabou(r, b, m, t, c, taboulen, opt, x_ini, list_of_agent_ini)
    x_current, list_of_agent_current = x_ini, list_of_agent_ini
    x_best = copy(x_current)
    list_of_agents_best = copy(list_of_agent_current)
    # println(list_of_agents_best)
    @assert verify_sol(x_current, r, b)
    initial_cost = cost_sol(c, x_current)
    best_cost = initial_cost
    current_cost = copy(best_cost)
    tabou_list = Vector{Int64}()
    it = 0  
    stop = false
    while !stop && it < 1000
        it += 1
        stop, x_current, list_of_agent_current, tabou_list, new_cost = RL_tabou_change_one_agent(list_of_agent_current, x_current, r, b, m, c, tabou_list, taboulen, best_cost)
        if !stop
            current_cost = new_cost
            if new_cost > best_cost
                x_best = copy(x_current)
                list_of_agents_best = copy(list_of_agent_current)
                best_cost = copy(new_cost)
                # println("best cost ", best_cost, " x_best cost ", cost_sol(c, x_best))
            end
            @assert verify_sol(x_current, r, b)
        end
        if (best_cost == opt)
            println("OPTIMAL FOUND")
            stop = true
        end
    end
    # println("best cost", best_cost, " ", cost_sol(c, x_best))
    final_cost = cost_sol(c, x_best)
    @assert final_cost == best_cost
    @assert best_cost >= initial_cost
    @assert verify_sol(x_current, r, b)
    
    # println("Optimum $opt VS final value $best_cost")
    return x_best
end


function VND_random_swap_then_RL_change_agent(r, b, m, t, c, opt)
    sorted_task, sorted_agent = backpack_sorted(r, b, m, t)
    x_current, list_of_agent_current = glouton_heuristic(r, b, m, t, sorted_task, sorted_agent)
    x_best = copy(x_current)
    list_of_agents_best = copy(list_of_agent_current)
    current_cost = cost_sol(c, x_current)
    best_cost = copy(current_cost)
    stop = false
    it = 0
    nb_2_swap = 0
    nb_3_swap = 0
    while it < 10000
        it += 1
        can_two_swap, x_current, list_of_agent_current, current_cost = random_two_task_swap(x_current, list_of_agent_current, current_cost, r, b, c)
        if can_two_swap
            nb_2_swap += 1
            _, current_cost, x_current, list_of_agent_current = RL_change_one_agent(list_of_agent_current, x_current, r, b, m, c, current_cost, stop)
        end
        if current_cost > best_cost
            @assert cost_sol(c, x_current) == current_cost
            best_cost = copy(current_cost)
            x_best = copy(x_current)
            list_of_agents_best = copy(list_of_agent_current)
        else
            can_three_swap, x_current, list_of_agent_current, current_cost = random_three_task_swap(x_current, list_of_agent_current, current_cost, r, b, c)
            if can_three_swap
                nb_3_swap += 1
                stop, current_cost, x_current, list_of_agent_current = RL_change_one_agent(list_of_agent_current, x_current, r, b, m, c, current_cost, stop)
            end
        end
        if current_cost > best_cost
            @assert cost_sol(c, x_current) == current_cost
            best_cost = copy(current_cost)
            x_best = copy(x_current)
            list_of_agents_best = copy(list_of_agent_current)
        end
        @assert verify_sol(x_current, r, b)
        if best_cost == opt
            stop = true
            println("OPTIMAL FOUND")
        end
    end
    println("nb_2_swap ", nb_2_swap)
    println("nb_3_swap ", nb_3_swap)
    final_cost = cost_sol(c, x_best)
    @assert final_cost == best_cost
    @assert verify_sol(x_best, r, b)
    
    println("number of iterations: $it")
    println("improvement: \n final cost: $best_cost VS opt : $opt ==> GAP = $(opt-best_cost)")
    return x_best
end