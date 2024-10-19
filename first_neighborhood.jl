include("heuristic.jl")

function change_agent(x)
    neighborhood = [(agent, task) for task in 1:size(x)[2] for agent in 1:size(x)[1] if agent != findfirst(a -> a == 1, x[:, task])]
    return neighborhood
end

function feasible_change_agent_2(list_of_agent, x, r, b)
    neighborhood = Vector{Tuple{Int64, Int64}}()
    for task in 1:size(list_of_agent)[1]
        for agent in 1:m 
            if agent == list_of_agent[task]
                continue
            end
            if sum(x[agent, :] .* r[agent, :]) + r[agent, task] <= b[agent]
                push!(neighborhood, (agent, task)) 
            end
        end
    end   
    # neighborhood = [(agent, task) for task in 1:size(list_of_agent)[1] for agent in 1:m if agent != list_of_agent[task]]
    return neighborhood
end

function swap_agent(list_of_agent, x, r, b)
    neighborhood = Vector{Tuple{Int64, Int64}}()
    for task_1 in 1:t
        for task_2 in task_1:t
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



function descente(r, b, m, t, c)
    sorted_task, sorted_agent = backpack_sorted(r, b, m, t)
    x, list_of_agent = first_heuristic(r, b, m, t, sorted_task, sorted_agent)
    @assert verify_sol(x, r, b)
    initial_cost = cost_sol(c, x)
    best_cost = initial_cost
    stop = false
    it = 0  
    while !stop && it < 1000
        it += 1
        stop = true
        best_delta = 0
        best_neighbor = nothing
        neighborhood = feasible_change_agent_2(list_of_agent, x, r, b)
        if size(neighborhood)[1] != 0
            for (agent, task) in neighborhood
                agent_before = list_of_agent[task]
                delta_cost = c[agent, task] - c[agent_before, task]
                if delta_cost > best_delta
                    best_delta = delta_cost
                    best_neighbor = (agent, task)
                    stop = false
                end
            end
        end
        if !stop
            best_cost += best_delta
            agent_before = list_of_agent[best_neighbor[2]]
            x[best_neighbor[1], best_neighbor[2]] = 1
            x[agent_before, best_neighbor[2]] = 0
            list_of_agent[best_neighbor[2]] = best_neighbor[1]
        end
        if stop
            neighborhood_2 = swap_agent(list_of_agent, x, r, b)
            # println(neighborhood_2)
            if size(neighborhood_2)[1] != 0
                for (task_1, task_2) in neighborhood_2
                    agent_1_before = list_of_agent[task_1]
                    agent_2_before = list_of_agent[task_2]
                    delta_cost = c[agent_1_before, task_2] + c[agent_2_before, task_1]  - (c[agent_1_before, task_1] + c[agent_2_before, task_2])
                    if delta_cost > best_delta
                        # println("new best")
                        best_delta = delta_cost
                        best_neighbor = (task_1, task_2)
                        stop = false
                    end
                end
            end
            if !stop
                best_cost += best_delta
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
            end
        end
    end
    final_cost = cost_sol(c, x)
    @assert final_cost == best_cost
    @assert best_cost >= initial_cost
    @assert verify_sol(x, r, b)
    
    # println("number of iterations: $it")
    # println("improvement: \n initial cost: $initial_cost \n final cost: $best_cost \n improvement: $(best_cost - initial_cost)")
    return x
end
