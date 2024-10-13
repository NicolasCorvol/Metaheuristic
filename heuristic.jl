function first_heuristic(r, b, m, t)
    x = zeros(m,t)
    r_left = copy(b)

    for task in 1:t
        agent_with_ressource = [(agent, r[agent,task]) for agent in 1:m]
        sorted_agent_with_ressource = sort(agent_with_ressource, by = x -> x[2])
        for (agent, ressource) in sorted_agent_with_ressource
            if ressource > r_left[agent]
                continue
            end
            r_left[agent] -= ressource
            x[agent, task] = 1
            break
        end
    end
    return x
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