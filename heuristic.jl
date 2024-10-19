function backpack_sorted(r, c, m, t)
    cost_by_ressource = c./r
    cost_by_ressource = round.(cost_by_ressource, digits=4)
    agent_sorted_by_cost_and_ressources = zeros(Int64, m, t)
    for task in 1:size(cost_by_ressource)[2]
        agent_sorted_for_task = sort([(agent, cost_by_ressource[agent, task]) for agent in 1:m], rev=true, by = x -> x[2]) 
        agent_sorted_by_cost_and_ressources[:, task] = [agent for (agent, _) in agent_sorted_for_task]
    end
    sorted_task = sort([(task, cost_by_ressource[1,task]) for task in 1:t], by = x -> x[2])
    return [task for (task, _) in sorted_task], agent_sorted_by_cost_and_ressources
end

function agent_by_increasing_ressource(r, b, m, t)
    sorted_agent = zeros(Int64,  m, t)
    for task in 1:t
        agent_with_ressource = sort([(agent, r[agent,task]) for agent in 1:m], by = x -> x[2])
        sorted_agent[:, task] = [agent for (agent, _) in agent_with_ressource]
    end
    return sorted_agent
end

function first_heuristic(r, b, m, t, sorted_task, sorted_agent_by_task)
    task_to_agent = zeros(Int64, t)
    x = zeros(m, t)
    r_left = copy(b)
    for task in sorted_task
        for agent in sorted_agent_by_task[:, task]
            if r[agent, task] > r_left[agent]
                continue
            end
            r_left[agent] -= r[agent, task]
            task_to_agent[task]= agent
            x[agent, task] = 1
            break
        end
    end
    return x, task_to_agent
end

function cost_sol(c, x)
    cost = 0
    for task in 1:t
        for agent in 1:m
            cost += c[agent, task]*x[agent, task]
        end 
    end
    return cost
end

function verify_sol(x, r, b)
    sol_ok = true
    for task in 1:size(x)[2]
        if sum(x[:, task]) != 1
            println("Task $task is affected to $(sum(x[:, task])) agents")
        sol_ok = false
        end
    end
    for agent in 1:size(x)[1]
            if sum(x[agent, :] .* r[agent, :]) > b[agent]
                println("Agent $agent does not have enough ressources:  $(sum(x[agent, :] .* r[agent, :])) consumed > $(b[agent]) available.")
                sol_ok = false
        end
    end
    # if sol_ok
    #     println("Solution feasible")
    # end
    if !sol_ok
        println("Solution infeasible")
    end
    return sol_ok
end