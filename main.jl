include("readfile.jl")
include("heuristic.jl")
include("metaheuristics.jl")
include("get_opts_values.jl")
include("tabu_search.jl")

using Profile
using CSV
using DataFrames
using OrderedCollections
using ProgressMeter
using Base.Threads

# function main()
#     opts = Dict{String,Int32}()
#     all_opts = getOpts()
#     df = DataFrame(Instance = ["gap$(i)_$(j+1)" for i in 1:12 for j in 0:4],
#                    Opts = [opt for opt in all_opts])
#     for taboulen in 1:12
#         println(taboulen)                   
#         sol_values = []
#         times = []
#         gaps = []
#         for i in 1:12
#             println("###############")
#             println(i)
#             if i%6==0
#                 println(i)
#             end
#             for j in 0:4
#                 opt = all_opts["gap$(i)_$(j+1)"]
#                 # println("Instance $j")
#                 readfile("instances/gap$i.txt", j)
#                 start_time = Base.time_ns()
#                 # x = descente(r, b, m, t, c, opt)
#                 # x = VND_random_swap_then_LS_change_agent(r, b, m, t, c, opt)
#                 # x = descente_tabou_after_descente_swap(r, b, m, t, c, opt, 4)
#                 x = descente_tabou(r, b, m, t, c, taboulen, opt)
#                 elapsed_time = (Base.time_ns()-start_time) / (1e9)
#                 verif = verify_sol(x, r, b)
#                 if !verif
#                     println("Bad solution")
#                     continue
#                 end
#                 cost_final_sol = cost_sol(c, x)
#                 gap = round.((opt-cost_final_sol)/opt*100, digits=2)
#                 append!(sol_values, [cost_final_sol])
#                 # append!(times, [elapsed_time])
#                 append!(gaps, [gap])
#             end
#         end 
#         df[:, "Values_taloulen_$taboulen"] = sol_values
#         # df[:, "Times_taloulen_$taboulen"] = times
#         df[:, "Gaps_taloulen_$taboulen"] = gaps

#         end
#     CSV.write("results/descente_and_tabou_1_12.csv", df, delim=';')
# end

            # readfile("instances/gap$i.txt", j)
            # max_iterations = 100
            # best_cost = 0
            # println(j)
            # opt = all_opts["gap$(i)_$(j+1)"]
            # # cost, x, task_to_agent = real_grasp(r, c, b, m, t, max_iterations, alpha, opt)
            # # println("cost : ", cost, " GAP ", opt - cost)
            # best_cost = 0 
            # best_gap = opt
            # best_method = "No solution found"

            # for i in 1:1
                # sorted_task, sorted_agent_by_task = sorted_tasks[i], sorted_agents[i]
                # x, task_to_agent = glouton_heuristic(r, b, m, t, sorted_task, sorted_agent_by_task)
                # x, task_to_agent = greedy_random_cost_effectiveness_heuristic(r, c, b, m, t)
                # x, task_to_agent = greedy_random_min_ressource_heuristic(r, c, b, m, t)
                # x, task_to_agent = grasp_constructive_phase(r, c, b, m, t, alpha)
                # cost, x, task_to_agent = grasp_with_local_search(r, c, b, m, t, max_iterations, alpha, opt)
                # verif = verify_sol(x, r, b)
                # if !verif
                #     continue
                # end
                # # append!(diff_x, [x])
                # x, task_to_agent = variable_neighborhood_descent(r, b, m, t, c, opt, x, task_to_agent)
                # x = recuit_simule(r, b, m, t, c, opt, x, task_to_agent)
                # cost_final_sol = cost_sol(c, x)
                # gap = round.((opt-cost_final_sol)/opt*100, digits=2)
                # if cost_final_sol > best_cost
                #     best_method = ""
                #     best_cost = cost_final_sol
            # println("Instance $j")


