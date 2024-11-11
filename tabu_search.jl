include("change_one_agent.jl")
include("swap_two_tasks.jl")

# Fonction principale de recherche tabou pour les voisinages de changement d'agent et d'échange
# de deux tâches
function tabu_change_and_swap(r, b, m, t, c, tabu_len, opt, x_ini, task_to_agent_ini;
                            max_iteration=1000, 
                            max_iteration_without_improvement=100, 
                            max_elapsed_time=600, 
                            minimization = false)
    # Initialize sol
    start_time = time()
    x_current, task_to_agent_current = x_ini, task_to_agent_ini
    x_best = copy(x_current)
    task_to_agent_best = copy(task_to_agent_current)
    # Initialize costs
    current_cost = cost_sol(c, x_current)
    initial_cost = copy(current_cost)
    best_cost = copy(current_cost)
    # Initialize tabu_list
    tabu_list = Vector{Tuple{Int64, Int64}}()
    it = 0
    it_without_improvement = 0 
    elapsed_time = time() - start_time
    while it < max_iteration && it_without_improvement < max_iteration_without_improvement && elapsed_time < max_elapsed_time
        it += 1
        x_current, task_to_agent_current, tabu_list, current_delta = tabu_search_random_change_or_swap(task_to_agent_current, x_current, r, b, c, tabu_list, tabu_len, task_to_agent_best)
        current_cost += current_delta
        @assert current_cost == cost_sol(c, x_current)
        @assert verify_sol(x_current, r, b)
        if current_cost > best_cost
            best_cost = current_cost
            @assert best_cost == cost_sol(c, x_current)
            x_best = copy(x_current)
            task_to_agent_best = copy(task_to_agent_current)
            it_without_improvement = 0
        else
            it_without_improvement += 1
        end
        if (best_cost*(2*(1 - minimization) -1) == opt)
            println("OPTIMAL FOUND")
            break
        end
        elapsed_time = time() - start_time
    end
    final_cost = cost_sol(c, x_best)
    @assert final_cost == best_cost
    @assert verify_sol(x_best, r, b)
    return x_best, task_to_agent_best, best_cost 
end

# Recherche locale pour le voisinage de changement d'agent dans la recherche tabou
function LS_tabu_change_agent(task_to_agent, x, neighborhood, r, b, c, best_delta, tabu_list, task_to_agent_best)
    best_neighbour = nothing
    for (agent, task) in neighborhood
        previous_agent = task_to_agent[task]
        delta_cost = delta_cost_change_one_agent(task, previous_agent, agent, c)
        if !((agent, task) in tabu_list) && delta_cost > best_delta
            best_delta = delta_cost
            best_neighbour = (agent, task)
        # Aspiration criteria
        elseif ((agent, task) in tabu_list)
            best_agent = task_to_agent_best[task]
            delta_best_cost = delta_cost_change_one_agent(task, best_agent, agent, c)
            if delta_cost > best_delta && delta_cost > delta_best_cost
                best_delta = delta_cost
                best_neighbour = (agent, task)
            end
        end
    end
    return best_delta, best_neighbour
end


# Recherche locale pour le voisinage d'échange de deux tâches dans la recherche tabou
function LS_tabu_swap_tasks(task_to_agent, x, neighborhood, r, b, c, best_delta, tabu_list, task_to_agent_best)
    best_neighbour = nothing
    for (task_1, task_2) in neighborhood
        delta_cost = delta_cost_swap_tasks(task_1, task_2, task_to_agent, c)
        if !((task_to_agent[task_2], task_1) in tabu_list) && !((task_to_agent[task_1], task_2) in tabu_list) && delta_cost > best_delta
            best_delta = delta_cost
            best_neighbour = (task_1, task_2)
        # Aspiration criteria
        elseif ((task_to_agent[task_2], task_1) in tabu_list) || ((task_to_agent[task_1], task_2) in tabu_list) 
            delta_best_cost = delta_cost_swap_tasks(task_1, task_2, task_to_agent_best, c)
            if delta_cost > best_delta && delta_cost > delta_best_cost
                best_delta = delta_cost
                best_neighbour = (task_1, task_2)
            end
        end
    end
    return best_delta, best_neighbour
end

