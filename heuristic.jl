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
    return x, task_to_agent, r_left
end


function grasp_with_local_search(r, c, b, m, t, max_iterations, alpha, opt)
    best_x = nothing
    best_task_to_agent = nothing
    best_cost = 0

    for iteration in 1:max_iterations
        x, task_to_agent, r_left = constructive_phase(r, c, b, m, t, alpha)
        
        if verify_sol(x, r, b)
            x, task_to_agent = local_search(x, task_to_agent, r_left, r, c, b, m, t)
            cost = cost_sol(c, x)
            if cost > best_cost
                best_cost = cost
                best_x = x
                best_task_to_agent = task_to_agent
            end
        end
        if best_cost == opt
            println("OPTIMAL")
            break
        end
    end
    return best_cost, best_x, best_task_to_agent
end




function local_search(x, task_to_agent, r_left, r, c, b, m, t)
    improved = true
    while improved
        improved = false
        for task in 1:t
            current_agent = task_to_agent[task]
            for agent in 1:m
                if agent != current_agent
                    current_cost = c[current_agent, task]
                    new_cost = c[agent, task]
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

function ressource_left(x, r, b)
    return sum(b[agent] - sum(x[agent, :] .* r[agent, :]) for agent in 1:size(x, 1))
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


# ----------------- MULTI START ---------------------------

function multi_start(r, c, b, m, t, max_sol_nb)
    diff_x =[]
    diff_task_to_agent = []
    diff_heuristic_names = []
    cost_sols = []
    emptiness = []
    # cost by ressource 
    x_0, task_to_agent_0 = greedy_cost_by_ressource_heuristic(r, c, b, m, t)
    if verify_sol(x_0, r, b)
        cost_0 = cost_sol(c, x_0)
        r_left_0 = ressource_left(x_0, r, b)
        append!(diff_heuristic_names, ["greedy_cost_by_ressource_heuristic"])
        append!(diff_x, [x_0])
        append!(diff_task_to_agent, [task_to_agent_0])
        append!(cost_sols, [cost_0])
        append!(emptiness, [r_left_0])
    end
    # min ressource
    for _ in 1:20
        x_1, task_to_agent_1 = greedy_random_min_ressource_heuristic(r, c, b, m, t)
        if !verify_sol(x_1, r, b) || task_to_agent_1 in diff_task_to_agent 
            continue
        end
        cost_1 = cost_sol(c, x_1)
        r_left_1 = ressource_left(x_1, r, b)
        append!(diff_heuristic_names, ["greedy_random_min_ressource_heuristic"])
        append!(diff_x, [x_1])
        append!(diff_task_to_agent, [task_to_agent_1])
        append!(cost_sols, [cost_1])
        append!(emptiness, [r_left_1])
    end
    # random c/r
    for _ in 1:20
        x_2, task_to_agent_2 = greedy_random_cost_effectiveness_heuristic(r, c, b, m, t)
        if !verify_sol(x_2, r, b) || task_to_agent_2 in diff_task_to_agent
            continue
        end
        cost_2 = cost_sol(c, x_2)
        r_left_2 = ressource_left(x_2, r, b)
        append!(diff_heuristic_names, ["greedy_random_cost_effectiveness_heuristic"])
        append!(diff_x, [x_2])
        append!(diff_task_to_agent, [task_to_agent_2])
        append!(cost_sols, [cost_2])
        append!(emptiness, [r_left_2])
    end
    # grasp
    for alpha in [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.7, 0.8, 0.9]
        for _ in 1:20
            x_3, task_to_agent_3 = grasp_constructive_phase(r, c, b, m, t, alpha)
            if !verify_sol(x_3, r, b) || task_to_agent_3 in diff_task_to_agent
                continue
            end
            cost_3 = cost_sol(c, x_3)
            r_left_3 = ressource_left(x_3, r, b)
            append!(diff_heuristic_names, ["grasp_constructive_phase_$alpha"])
            append!(diff_x, [x_3])
            append!(diff_task_to_agent, [task_to_agent_3])
            append!(cost_sols, [cost_3])
            append!(emptiness, [r_left_3])
        end
    end
    # full random
    for _ in 1:20
        x_4, task_to_agent_4 = greedy_random_heuristic(r, c, b, m, t)
        if !verify_sol(x_4, r, b) || task_to_agent_4 in diff_task_to_agent
            continue
        end
        cost_4 = cost_sol(c, x_4)
        r_left_4 = ressource_left(x_4, r, b)
        append!(diff_heuristic_names, ["greedy_random_heuristic"])
        append!(diff_x, [x_4])
        append!(diff_task_to_agent, [task_to_agent_4])
        append!(cost_sols, [cost_4])
        append!(emptiness, [r_left_4])
    end

    ## trier les solution par ... 
    ## première idée : cout croissant
    ## on pourrait utiliser de l'aide à la décision multi-critère 
    # scores = [cost_weight * cost_sols[i] + emptiness_weight * ressource_left[i] for i in 1:length(diff_x)]

    sorted_indices = sortperm(cost_sols, rev=true)
    max_nb_of_sols = min(max_sol_nb, length(diff_x))
    sorted_x = diff_x[sorted_indices][1:max_nb_of_sols]
    sorted_task_to_agent = diff_task_to_agent[sorted_indices][1:max_nb_of_sols]
    sorted_heuristic_names = diff_heuristic_names[sorted_indices][1:max_nb_of_sols]
    sorted_costs = cost_sols[sorted_indices][1:max_nb_of_sols]
    sorted_emptiness = emptiness[sorted_indices][1:max_nb_of_sols]
    return sorted_x, sorted_task_to_agent, sorted_heuristic_names, sorted_costs, sorted_emptiness
end