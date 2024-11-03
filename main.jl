include("readfile.jl")
include("heuristic.jl")
include("metaheuristics.jl")
include("get_opts_values.jl")

using Profile
using CSV
using DataFrames
using OrderedCollections

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
#                 # x = VND_random_swap_then_RL_change_agent(r, b, m, t, c, opt)
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



function main()
    opts = Dict{String,Int32}()
    all_opts = getOpts()
    df = DataFrame(Instance = ["gap$(i)_$(j+1)" for i in 1:12 for j in 0:4],
                   Opts = [all_opts["gap$(i)_$(j+1)"] for i in 1:12 for j in 0:4])
    best_costs = []
    best_gaps = []
    best_methods = []
    for i in 1:12
        println("###############")
        println(i)
        for j in 0:4
            println("Instance $j")
            readfile("instances/gap$i.txt", j)
            diff_x = []
            diff_agent_to_task = []
            best_cost = 0
            best_method = ""
            opt = all_opts["gap$(i)_$(j+1)"]
            for alpha in [0, 0.2, 0.4, 0.6, 0.8, 1]
                for k in 1:10000
                    sorted_task, sorted_agent_by_task = backpack_sorted(r, b, m, t)
                    x, task_to_agent = grasp_heuristic(r, b, m, t, sorted_task, sorted_agent_by_task, alpha)
                    verif = verify_sol(x, r, b)
                    if !verif
                        continue
                    end
                    if !(task_to_agent in diff_agent_to_task)
                        append!(diff_agent_to_task, [task_to_agent])
                        append!(diff_x, [x])
                        cost_final_sol = cost_sol(c, x)
                        gap = round.((opt-cost_final_sol)/opt*100, digits=2)
                    end
                end
            end
            for k in 1:10000
                x, task_to_agent = random_heuristic(r, b, m, t)
                verif = verify_sol(x, r, b)
                if !verif
                    continue
                end
                if !(task_to_agent in diff_agent_to_task)
                    append!(diff_agent_to_task, [task_to_agent])
                    append!(diff_x, [x])
                    cost_final_sol = cost_sol(c, x)
                    gap = round.((opt-cost_final_sol)/opt*100, digits=2)
                end
            end
            println("different solutions : ", size(diff_x)[1])
            for i in 1:size(diff_x)[1]
                x = diff_x[i] 
                task_to_agent = diff_agent_to_task[i]
                x = descente_change_agent(r, b, m, t, c, opt, x, task_to_agent)
                verif = verify_sol(x, r, b)
                if !verif
                    continue
                end
                cost_final_sol = cost_sol(c, x)
                if cost_final_sol > best_cost
                    best_method = "change_agent"
                    best_cost = cost_final_sol
                end 
                if cost_final_sol == opt
                    break
                end
                if best_cost < opt
                    x = diff_x[i] 
                    task_to_agent = diff_agent_to_task[i]
                    x = descente_v_2(r, b, m, t, c, opt, x, task_to_agent)
                    verif = verify_sol(x, r, b)
                    if !verif
                        continue
                    end
                    cost_final_sol = cost_sol(c, x)
                    if cost_final_sol > best_cost
                        best_method = "VND"
                        best_cost = cost_final_sol
                    end 
                    if cost_final_sol == opt
                        break
                    end
                end
                if best_cost < opt
                    for taboulen in 1:15
                        x = diff_x[i] 
                        task_to_agent = diff_agent_to_task[i]
                        x = descente_tabou_V2(r, b, m, t, c, opt, taboulen, x, task_to_agent)
                        verif = verify_sol(x, r, b)
                        if !verif
                            continue
                        end
                        cost_final_sol = cost_sol(c, x)
                        if cost_final_sol > best_cost
                            best_method = "TABOU"
                            best_cost = cost_final_sol
                        end 
                        if cost_final_sol == opt
                            break
                        end
                    end
                    if best_cost == opt
                        break
                    end
                end
            end
            append!(best_costs, [best_cost])
            best_gap = round.((opt-best_cost)/opt*100, digits=2)
            append!(best_gaps, [best_gap])
            append!(best_methods, [best_method])
        end
    end
    df[:, "best value"] = best_costs
    df[:, "Best gap"] = best_gaps
    df[:, "Best method"] = best_methods
    CSV.write("results/desente_graps_random_agent_vnd_tabou.csv", df, delim=';') 
end


main()

# Profile.clear()  # Clear any previous profiling data
# @profile main()

# # Print out profiling data
# Profile.print()