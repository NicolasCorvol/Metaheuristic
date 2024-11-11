# ---------Voisinage pour l'échange de deux tâches d'agents différents -------------

# Construction des voisins admissibles
function swap_task(task_to_agent, x, r, b)
    neighborhood = Vector{Tuple{Int64, Int64}}()
    for task_1 in 1:size(task_to_agent)[1]
        for task_2 in task_1+1:size(task_to_agent)[1]
            agent_1 = task_to_agent[task_1] 
            agent_2 = task_to_agent[task_2] 
            if agent_1 == agent_2
                continue
            end
            if sum(x[agent_1, :] .* r[agent_1, :]) + r[agent_1, task_2] - r[agent_1, task_1] <= b[agent_1] && sum(x[agent_2, :] .* r[agent_2, :]) + r[agent_2, task_1] - r[agent_2, task_2] <= b[agent_2] 
                push!(neighborhood, (task_1, task_2))
            end
        end
    end
    return neighborhood
end


# Calcul de la différence de coût
function delta_cost_swap_tasks(task_1, task_2, task_to_agent, c)
    previous_agent_1 = task_to_agent[task_1]
    previous_agent_2 = task_to_agent[task_2]
    return (c[previous_agent_1, task_2] + c[previous_agent_2, task_1])  - (c[previous_agent_1, task_1] + c[previous_agent_2, task_2])
end


# Mise à jour de la solution après échange de deux tâches
function update_sol_swap_tasks(x, task_to_agent, best_neighbor)
    task_1 = best_neighbor[1]
    task_2 = best_neighbor[2]
    agent_1_before = task_to_agent[task_1]
    agent_2_before = task_to_agent[task_2]
    # task_1 to agent_2
    x[agent_1_before, task_1] = 0
    x[agent_2_before, task_1] = 1
    task_to_agent[task_1] = agent_2_before
    # task_2 to agent_1
    x[agent_2_before, task_2] = 0
    x[agent_1_before, task_2] = 1
    task_to_agent[task_2] = agent_1_before
    return x, task_to_agent
end


# Recherche locale pour ce voisinage d'échange de deux tâches
function LS_swap_tasks(task_to_agent, x, r, b, m, c, best_cost, stop)
    if !stop
        return stop, best_cost, x, task_to_agent
    end
    best_delta = 0
    best_neighbor = nothing
    neighborhood = swap_task(task_to_agent, x, r, b)
    if size(neighborhood)[1] != 0
        for (task_1, task_2) in neighborhood
            delta_cost = delta_cost_swap_tasks(task_1, task_2, task_to_agent, c)
            if delta_cost > best_delta
                best_delta = delta_cost
                best_neighbor = (task_1, task_2)
                stop = false
            end
        end
    end
    if !stop
        best_cost += best_delta
        x, task_to_agent = update_sol_swap_tasks(x, task_to_agent, best_neighbor)
    end
    return stop, best_cost, x, task_to_agent
end


# Effectue un deux-échange aléatoire parmi tout ceux réalisables 
function random_two_task_swap(x, task_to_agent, current_cost, r, b, c)
    neighborhood = swap_task(task_to_agent, x, r, b)
    if size(neighborhood)[1] == 0
        return false, x, task_to_agent, current_cost
    end
    random_neighbor = rand(neighborhood)
    task_1 = random_neighbor[1]
    task_2 = random_neighbor[2]
    delta_cost = delta_cost_swap_tasks(task_1, task_2, task_to_agent, c)
    current_cost += delta_cost
    x, task_to_agent = update_sol_swap_tasks(x, task_to_agent, random_neighbor)
    return true, x, task_to_agent, current_cost 
end