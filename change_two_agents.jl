# ---------Voisinage pour le changement d'agent pour deux tâches -------------

# Construction des voisins admissibles
function change_two_agents(task_to_agent, x, r, b, m)
    neighborhood = Vector{Tuple{Int64, Int64, Int64, Int64}}()
    for task_1 in 1:size(task_to_agent)[1]
        for task_2 in task_1+1:size(task_to_agent)[1]
            for agent_1 in 1:m
                for agent_2 in 1:m 
                    if agent_1 == task_to_agent[task_1] || agent_2 == task_to_agent[task_2]
                        continue
                    end
                    if agent_1 == agent_2
                        if sum(x[agent_1, :] .* r[agent_1, :]) + r[agent_1, task_1] + r[agent_1, task_2] <= b[agent_1]
                            push!(neighborhood, (agent_1, task_1, agent_2, task_2)) 
                        end
                    else
                        if sum(x[agent_1, :] .* r[agent_1, :]) + r[agent_1, task_1] <= b[agent_1] && sum(x[agent_2, :] .* r[agent_2, :]) + r[agent_2, task_2] <= b[agent_2]
                            push!(neighborhood, (agent_1, task_1, agent_2, task_2)) 
                        end
                    end
                end
            end
        end
    end   
    return neighborhood
end


# Calcul de la différence de coût
function delta_cost_change_two_agents(previous_agent_1, task_1, previous_agent_2, task_2, new_agent_1, new_agent_2, c)
    return (c[new_agent_1, task_1] + c[new_agent_2, task_2]) - (c[previous_agent_1, task_1] + c[previous_agent_2, task_2])
end


# Modification de la solution s'il y a changement d'agent
function update_sol_change_two_agents(x, task_to_agent, best_neighbor)
    agent_before_1 = task_to_agent[best_neighbor[2]]
    agent_before_2 = task_to_agent[best_neighbor[4]]
    x[best_neighbor[1], best_neighbor[2]] = 1
    x[agent_before_1, best_neighbor[2]] = 0

    x[best_neighbor[3], best_neighbor[4]] = 1
    x[agent_before_2, best_neighbor[4]] = 0
    task_to_agent[best_neighbor[2]] = best_neighbor[1]
    task_to_agent[best_neighbor[4]] = best_neighbor[3]
    return x, task_to_agent
end


# Recherche locale pour ce voisinage de changement de deux agents
function LS_change_two_agents(task_to_agent, x, r, b, m, c, best_cost, stop)
    if !stop
        return stop, best_cost, x, task_to_agent
    end
    best_delta = 0
    best_neighbor = nothing
    neighborhood = change_two_agents(task_to_agent, x, r, b, m)
    if size(neighborhood)[1] != 0
        for (agent_1, task_1, agent_2, task_2) in neighborhood
            agent_before_1 = task_to_agent[task_1]
            agent_before_2 = task_to_agent[task_2]
            delta_cost = delta_cost_change_two_agents(agent_before_1, task_1, agent_before_2, task_2, agent_1, agent_2, c)
            if delta_cost > best_delta
                best_delta = delta_cost
                best_neighbor = (agent_1, task_1, agent_2, task_2)
                stop = false
            end
        end
    end
    if !stop
        best_cost += best_delta
        cost_before =  cost_sol(c, x)
        x, task_to_agent = update_sol_change_two_agents(x, task_to_agent, best_neighbor)
    end
    return stop, best_cost, x, task_to_agent
end
