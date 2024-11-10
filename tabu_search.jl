include("change_one_agent.jl")
include("swap_two_tasks.jl")


function tabu_change_and_swap(r, b, m, t, c, tabu_len, opt, x_ini, list_of_agent_ini, max_it, max_it_without_improvement)
    # initialize sol
    x_current, list_of_agent_current = x_ini, list_of_agent_ini
    x_best = copy(x_current)
    list_of_agent_best = copy(list_of_agent_current)
    # initialize costs
    current_cost = cost_sol(c, x_current)
    initial_cost = copy(current_cost)
    best_cost = copy(current_cost)
    # initialize tabu_list
    tabu_list = Vector{Tuple{Int64, Int64}}()
    it = 0
    it_without_improvement = 0 
    while it < max_it && it_without_improvement < max_it_without_improvement
        it += 1
        # x_current, list_of_agent_current, tabu_list, current_delta = tabu_search_change_swap(list_of_agent_current, x_current, r, b, c, tabu_list, tabu_len, list_of_agent_best)
        x_current, list_of_agent_current, tabu_list, current_delta = tabu_search_random_change_or_swap(list_of_agent_current, x_current, r, b, c, tabu_list, tabu_len, list_of_agent_best)
        
        current_cost += current_delta
        @assert current_cost == cost_sol(c, x_current)
        @assert verify_sol(x_current, r, b)
        if current_cost > best_cost
            best_cost = current_cost
            @assert best_cost == cost_sol(c, x_current)
            x_best = copy(x_current)
            list_of_agent_best = copy(list_of_agent_current)
            it_without_improvement = 0
        else
            it_without_improvement += 1
        end
        if (best_cost == opt)
            println("OPTIMAL FOUND")
            break
        end
    end
    # println("best cost", best_feasible_cost, " ", cost_sol(c, best_x_feasible))
    final_cost = cost_sol(c, x_best)
    @assert final_cost == best_cost
    @assert verify_sol(x_best, r, b)
    # if best_cost > initial_cost
    #     println("best cost tabu")
        # println("Optimum=$opt / final value=$best_cost / gap=$(opt-best_cost)")
    # end
    return x_best, list_of_agent_best, best_cost 
end

function LS_tabu_change_agent(list_of_agent, x, neighborhood, r, b, c, best_delta, tabu_list, list_of_agent_best)
    best_neighbour = nothing
    for (agent, task) in neighborhood
        previous_agent = list_of_agent[task]
        delta_cost = delta_cost_change_one_agent(task, previous_agent, agent, c)
        if !((agent, task) in tabu_list) && delta_cost > best_delta
            best_delta = delta_cost
            best_neighbour = [(agent, task)]
        # Critère d'aspitation
        elseif ((agent, task) in tabu_list)
            best_agent = list_of_agent_best[task]
            delta_best_cost = delta_cost_change_one_agent(task, best_agent, agent, c)
            if delta_cost > best_delta && delta_cost > delta_best_cost
                best_delta = delta_cost
                best_neighbour = [(agent, task)]
            end
        end
    end
    return best_delta, best_neighbour
end

function LS_tabu_swap_tasks(list_of_agent, x, neighborhood, r, b, c, best_delta, tabu_list, list_of_agent_best)
    best_neighbour = nothing
    for (task_1, task_2) in neighborhood
        previous_agent_1 = list_of_agent[task_1]
        previous_agent_2 = list_of_agent[task_2]
        delta_cost = delta_cost_swap_tasks(previous_agent_1, task_1, previous_agent_2, task_2, c)
        if !((list_of_agent[task_2], task_1) in tabu_list) && !((list_of_agent[task_1], task_2) in tabu_list) && delta_cost > best_delta
            best_delta = delta_cost
            best_neighbour = [(list_of_agent[task_2], task_1), (list_of_agent[task_1], task_2)]
        # Critère d'aspitation
        elseif ((list_of_agent[task_2], task_1) in tabu_list) || ((list_of_agent[task_1], task_2) in tabu_list) 
            agent_1_best_cost = list_of_agent_best[task_1]
            agent_2_best_cost = list_of_agent_best[task_2]
            delta_best_cost = delta_cost_swap_tasks(agent_1_best_cost, task_1, agent_2_best_cost, task_2, c)
            if delta_cost > best_delta && delta_cost > delta_best_cost
                best_delta = delta_cost
                best_neighbour = [(list_of_agent[task_2], task_1), (list_of_agent[task_1], task_2)]
            end
        end
    end
    return best_delta, best_neighbour
