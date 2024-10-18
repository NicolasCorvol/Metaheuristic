include("heuristic.jl")

function change_agent(x)
    neighborhood = [(agent, task) for task in 1:size(x)[2] for agent in 1:size(x)[1] if agent != findfirst(a -> a == 1, x[:, task])]
    return neighborhood
end


function descente(r, b, m, t, c)
    sorted_task, sorted_agent = backpack_sorted(r, b, m, t)
    x, _ = first_heuristic(r, b, m, t, sorted_task, sorted_agent)
    @assert verify_sol(x, r, b)
    initial_cost = cost_sol(c, x)
    best_cost = initial_cost
    stop = false
    it = 0  
    while !stop && it < 1000
        it += 1
        if it%25 == 0
            println(it)
        end
        stop = true
        neighborhood = change_agent(x)
        best_delta = 0
        best_neighbor = nothing 
        for (agent, task) in neighborhood
            agent_before = findfirst(a -> a == 1, x[:, task])
            # Check if the new solution is realizable
            # println(sum(x[agent, :] .* r[agent, :]), " ", r[agent, task], " ", b[agent])
            if sum(x[agent, :] .* r[agent, :]) + r[agent, task] <= b[agent]
                delta_cost = c[agent, task] - c[agent_before, task]
                # println("delta_cost ", delta_cost)
                if delta_cost > best_delta
                    best_delta = delta_cost
                    best_neighbor = (agent, task)
                    stop = false
                end
            end
        end
        if !stop
            best_cost += best_delta
            agent_before = findfirst(a -> a == 1, x[:, best_neighbor[2]])
            x[best_neighbor[1], best_neighbor[2]] = 1
            x[agent_before, best_neighbor[2]] = 0
            # println("new best solution found")
        end
    end
    
    final_cost = cost_sol(c, x)
    @assert final_cost == best_cost
    @assert best_cost >= initial_cost
    @assert verify_sol(x, r, b)
    
    println("number of iterations: $it")
    println("improvement: \n initial cost: $initial_cost \n final cost: $best_cost \n improvement: $(best_cost - initial_cost)")
    return x
end