function main()
    println(Threads.nthreads())
    my_lock = ReentrantLock()
    opts = Dict{String,Int32}()
    all_opts = getOpts_max()
    # all_opts = getOpts_min()
    df = DataFrame(Instance = ["gap$(i)_$(j+1)" for i in 1:12 for j in 0:4],
                   Opts = [all_opts["gap$(i)_$(j+1)"] for i in 1:12 for j in 0:4])
    best_initial_cost = []
    best_initial_heuristic = []
    sol_values = []
    times = []
    gaps = []
    best_final_heuristic = []
    for i in 1:12
        println("###############")
        println(i)
        for j in 0:4
            println("Instance $j")
            readfile("instances/gap$i.txt", j)
            opt = all_opts["gap$(i)_$(j+1)"]
            start_time = time()
            ## MULTI START
            sorted_x, sorted_task_to_agent, sorted_heuristic_names, sorted_costs, sorted_emptiness = multi_start(r, c, b, m, t, 50)
            println("opt $opt, best_ini $(sorted_costs[1])")
            append!(best_initial_cost, [sorted_costs[1]])
            append!(best_initial_heuristic, [sorted_heuristic_names[1]])
            
            if length(sorted_x) == 0
                println("No feasible initial solutions")
                continue
            end
            found_optimal = Atomic{Bool}(false)
            best_cost_all_methods = 0
            best_heuristic = nothing
            best_gap = nothing
            @threads for idx in 1:length(sorted_x)
                # println("Thread $(threadid()) is processing solution index $idx")
                if found_optimal[]
                    continue
                end 
                x = sorted_x[idx]
                task_to_agent = sorted_task_to_agent[idx] 
                heuristic_ini = sorted_heuristic_names[idx]
                @assert verify_sol(x, r, b)
                best_cost = 0
                for k in 1:30
                    tabu_len = rand(1:floor(Int, sqrt(m)))
                    x, task_to_agent, best_cost = variable_neighborhood_descent(r, b, m, t, c, opt, x, task_to_agent)
                    @assert verify_sol(x, r, b)
                    if best_cost == opt
                        found_optimal[] = true
                        break
                    end
                    x, task_to_agent, best_cost = tabu_change_and_swap(r, b, m, t, c, tabu_len, opt, x, task_to_agent, 1000, 20)
                    @assert verify_sol(x, r, b)
                    elapsed_time = time() - start_time
                    if best_cost == opt || elapsed_time >= 60*2
                        found_optimal[] = true
                        break
                    end
                    if time() - start_time >= 120
                        found_optimal[] = true
                        break
                    end

                end
                # @assert cost_sol(c, x) == best_cost
                lock(my_lock) do
                    if best_cost > best_cost_all_methods
                        best_cost_all_methods = best_cost
                        best_heuristic = heuristic_ini
                        best_gap = round.((opt-best_cost)/opt*100, digits=2)
                    end
                end
            end
            total_elapsed_time = time() - start_time
            println("Optimum=$opt / final value=$(best_cost_all_methods) / gap=$(opt-best_cost_all_methods)")
            append!(sol_values, [best_cost_all_methods])
            append!(times, [total_elapsed_time])
            append!(gaps, [best_gap])
            append!(best_final_heuristic, [best_heuristic])
        end
        
    end
    df[:, "best value"] = sol_values
    df[:, "Best gap"] = gaps
    df[:, "Best method"] = best_final_heuristic
    df[:, "Time"] = times
    CSV.write("results/grasp_VND_rs4.csv", df, delim=';') 
end


