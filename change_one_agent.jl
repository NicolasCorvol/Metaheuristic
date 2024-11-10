# ---------Voisinage pour le changement d'agent pour une tâche -------------

# Construction des voisins admissibles
function change_one_agent(list_of_agent, x, r, b)
    neighborhood = Vector{Tuple{Int64, Int64}}()
    for task in 1:size(list_of_agent)[1]
        for agent in 1:size(x)[1] 
            if agent == list_of_agent[task]
                continue
            end
            if sum(x[agent, :] .* r[agent, :]) + r[agent, task] <= b[agent]
                push!(neighborhood, (agent, task)) 
            end
        end
    end   
    return neighborhood
end


# Calcul de la différence de coût
function delta_cost_change_one_agent(task, previous_agent, new_agent, c)
    return c[new_agent, task] - c[previous_agent, task]
end


# Modification de la solution s'il y a changement d'agent
function update_sol_change_one_agent(x, list_of_agent, best_neighbor)
    agent_before = list_of_agent[best_neighbor[2]]
    x[best_neighbor[1], best_neighbor[2]] = 1
    x[agent_before, best_neighbor[2]] = 0
    list_of_agent[best_neighbor[2]] = best_neighbor[1]
    return x, list_of_agent
end


# Recherche locale pour ce voisinage de changement d'agent
function LS_change_one_agent(list_of_agent, x, r, b, m, c, best_cost, stop)
    if !stop
        return stop, best_cost, x, list_of_agent
    end
    best_delta = 0
    best_neighbor = nothing
    neighborhood = change_one_agent(list_of_agent, x, r, b)
    if size(neighborhood)[1] != 0
        for (agent, task) in neighborhood
            agent_before = list_of_agent[task]
            delta_cost = delta_cost_change_one_agent(task, agent_before, agent, c)
            if delta_cost > best_delta
                best_delta = delta_cost
                best_neighbor = (agent, task)
                stop = false
            end
        end
    end
    if !stop
        best_cost += best_delta
        x, list_of_agent = update_sol_change_one_agent(x, list_of_agent, best_neighbor)
    end
    return stop, best_cost, x, list_of_agent
end