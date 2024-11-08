using Random

# Heuristique du sac à dos ==> tâches triées par c/r décroissant 
# Agent pris dans un ordre à déterminer
function backpack_sorted(r, c, m, t, sorted_agents)
    cost_by_ressource = c ./ r
    cost_by_ressource = round.(cost_by_ressource, digits=4)
    sorted_task = sort(
        [(task, maximum(cost_by_ressource[:, task])) for task in 1:t], 
        by = x -> x[2], 
        rev = true
    )
    return [task for (task, _) in sorted_task], sorted_agents
end

## Pour le moment on n'utilise pas ces fonctions qui sont déjà 
## intégrées dans le backpack sorted => c'est le cost_by_ressource 
## qui trie les agents 

# Agents triés par ceux qui prennent le moins de ressources  
function agent_by_increasing_ressource(r, c, m, t)
    sorted_agent = zeros(Int64,  m, t)
    for task in 1:t
        agent_with_ressource = sort([(agent, r[agent,task]) for agent in 1:m], by = x -> x[2])
        sorted_agent[:, task] = [agent for (agent, _) in agent_with_ressource]
    end
    return sorted_agent
end


# Agents triées par ceux qui rapporte le plus 
function agent_by_decreasing_cost(r, c, m, t)
    sorted_agent = zeros(Int64,  m, t)
    for task in 1:t
        agent_with_ressource = sort([(agent, c[agent,task]) for agent in 1:m], rev=true, by = x -> x[2])
        sorted_agent[:, task] = [agent for (agent, _) in agent_with_ressource]
    end
    return sorted_agent
end

function agent_by_decreasing_cost_on_ressource(r, c, m, t)
    cost_by_ressource = c./r
    cost_by_ressource = round.(cost_by_ressource, digits=4)
    agent_sorted_by_cost_and_ressources = zeros(Int64, m, t)
    for task in 1:size(cost_by_ressource)[2]
        agent_sorted_for_task = sort([(agent, cost_by_ressource[agent, task]) for agent in 1:m], rev=true, by = x -> x[2]) 
        agent_sorted_by_cost_and_ressources[:, task] = [agent for (agent, _) in agent_sorted_for_task]
    end
    return agent_sorted_by_cost_and_ressources
end

# Parcours les taches et les agents dans l'ordre donné
# Insert les tâches dans le premier agents dispo trié 
function glouton_heuristic(r, b, m, t, sorted_task, sorted_agent_by_task)
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


# Heuristique GRASP basée sur l'heuristique du sac à dos => pas vraiement un grasp
function grasp_heuristic(r, b, m, t, sorted_task, sorted_agent_by_task, alpha)
    task_to_agent = zeros(Int64, t)
    x = zeros(m, t)
    r_left = copy(b)
    while size(sorted_task)[1] != 0
        LRC = sorted_task[1:1+Int(round.(alpha*(size(sorted_task)[1]-1)))]
        random_task_index = rand(1:size(LRC)[1])
        task = LRC[random_task_index]
        deleteat!(sorted_task, findall(x->x==task,sorted_task))
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


function real_grasp(r, c, b, m, t, max_iterations, alpha, opt)
    best_x = nothing
    best_task_to_agent = nothing
    best_cost = 0

    for iteration in 1:max_iterations
        x, task_to_agent, r_left = constructive_phase(r, c, b, m, t, alpha)
        x, task_to_agent = local_search(x, task_to_agent, r_left, r, c, b, m, t)

        # MAJ meilleure solution
        cost = cost_sol(c, x)
        if cost > best_cost
            # println("cost : ", cost)
            best_cost = cost
            best_x = x
            best_task_to_agent = task_to_agent
        end
        if best_cost == opt
            println("OPTIMAL")
            break
        end
    end
    return best_cost, best_x, best_task_to_agent
end


function constructive_phase(r, c, b, m, t, alpha)
    cost_by_ressource = round.(c ./ r, digits=4)
    task_to_agent = zeros(Int64, t)
    x = zeros(m, t)
    r_left = copy(b)
    sorted_task = sort(
        [(task, maximum(cost_by_ressource[:, task])) for task in 1:t], 
        by = x -> x[2], 
        rev = true
    )
    not_affected_task = [task for task in 1:t]
    while size(not_affected_task)[1] != 0
        best_cost_by_ressource = 0
        task_to_affect = nothing
        admissible_agents = nothing
        for task in not_affected_task
            tasks_admissible_agents = [agent for agent in 1:m if r_left[agent] >= r[agent, task]]
            admissible_cost_by_ressource = 
        task = sorted_task[1]
        sorted_agents = sort(
            [(agent, cost_by_ressource[agent, task]) for agent in admissible_agents],
            by = x -> x[2]
        )
        max_value = sorted_agents[1][2]
        min_value = sorted_agents[end][2]
        threshold = min_value + alpha * (max_value - min_value)
        # LRC = [agent for (agent, cost) in sorted_agents if ]
        # LRC = [agent for (agent,_) in sorted_agents[1:1+Int(round.(alpha*(size(sorted_agents)[1]-1)))]]
        LRC = [agent for (agent, _) in sorted_agents if cost_by_ressource[agent, task] >= threshold]
        chosen_agent = rand(LRC)
        r_left[chosen_agent] -= r[chosen_agent, task]
        task_to_agent[task] = chosen_agent
        x[chosen_agent, task] = 1

        popfirst!(sorted_task)
        sorted_task = sort(
            [(task, maximum(cost_by_ressource[:, task])) for task in sorted_task], 
            by = x -> x[2], 
            rev = true
        )

    end
    @assert verify_sol(x, r, b)
    return x, task_to_agent, r_left
end


function local_search(x, task_to_agent, r_left, r, c, b, m, t)
    improved = true
    while improved
        improved = false
        for task in 1:t
            current_agent = task_to_agent[task]
            for agent in 1:m
                if agent != current_agent
                    current_cost = c[current_agent, task] / r[current_agent, task]
                    new_cost = c[agent, task] / r[agent, task]
                    if new_cost > current_cost && r_left[agent] >= r[agent, task]
                        task_to_agent[task] = agent
                        x[agent, task] = 1
                        x[current_agent, task] = 0
                        r_left[agent] -= r[agent, task]
                        r_left[current_agent] += r[current_agent, task]
                        @assert verify_sol(x, r, b)
                        improved = true
                        break
                    end
                end
            end
        end
    end
    return x, task_to_agent
end


# Heuristique random pour avoir plusieurs démarrage
function random_heuristic(r, b, m, t)
    task_to_agent = zeros(Int64, t)
    x = zeros(m, t)
    r_left = copy(b)
    tasks = shuffle!(collect(1:size(r)[2]))
    for random_task in tasks
        random_agent = shuffle!(collect(1:size(r)[1])) 
        for agent in random_agent
            if r[agent, random_task] > r_left[agent]
                continue
            end
            r_left[agent] -= r[agent, random_task]
            task_to_agent[random_task]= agent
            x[agent, random_task] = 1
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
            # println("Task $task is affected to $(sum(x[:, task])) agents")
        sol_ok = false
        end
    end
    for agent in 1:size(x)[1]
            if sum(x[agent, :] .* r[agent, :]) > b[agent]
                # println("Agent $agent does not have enough ressources:  $(sum(x[agent, :] .* r[agent, :])) consumed > $(b[agent]) available.")
                sol_ok = false
        end
    end
    # if sol_ok
    #     println("Solution feasible")
    # end
    # if !sol_ok
    #     println("Solution infeasible")
    # end
    return sol_ok
end