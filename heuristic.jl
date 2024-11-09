using Random

# ---------------- Tri des tâches ------------------------
# Tri des tâches par c/r décroissant 
function sort_tasks_by_decreasing_cost_on_ressource(r, c, m, t)
    cost_by_ressource = round.(c ./ r, digits=4)
    sorted_task = sort(
        [(task, maximum(cost_by_ressource[:, task])) for task in 1:t], 
        by = x -> x[2], 
        rev = true)
    return [task for (task, _) in sorted_task]
end


# ---------------- Tri des agents ------------------------
# Tri des agents par ressources croissantes
function sort_agent_by_increasing_ressource(r, m, t)
    sorted_agent = zeros(Int64, m, t)
    for task in 1:t
        agent_with_ressource = sort([(agent, r[agent,task]) for agent in 1:m], 
            by = x -> x[2])
        sorted_agent[:, task] = [agent for (agent, _) in agent_with_ressource]
    end
    return sorted_agent
end

# Tri des agents par coût décroissant
function sort_agent_by_decreasing_cost(c, m, t)
    sorted_agent = zeros(Int64,  m, t)
    for task in 1:t
        agent_with_ressource = sort([(agent, c[agent,task]) for agent in 1:m],
            by = x -> x[2],
            rev=true)
        sorted_agent[:, task] = [agent for (agent, _) in agent_with_ressource]
    end
    return sorted_agent
end

# Tri des agents par c/r décroissant 
function sort_agent_by_decreasing_cost_on_ressource(r, c, m, t)
    cost_by_ressource = round.(c ./ r, digits=4)
    agent_sorted_by_cost_and_ressources = zeros(Int64, m, t)
    for task in 1:t
        agent_sorted_for_task = sort([(agent, cost_by_ressource[agent, task]) for agent in 1:m],
            by = x -> x[2],
            rev=true) 
        agent_sorted_by_cost_and_ressources[:, task] = [agent for (agent, _) in agent_sorted_for_task]
    end
    return agent_sorted_by_cost_and_ressources
end


# ------------------------ Heuristiques ----------------------------

# Heuristique gloutonne qui parcourt les tâches puis les agents dans l'ordre donné
function greedy_heuristic(r, c, b, m, t, sorted_task, sorted_agent_by_task)
    task_to_agent = zeros(Int64, t)
    x = zeros(m, t)
    r_left = copy(b)
    for task in sorted_task
        for agent in sorted_agent_by_task[:, task]
            if r_left[agent] >= r[agent, task]
                r_left[agent] -= r[agent, task]
                task_to_agent[task]= agent
                x[agent, task] = 1
                break
            end
        end
    end
    return x, task_to_agent
end


# Heuristique aléatoire pour avoir plusieurs démarrage
function greedy_random_heuristic(r, c, b, m, t)
    random_tasks = shuffle(1:t)
    random_agent = zeros(Int64,  m, t)
    for task in 1:t
        random_agent[:, task] = shuffle(1:m)
    end
    return greedy_heuristic(r, c, b, m, t, random_tasks, random_agent)
end


# Heuristique qui affecte les tâches dans un ordre aléatoire à l'agent pour qui 
# cette tâche utilise le moins de ressource (permet ensuite d'avoir de l'espace 
# dans les agents pour utiliser le voisinage de changement d'agent)
function greedy_random_min_ressource_heuristic(r, c, b, m, t)
    random_tasks = shuffle(1:t)
    sorted_agents = sort_agent_by_increasing_ressource(r, m, t)
    return greedy_heuristic(r, c, b, m, t, random_tasks, sorted_agents)
end


# Heuristique qui trie les tâches dans l'ordre du maximum c/r décroissant
# et qui affecte ces tâches aux agents ayant le meilleur c/r disponible
function greedy_cost_by_ressource_heuristic(r, c, b, m, t)
    sorted_tasks = sort_tasks_by_decreasing_cost_on_ressource(r, c, m, t)
    sorted_agents = sort_agent_by_decreasing_cost_on_ressource(r, c, m, t)
    return greedy_heuristic(r, c, b, m, t, sorted_tasks, sorted_agents)
end   


# Heuristique qui affecte les tâches dans un ordre aléatoire à l'agent qui 
# maximise le c/r (attention : ne renvoie pas toujours de solution faisable)
function greedy_random_cost_effectiveness_heuristic(r, c, b, m, t)
    cost_by_ressource = round.(c ./ r, digits=4)
    task_to_agent = zeros(Int64, t)
    x = zeros(m, t)
    r_left = copy(b)
    tasks = shuffle(1:t)
    for task in tasks
        best_agent = nothing
        best_score = -Inf  
        for agent in 1:m
            if r_left[agent] >= r[agent, task]
                score = cost_by_ressource[agent, task]
                if score > best_score
                    best_score = score
                    best_agent = agent
                end
            end
        end
        if best_agent != nothing
            task_to_agent[task] = best_agent
            x[best_agent, task] = 1
            r_left[best_agent] -= r[best_agent, task]
        end
    end
    return x, task_to_agent
end

# Heuristique constructive qui trie les tâches par meilleur c/r avec
# agent encore disponible et qui crée une LRC composée des agents avec
# les meilleurs c/r pour cette tâche
function grasp_constructive_phase(r, c, b, m, t, alpha)
    cost_by_ressource = round.(c ./ r, digits=4)
    task_to_agent = zeros(Int64, t)
    x = zeros(m, t)
    r_left = copy(b)

    sorted_task = sort(
        [(task, maximum(cost_by_ressource[:, task])) for task in 1:t], 
        by = x -> x[2], 
        rev = true)

    not_affected__sorted_tasks = [task for (task, _) in sorted_task]
    while size(not_affected__sorted_tasks)[1] != 0
        best_cost_by_ressource = 0
        task = not_affected__sorted_tasks[1]
        admissible_agents = [agent for agent in 1:m if r_left[agent] >= r[agent, task]]
        sorted_agents = sort(
            [(agent, cost_by_ressource[agent, task]) for agent in admissible_agents],
            by = x -> x[2], rev=true)

        # S'il n'y a plus d'agent disponible, on arrête l'algorithme
        if isempty(admissible_agents)
            break
        end

        max_value = sorted_agents[1][2]
        min_value = sorted_agents[end][2]
        threshold = min_value + alpha * (max_value - min_value)
        LRC = [agent for (agent, _) in sorted_agents if cost_by_ressource[agent, task] >= threshold]
        chosen_agent = rand(LRC)
        r_left[chosen_agent] -= r[chosen_agent, task]
        task_to_agent[task] = chosen_agent
        x[chosen_agent, task] = 1

        popfirst!(not_affected__sorted_tasks)

        adjusted_cost_ressource_matrix = zeros(Float64, m, t)
        for task in not_affected__sorted_tasks
            for agent in 1:m
                if r_left[agent] >= r[agent, task]
                    adjusted_cost_ressource_matrix[agent, task] = cost_by_ressource[agent, task]
                end
            end
        end

        sorted_task = sort(
            [(task, maximum(adjusted_cost_ressource_matrix[:, task])) for task in not_affected__sorted_tasks], 
            by = x -> x[2], 
            rev = true)
        not_affected__sorted_tasks = [task for (task, _) in sorted_task]
    end
    return x, task_to_agent
end


# ----------------- Fonctions de coût et de vérification ---------------------------

# Coût de la solution
function cost_sol(c, x)
    cost = 0
    for task in 1:t
        for agent in 1:m
            cost += c[agent, task]*x[agent, task]
        end 
    end
    return cost
end


# Vérification de la validité d'une solution
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