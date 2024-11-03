## Swap two tasks

function check_swap_is_possible(x, r, b, task_1, agent_1, task_2, agent_2, task_3, agent_3)
    """This function checks if this swap is possible: 
    1 -> 2 // 2 -> 3 // 3 -> 1
    """    
    if sum(x[agent_1, :] .* r[agent_1, :]) + r[agent_1, task_3] - r[agent_1, task_1] > b[agent_1]
        return false
    end
    if sum(x[agent_2, :] .* r[agent_2, :]) + r[agent_2, task_1] - r[agent_2, task_2] > b[agent_2]
        return false
    end
    if sum(x[agent_3, :] .* r[agent_3, :]) + r[agent_3, task_2] - r[agent_3, task_3] > b[agent_3]
        return false
    end
    return true
end

function swap_three_tasks(list_of_agent, x, r, b)
    neighborhood = Vector{Tuple{Int64, Int64, Int64}}()
    for task_1 in 1:size(list_of_agent)[1]
        for task_2 in task_1+1:size(list_of_agent)[1]
            for task_3 in 1+task_2:size(list_of_agent)[1]
                agent_1 = list_of_agent[task_1] 
                agent_2 = list_of_agent[task_2] 
                agent_3 = list_of_agent[task_3]
                if agent_1 == agent_2 || agent_2 == agent_3 || agent_1 == agent_3
                    continue
                end
                # 1 -> 2 // 2 -> 3 // 3 -> 1
                if check_swap_is_possible(x, r, b, task_1, agent_1, task_2, agent_2, task_3, agent_3)
                    push!(neighborhood, (task_1, task_2, task_3))
                end
                # 1 -> 3 // 3 -> 2 // 2 -> 1
                if check_swap_is_possible(x, r, b, task_1, agent_1, task_3, agent_3, task_2, agent_2)
                    push!(neighborhood, (task_1, task_3, task_2))
                end
            end
        end
    end
    return neighborhood
end

function delta_cost_swap_three_tasks(task_1, previous_agent_1, task_2, previous_agent_2, task_3, previous_agent_3, c)
    """Calculate the delta cost of the swap 1 -> 2 // 2 -> 3 // 3 -> 1 """  
    new_cost = c[previous_agent_1, task_3] + c[previous_agent_2, task_1] + c[previous_agent_3, task_2]
    previous_cost = c[previous_agent_1, task_1] + c[previous_agent_2, task_2] + c[previous_agent_3, task_3]    
    return new_cost - previous_cost 
end

function update_sol_swap_three_tasks(x, list_of_agent, best_neighbor)
    """Returns the new solutions after swaping the tasks."""    
    task_1 = best_neighbor[1]
    task_2 = best_neighbor[2]
    task_3 = best_neighbor[3]
    agent_1_before = list_of_agent[task_1]
    agent_2_before = list_of_agent[task_2]
    agent_3_before = list_of_agent[task_3]
    # task_1 to agent_2
    x[agent_1_before, task_1] = 0
    x[agent_2_before, task_1] = 1
    list_of_agent[task_1] = agent_2_before
    # task_2 to agent_3
    x[agent_2_before, task_2] = 0
    x[agent_3_before, task_2] = 1
    list_of_agent[task_2] = agent_3_before
    # task_3 to agent_1
    x[agent_3_before, task_3] = 0
    x[agent_1_before, task_3] = 1
    list_of_agent[task_3] = agent_1_before
    return x, list_of_agent
end

function RL_swap_three_tasks(list_of_agent, x, r, b, m, c, best_cost, stop)
    if !stop
        return stop, best_cost, x, list_of_agent
    end
    best_delta = 0
    best_neighbor = nothing
    neighborhood = swap_three_tasks(list_of_agent, x, r, b)
    if size(neighborhood)[1] != 0
        for (task_1, task_2, task_3) in neighborhood
            agent_1_before = list_of_agent[task_1]
            agent_2_before = list_of_agent[task_2]
            agent_3_before = list_of_agent[task_3]
            delta_cost = delta_cost_swap_three_tasks(task_1, agent_1_before, task_2, agent_2_before, task_3, agent_3_before, c)
            if delta_cost > best_delta
                best_delta = delta_cost
                best_neighbor = (task_1, task_2, task_3)
                stop = false
            end
        end
    end
    if !stop
        # println(best_delta)
        best_cost += best_delta
        x, list_of_agent = update_sol_swap_three_tasks(x, list_of_agent, best_neighbor)
    end
    return stop, best_cost, x, list_of_agent
end

function random_three_task_swap(x, list_of_agent, current_cost, r, b, c)
    neighborhood = swap_three_tasks(list_of_agent, x, r, b)
    if size(neighborhood)[1] == 0
        return false, x, list_of_agent, current_cost
    end
    random_neighbor = rand(neighborhood)
    task_1 = random_neighbor[1]
    task_2 = random_neighbor[2]
    task_3 = random_neighbor[3]
    agent_1_before = list_of_agent[task_1]
    agent_2_before = list_of_agent[task_2]
    agent_3_before = list_of_agent[task_3]
    delta_cost = delta_cost_swap_three_tasks(task_1, agent_1_before, task_2, agent_2_before, task_3, agent_3_before, c)
    current_cost += delta_cost
    x, list_of_agent = update_sol_swap_three_tasks(x, list_of_agent, random_neighbor)
    return true, x, list_of_agent, current_cost 
end