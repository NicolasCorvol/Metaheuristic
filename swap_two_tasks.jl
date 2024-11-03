## Swap two tasks

# Fonction renvoyant le voisinage sous la forme de couple 
# de tâche à swap
function swap_task(list_of_agent, x, r, b)
    neighborhood = Vector{Tuple{Int64, Int64}}()
    for task_1 in 1:size(list_of_agent)[1]
        for task_2 in task_1+1:size(list_of_agent)[1]
            agent_1 = list_of_agent[task_1] 
            agent_2 = list_of_agent[task_2] 
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

function delta_cost_swap_tasks(previous_agent_1, task_1, previous_agent_2, task_2, c)
    return c[previous_agent_1, task_2] + c[previous_agent_2, task_1]  - (c[previous_agent_1, task_1] + c[previous_agent_2, task_2])
end

# Fonction qui effectue le swap
function update_sol_swap_tasks(x, list_of_agent, best_neighbor)
    task_1 = best_neighbor[1]
    task_2 = best_neighbor[2]
    agent_1_before = list_of_agent[task_1]
    agent_2_before = list_of_agent[task_2]
    # task_1 to agent_2
    x[agent_1_before, task_1] = 0
    x[agent_2_before, task_1] = 1
    list_of_agent[task_1] = agent_2_before
    # task_2 to agent_1
    x[agent_2_before, task_2] = 0
    x[agent_1_before, task_2] = 1
    list_of_agent[task_2] = agent_1_before
    return x, list_of_agent
end

# Recherche locale du swap 
function RL_swap_tasks(list_of_agent, x, r, b, m, c, best_cost, stop)
    if !stop
        return stop, best_cost, x, list_of_agent
    end
    best_delta = 0
    best_neighbor = nothing
    neighborhood = swap_task(list_of_agent, x, r, b)
    if size(neighborhood)[1] != 0
        for (task_1, task_2) in neighborhood
            agent_1_before = list_of_agent[task_1]
            agent_2_before = list_of_agent[task_2]
            delta_cost = delta_cost_swap_tasks(agent_1_before, task_1, agent_2_before, task_2, c)
            if delta_cost > best_delta
                best_delta = delta_cost
                best_neighbor = (task_1, task_2)
                stop = false
            end
        end
    end
    if !stop
        best_cost += best_delta
        x, list_of_agent = update_sol_swap_tasks(x, list_of_agent, best_neighbor)
    end
    return stop, best_cost, x, list_of_agent
end

# Effectue un swap random parmis tout ceux réalisables 
function random_two_task_swap(x, list_of_agent, current_cost, r, b, c)
    neighborhood = swap_task(list_of_agent, x, r, b)
    if size(neighborhood)[1] == 0
        return false, x, list_of_agent, current_cost
    end
    random_neighbor = rand(neighborhood)
    task_1 = random_neighbor[1]
    task_2 = random_neighbor[2]
    agent_1_before = list_of_agent[task_1]
    agent_2_before = list_of_agent[task_2]
    delta_cost = delta_cost_swap_tasks(agent_1_before, task_1, agent_2_before, task_2, c)
    current_cost += delta_cost
    x, list_of_agent = update_sol_swap_tasks(x, list_of_agent, random_neighbor)
    return true, x, list_of_agent, current_cost 
end