# Une étape de recherche tabou qui prend le meilleur voisin pour le voisinage du changement et de 
# l'échange de tâches
function tabu_search_change_swap(task_to_agent, x, r, b, c, tabu_list, tabu_len, task_to_agent_best)
    best_delta = -Inf
    change_agent_neighborhood = change_one_agent(task_to_agent, x, r, b)
    swap_neighborhood = swap_task(task_to_agent, x, r, b)
    # LS change agent 
    best_delta, best_change_agent_neighbour = LS_tabu_change_agent(task_to_agent, x, change_agent_neighborhood, r, b, c, best_delta, tabu_list, task_to_agent_best)
    best_delta, best_swap_neighbour = LS_tabu_swap_tasks(task_to_agent, x, swap_neighborhood, r, b, c, best_delta, tabu_list, task_to_agent_best)
    @assert (best_change_agent_neighbour != nothing || best_swap_neighbour != nothing)
    add_to_tabu = nothing
    # If the best neighbour is swap
    if best_swap_neighbour != nothing 
        x, task_to_agent = update_sol_swap_tasks(x, task_to_agent, best_swap_neighbour)
        # Put the one with best cost in the tabu list
        if c[task_to_agent[best_swap_neighbour[1]], best_swap_neighbour[1]] >= c[task_to_agent[best_swap_neighbour[2]], best_swap_neighbour[2]]
            add_to_tabu = (task_to_agent[best_swap_neighbour[1]], best_swap_neighbour[1])
        else
            add_to_tabu = (task_to_agent[best_swap_neighbour[2]], best_swap_neighbour[2])
        end
    # If the best neighbour is change agent
    else
        x, task_to_agent = update_sol_change_one_agent(x, task_to_agent, best_change_agent_neighbour)
        add_to_tabu = best_change_agent_neighbour
    end
    
    if size(tabu_list)[1] < tabu_len
        push!(tabu_list, add_to_tabu)
    else
        popfirst!(tabu_list)
        push!(tabu_list, add_to_tabu)
    end
    @assert size(tabu_list)[1] <= tabu_len
    return x, task_to_agent, tabu_list, best_delta
end

# Une étape de recherche tabou qui prend aléatoirement le meilleur voisin pour le voisinage du changement 
# ou pour l'échange de deux tâches
function tabu_search_random_change_or_swap(task_to_agent, x, r, b, c, tabu_list, tabu_len, task_to_agent_best)
    best_delta = -Inf
    add_to_tabu = nothing
    if rand() < 0.5
        change_agent_neighborhood = change_one_agent(task_to_agent, x, r, b)
        if size(change_agent_neighborhood)[1] == 0
            return x, task_to_agent, tabu_list, 0
        end
        best_delta, best_change_agent_neighbour = LS_tabu_change_agent(task_to_agent, x, change_agent_neighborhood, r, b, c, best_delta, tabu_list, task_to_agent_best)
        if best_change_agent_neighbour == nothing
            return x, task_to_agent, tabu_list, 0
        end
        x, task_to_agent = update_sol_change_one_agent(x, task_to_agent, best_change_agent_neighbour)
        add_to_tabu = best_change_agent_neighbour
    else
        swap_neighborhood = swap_task(task_to_agent, x, r, b)
        if size(swap_neighborhood)[1] == 0
            return x, task_to_agent, tabu_list, 0
        end
        best_delta, best_swap_neighbour = LS_tabu_swap_tasks(task_to_agent, x, swap_neighborhood, r, b, c, best_delta, tabu_list, task_to_agent_best)
        if best_swap_neighbour == nothing
            return x, task_to_agent, tabu_list, 0
        end
        x, task_to_agent = update_sol_swap_tasks(x, task_to_agent, best_swap_neighbour)
        # Put the one with best cost in the tabu list
        if c[task_to_agent[best_swap_neighbour[1]], best_swap_neighbour[1]] >= c[task_to_agent[best_swap_neighbour[2]], best_swap_neighbour[2]]
            add_to_tabu = (task_to_agent[best_swap_neighbour[1]], best_swap_neighbour[1])
        else
            add_to_tabu = (task_to_agent[best_swap_neighbour[2]], best_swap_neighbour[2])
        end
    end

    if size(tabu_list)[1] < tabu_len
        push!(tabu_list, add_to_tabu)
    else
        popfirst!(tabu_list)
        push!(tabu_list, add_to_tabu)
    end
    @assert size(tabu_list)[1] <= tabu_len
    return x, task_to_agent, tabu_list, best_delta
end