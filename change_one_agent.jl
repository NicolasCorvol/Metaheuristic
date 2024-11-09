include("heuristic.jl")

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

function delta_cost_change_one_agent(task, previous_agent, new_agent, c)
    return c[new_agent, task] - c[previous_agent, task]
end

function update_sol_change_one_agent(x, list_of_agent, best_neighbor)
    agent_before = list_of_agent[best_neighbor[2]]
    x[best_neighbor[1], best_neighbor[2]] = 1
    x[agent_before, best_neighbor[2]] = 0
    list_of_agent[best_neighbor[2]] = best_neighbor[1]
    return x, list_of_agent
end

# Recherche locale pour change one agent 
function RL_change_one_agent(list_of_agent, x, r, b, m, c, best_cost, stop)
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

# Recherche Tabou pour le voisinage Change one agent 
# Les tâches dont on change l'agent sont placées dans la liste tabou
function RL_tabou_change_one_agent(list_of_agent, x, r, b, m, c, tabou_list, taboulen, best_cost)
    stop = true
    new_cost = -Inf
    best_neighbor = nothing
    neighborhood = change_one_agent(list_of_agent, x, r, b)
    if size(neighborhood)[1] == 0
        return stop, x, list_of_agent, tabou_list, -1
    end
    for (agent, task) in neighborhood
        x_temp = copy(x)
        list_of_agent_temp = copy(list_of_agent)
        agent_before = list_of_agent[task]
        ## Ici il serait plus optimal de calculer un delta cost aussi !
        # je n'ai pas réussi pour le moment mais il faudrait ne pas modifier la liste et calculer juste
        # le delta cost 
        x_temp, list_of_agent_temp = update_sol_change_one_agent(x_temp, list_of_agent_temp, (agent, task))
        cost = cost_sol(c, x_temp)
        if !(task in tabou_list) && cost > new_cost
            new_cost = cost
            best_neighbor = (agent, task)
            stop = false
        end
        # Critère d'aspitation
        if (task in tabou_list) && cost > best_cost
            new_cost = cost
            best_neighbor = (agent, task)
            stop = false
        end
    end

    if stop
        return stop, x, list_of_agent, tabou_list, -1 
    end
    x, list_of_agent = update_sol_change_one_agent(x, list_of_agent, best_neighbor)
    if size(tabou_list)[1] < taboulen
        push!(tabou_list, best_neighbor[2])
    else
        popfirst!(tabou_list)
        ## Que faire dans le cas du critère d'aspiration ??
        push!(tabou_list, best_neighbor[2])
    end
    @assert size(tabou_list)[1] <= taboulen
    return stop, x, list_of_agent, tabou_list, new_cost
end
