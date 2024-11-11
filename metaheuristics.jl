using Debugger


include("heuristic.jl")
include("change_one_agent.jl")
include("change_two_agents.jl")
include("swap_two_tasks.jl")
include("swap_three_tasks.jl")


# Descente à voisinage variable avec 3 structures de voisinages : 
# 1. Changement d'agent pour une tâche
# 2. Echange de deux tâches d'agents différents
# 3. Echange de trois tâches d'agents différents
function variable_neighborhood_descent(r, b, m, t, c, opt, x, task_to_agent;
                                        max_iteration = 1000, 
                                        max_elapsed_time = 600, 
                                        minimization=false)
    @assert verify_sol(x, r, b)
    start_time = time()
    initial_cost = cost_sol(c, x)
    best_cost = initial_cost
    stop = false
    it = 0
    elapsed_time = time() - start_time
    while !stop && it < max_iteration && elapsed_time < max_elapsed_time 
        it += 1
        stop = true
        stop, best_cost, x, task_to_agent = LS_change_one_agent(task_to_agent, x, r, b, m, c, best_cost, stop)
        if stop
            stop, best_cost, x, task_to_agent = LS_swap_tasks(task_to_agent, x, r, b, m, c, best_cost, stop)
        end
        if stop
            stop, best_cost, x, task_to_agent = LS_swap_three_tasks(task_to_agent, x, r, b, m, c, best_cost, stop)
        end
        @assert verify_sol(x, r, b)
        if (best_cost*(2*(1 - minimization) -1) == opt)
            stop = true
            println("OPTIMAL FOUND")
        end
        elapsed_time = time() - start_time
    end
    final_cost = cost_sol(c, x)
    @assert final_cost == best_cost
    @assert best_cost >= initial_cost
    @assert verify_sol(x, r, b)
    return x, task_to_agent, best_cost
end


function random_descente_change_agent_or_swap(r, b, m, t, c, opt, x, task_to_agent; 
                                            max_iteration = 1000, 
                                            max_elapsed_time = 600, 
                                            minimization=false)
    @assert verify_sol(x, r, b)
    start_time = time()
    initial_cost = cost_sol(c, x)
    best_cost = initial_cost
    stop = false
    it = 0  
    elapsed_time = time() - start_time
    while !stop && it < max_iteration && elapsed_time < max_elapsed_time
        it += 1
        stop = true
        if rand() < 0.5
            stop, best_cost, x, task_to_agent = LS_change_one_agent(task_to_agent, x, r, b, m, c, best_cost, stop)
        else
            stop, best_cost, x, task_to_agent = LS_swap_tasks(task_to_agent, x, r, b, m, c, best_cost, stop)
        end
        @assert verify_sol(x, r, b)
        if (best_cost*(2*(1 - minimization) -1) == opt)
            stop = true
            println("OPTIMAL FOUND")
        end
        elapsed_time = time() - start_time
    end
    final_cost = cost_sol(c, x)
    @assert final_cost == best_cost
    @assert best_cost >= initial_cost
    @assert verify_sol(x, r, b)
    return x, task_to_agent, best_cost
end



function descente_change_agent(r, b, m, t, c, opt, x, task_to_agent)
    @assert verify_sol(x, r, b)
    initial_cost = cost_sol(c, x)
    best_cost = initial_cost
    stop = false
    it = 0  
    while !stop && it < 1000
        it += 1
        stop = true
        stop, best_cost, x, task_to_agent = LS_change_one_agent(task_to_agent, x, r, b, m, c, best_cost, stop)
        @assert verify_sol(x, r, b)
        if best_cost == opt
            stop = true
            println("OPTIMAL FOUND")
        end
    end
    final_cost = cost_sol(c, x)
    @assert final_cost == best_cost
    @assert best_cost >= initial_cost
    @assert verify_sol(x, r, b)
    # println("number of iterations: $it")
    # println("improvement: \n final cost: $best_cost VS opt : $opt")
    return x
end

function recuit_simule(r, b, m, t, c, opt, x, task_to_agent, T)
    @assert verify_sol(x, r, b)
    # Initialisation
    initial_cost = cost_sol(c, x)
    println("Initial cost: $initial_cost")
    best_cost = initial_cost
    current_cost = initial_cost
    best_x = copy(x)
    it = 0 
    T = t*2
    mu = 0.9
    while it < 100*t
        if mod(it, 100) == 0
            T = mu*T
        end
        neighborhood = shuffle(swap_task(task_to_agent, x, r, b))
        if isempty(neighborhood)
            print("neighborhood empty")
        end
        if !isempty(neighborhood)
            for (task_1, task_2) in neighborhood
                delta_cost = delta_cost_swap_tasks(task_1, task_2, task_to_agent, c)                    
                if delta_cost > 0 || exp(delta_cost / T) > rand()
                    x, task_to_agent = update_sol_swap_tasks(x, task_to_agent, (task_1, task_2))
                    x, task_to_agent = variable_neighborhood_descent(r, b, m, t, c, opt, x, task_to_agent)
                    current_cost += delta_cost
                    @assert current_cost == cost_sol(c, x)
                    # Maj de la meilleure solution
                    if current_cost > best_cost
                        best_x = copy(x)
                        best_cost = current_cost
                        println("New best cost: $best_cost at iteration $it")
                    end
                    break
                end
            end
        end
        it += 1
        @assert verify_sol(x, r, b)
        
        if best_cost == opt
            println("Optimal solution found at iteration $it")
            break
        end
    end

    # Calcul final et validation
    final_cost = cost_sol(c, best_x)
    println("Final cost: $final_cost")
    println("Best cost: $best_cost")
    println("Current cost: $current_cost")
    
    @assert final_cost == best_cost
    @assert best_cost >= initial_cost
    @assert verify_sol(best_x, r, b)

    println("Number of iterations: $it")
    return best_x
end