# function main()
#     opts = Dict{String,Int32}()
#     all_opts = getOpts()
#     df = DataFrame(Instance = ["gap$(i)_$(j+1)" for i in 1:12 for j in 0:4],
#                    Opts = [all_opts["gap$(i)_$(j+1)"] for i in 1:12 for j in 0:4])
#     best_costs = []
#     best_gaps = []
#     best_methods = []
#     for i in 1:12
#         println("###############")
#         println(i)
#         for j in 0:4
#             println("Instance $j")
#             readfile("instances/gap$i.txt", j)
#             diff_x = []
#             diff_agent_to_task = []
#             best_cost = 0
#             best_method = ""
#             opt = all_opts["gap$(i)_$(j+1)"]
#             for alpha in [0, 0.2, 0.4, 0.6, 0.8, 1]
#                 for k in 1:10000
#                     sorted_task, sorted_agent_by_task = backpack_sorted_bis(r, c, m, t, agent_by_decreasing_cost_on_ressource(r, c, m, t))
#                     x, task_to_agent = grasp_heuristic(r, b, m, t, sorted_task, sorted_agent_by_task, alpha)
#                     verif = verify_sol(x, r, b)
#                     if !verif
#                         continue
#                     end
#                     if !(task_to_agent in diff_agent_to_task)
#                         append!(diff_agent_to_task, [task_to_agent])
#                         append!(diff_x, [x])
#                         cost_final_sol = cost_sol(c, x)
#                         gap = round.((opt-cost_final_sol)/opt*100, digits=2)
#                     end
#                 end
#             end
#             for k in 1:10000
#                 x, task_to_agent = random_heuristic(r, b, m, t)
#                 verif = verify_sol(x, r, b)
#                 if !verif
#                     continue
#                 end
#                 if !(task_to_agent in diff_agent_to_task)
#                     append!(diff_agent_to_task, [task_to_agent])
#                     append!(diff_x, [x])
#                     cost_final_sol = cost_sol(c, x)
#                     gap = round.((opt-cost_final_sol)/opt*100, digits=2)
#                 end
#             end
#             println("different solutions : ", size(diff_x)[1])
#             for i in 1:size(diff_x)[1]
#                 x = diff_x[i] 
#                 task_to_agent = diff_agent_to_task[i]
#                 x = descente_change_agent(r, b, m, t, c, opt, x, task_to_agent)
#                 verif = verify_sol(x, r, b)
#                 if !verif
#                     continue
#                 end
#                 cost_final_sol = cost_sol(c, x)
#                 if cost_final_sol > best_cost
#                     best_method = "change_agent"
#                     best_cost = cost_final_sol
#                 end 
#                 if cost_final_sol == opt
#                     break
#                 end
#                 if best_cost < opt
#                     x = diff_x[i] 
#                     task_to_agent = diff_agent_to_task[i]
#                     x = variable_neighborhood_descent(r, b, m, t, c, opt, x, task_to_agent)
#                     verif = verify_sol(x, r, b)
#                     if !verif
#                         continue
#                     end
#                     cost_final_sol = cost_sol(c, x)
#                     if cost_final_sol > best_cost
#                         best_method = "VND"
#                         best_cost = cost_final_sol
#                     end 
#                     if cost_final_sol == opt
#                         break
#                     end
#                 end
#                 if best_cost < opt
#                     for taboulen in 1:15
#                         x = diff_x[i] 
#                         task_to_agent = diff_agent_to_task[i]
#                         x = descente_tabou_change_agent(r, b, m, t, c, opt, taboulen, x, task_to_agent)
#                         verif = verify_sol(x, r, b)
#                         if !verif
#                             continue
#                         end
#                         cost_final_sol = cost_sol(c, x)
#                         if cost_final_sol > best_cost
#                             best_method = "TABOU"
#                             best_cost = cost_final_sol
#                         end 
#                         if cost_final_sol == opt
#                             break
#                         end
#                     end
#                     if best_cost == opt
#                         break
#                     end
#                 end
#             end
#             append!(best_costs, [best_cost])
#             best_gap = round.((opt-best_cost)/opt*100, digits=2)
#             append!(best_gaps, [best_gap])
#             append!(best_methods, [best_method])
#         end
#     end
#     df[:, "best value"] = best_costs
#     df[:, "Best gap"] = best_gaps
#     df[:, "Best method"] = best_methods
#     CSV.write("results/desente_graps_random_agent_vnd_tabou.csv", df, delim=';') 
# end
#     df[:, "Best initial value"] = best_initial_cost
#     df[:, "Best initial heuristic"] = best_initial_heuristic
#     df[:, "Final values"] = sol_values
#     df[:, "Elapsed time"] = times
#     df[:, "Gap to opt"] = gaps
#     df[:, "Best final heuristic"] = best_final_heuristic
#     CSV.write("results/multi_start_VND_tabu.csv", df, delim=';')
# end




main()

# Profile.clear()  # Clear any previous profiling data
# @profile main()

# # Print out profiling data
# Profile.print()