end

function tabu_search_change_swap(list_of_agent, x, r, b, c, tabu_list, tabu_len, list_of_agent_best)
    best_delta = -Inf
    change_agent_neighborhood = change_one_agent(list_of_agent, x, r, b)
    swap_neighborhood = swap_task(list_of_agent, x, r, b)
    # LS change agent 
    best_delta, best_change_agent_neighbour = LS_tabu_change_agent(list_of_agent, x, change_agent_neighborhood, r, b, c, best_delta, tabu_list, list_of_agent_best)
    best_delta, best_swap_neighbour = LS_tabu_swap_tasks(list_of_agent, x, swap_neighborhood, r, b, c, best_delta, tabu_list, list_of_agent_best)
    @assert (best_change_agent_neighbour != nothing || best_swap_neighbour != nothing)
    add_to_tabu = nothing
    # if the best neighbour is swap
    if best_swap_neighbour != nothing 
        # update sol
        x, list_of_agent = update_sol_swap_tasks(x, list_of_agent, (best_swap_neighbour[1][2], best_swap_neighbour[2][2]))
        # put the one with best cost in the tabu list
        if c[best_swap_neighbour[1][1], best_swap_neighbour[1][2]] >= c[best_swap_neighbour[2][1], best_swap_neighbour[2][2]]
            add_to_tabu = best_swap_neighbour[1]
        else
            add_to_tabu = best_swap_neighbour[2]
        end
    # if the best neighbour is change agent
    else
        x, list_of_agent = update_sol_change_one_agent(x, list_of_agent, best_change_agent_neighbour[1])
        add_to_tabu = best_change_agent_neighbour[1]
    end
    
    if size(tabu_list)[1] < tabu_len
        push!(tabu_list, add_to_tabu)
    else
        popfirst!(tabu_list)
        ## Que faire dans le cas du critère d'aspiration ??
        push!(tabu_list, add_to_tabu)
    end
    @assert size(tabu_list)[1] <= tabu_len
    return x, list_of_agent, tabu_list, best_delta
end

function tabu_search_random_change_or_swap(list_of_agent, x, r, b, c, tabu_list, tabu_len, list_of_agent_best)
    best_delta = -Inf
    add_to_tabu = nothing
    if rand() < 0.5
        change_agent_neighborhood = change_one_agent(list_of_agent, x, r, b)
        if size(change_agent_neighborhood)[1] == 0
            return x, list_of_agent, tabu_list, 0
        end
        best_delta, best_change_agent_neighbour = LS_tabu_change_agent(list_of_agent, x, change_agent_neighborhood, r, b, c, best_delta, tabu_list, list_of_agent_best)
        if best_change_agent_neighbour == nothing
            return x, list_of_agent, tabu_list, 0
        end
        x, list_of_agent = update_sol_change_one_agent(x, list_of_agent, best_change_agent_neighbour[1])
        add_to_tabu = best_change_agent_neighbour[1]
    else
        swap_neighborhood = swap_task(list_of_agent, x, r, b)
        if size(swap_neighborhood)[1] == 0
            return x, list_of_agent, tabu_list, 0
        end
        best_delta, best_swap_neighbour = LS_tabu_swap_tasks(list_of_agent, x, swap_neighborhood, r, b, c, best_delta, tabu_list, list_of_agent_best)
        if best_swap_neighbour == nothing
            return x, list_of_agent, tabu_list, 0
        end
        # update sol
        x, list_of_agent = update_sol_swap_tasks(x, list_of_agent, (best_swap_neighbour[1][2], best_swap_neighbour[2][2]))
        # put the one with best cost in the tabu list
        if c[best_swap_neighbour[1][1], best_swap_neighbour[1][2]] >= c[best_swap_neighbour[2][1], best_swap_neighbour[2][2]]
            add_to_tabu = best_swap_neighbour[1]
        else
            add_to_tabu = best_swap_neighbour[2]
        end
    end

    if size(tabu_list)[1] < tabu_len
        push!(tabu_list, add_to_tabu)
    else
        popfirst!(tabu_list)
        ## Que faire dans le cas du critère d'aspiration ??
        push!(tabu_list, add_to_tabu)
    end
    @assert size(tabu_list)[1] <= tabu_len
    return x, list_of_agent, tabu_list, best_delta
end