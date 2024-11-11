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


function main(instances_folder = "./gap_1_12", minimization=false)
    my_lock = ReentrantLock()
    opts = Dict{String,Int32}()
    min_factor = 2*(1 - minimization)-1
    max_run_time = 6*60
    if instances_folder == "./gap_1_12"
        all_opts = getOpts_max()
        number_of_instances_per_file = 5
    elseif instances_folder == "./gap_abcd"
        all_opts = getOpts_min()
        number_of_instances_per_file = 6
    else 
        number_of_instances_per_file = 1
        all_opts = nothing
    end
    instance_names = readdir(instances_folder)
    name_instances = []
    opt_instances = []
    best_initial_cost = []
    best_initial_heuristic = []
    sol_values = []
    times = []
    gaps = []
    best_final_heuristic = []
    for name in instance_names
        println("###############")
        println(name)
        for j in 1:number_of_instances_per_file
            println("Instance $j")
            readfile("$instances_folder/$name", j-1, minimization)
            bound = min_factor*upper_bound(c)
            if all_opts != nothing
                opt = all_opts["$(name)_$(j)"]
            else 
                opt = bound
            end
            append!(name_instances, ["$(name)_$(j)"])
            append!(opt_instances, [opt])
            start_time = time()
            
            # Multi_start 
            sorted_x, sorted_task_to_agent, sorted_heuristic_names, sorted_costs, sorted_emptiness = multi_start(r, c, b, m, t, 50, true)
            if length(sorted_x) == 0
                println("No feasible initial solutions")
                continue
            end
            println("$(name)_$(j) : opt $opt, borne $(bound) best_ini $(min_factor*sorted_costs[1])")
            append!(best_initial_cost, [sorted_costs[1]])
            append!(best_initial_heuristic, [sorted_heuristic_names[1]])

            found_optimal = Atomic{Bool}(false)
            best_cost_all_methods = sorted_costs[1]
            best_heuristic = sorted_heuristic_names[1]
            best_gap = round.(abs(opt - min_factor*best_cost_all_methods)/opt*100, digits=2)
            @threads for idx in 1:length(sorted_x)
                if found_optimal[]
                    break
                end
            # for idx in 1:length(sorted_x)
                # println("Thread $(threadid()) is processing solution index $idx")
                if (time() - start_time > max_run_time) || (min_factor*best_cost_all_methods == opt)
                    found_optimal[] = true
                    break
                end
                x = sorted_x[idx]
                task_to_agent = sorted_task_to_agent[idx]
                heuristic_ini = sorted_heuristic_names[idx]
                @assert verify_sol(x, r, b)
                x, task_to_agent, best_cost = variable_neighborhood_descent(r, b, m, t, c, opt, x, task_to_agent, 
                                                                            max_iteration = 1000, 
                                                                            max_elapsed_time = max_run_time - (time() - start_time), 
                                                                            minimization = minimization)
                if found_optimal[]
                    continue
                end
                for k in 1:30
                    tabu_len = rand(max(1, floor(Int, 0.2*m)):max(2, floor(Int, 0.5*m)))
                    x, task_to_agent, best_cost = random_descente_change_agent_or_swap(r, b, m, t, c, opt, x, task_to_agent, 
                                                                                        max_iteration = 1000, 
                                                                                        max_elapsed_time = max_run_time - (time() - start_time), 
                                                                                        minimization = minimization)
                    @assert verify_sol(x, r, b)
                    if (min_factor*best_cost == opt) || (time() - start_time >= max_run_time) || found_optimal[]
                        found_optimal[] = true
                        break
                    end
                    x, task_to_agent, best_cost = tabu_change_and_swap(r, b, m, t, c, tabu_len, opt, x, task_to_agent, 
                                                                        max_iteration=1000, 
                                                                        max_iteration_without_improvement=20, 
                                                                        max_elapsed_time=max_run_time-(time() - start_time), 
                                                                        minimization = minimization)
                    @assert verify_sol(x, r, b)
                    if (min_factor*best_cost == opt) || (time() - start_time >= max_run_time ) || found_optimal[]
                        found_optimal[] = true
                        break
                    end
                end
                @assert cost_sol(c, x) == best_cost
                @assert verify_sol(x, r, b)
                lock(my_lock) do
                    if best_cost > best_cost_all_methods
                        best_cost_all_methods = best_cost
                        best_heuristic = heuristic_ini
                        best_gap = round.(abs(opt - min_factor*best_cost_all_methods)/opt*100, digits=2)
                    end
                end
            end
            total_elapsed_time = time() - start_time
            println("Optimum=$opt / final value=$(min_factor*best_cost_all_methods) / gap=$(best_gap)")

            append!(sol_values, [best_cost_all_methods])
            append!(times, [total_elapsed_time])
            append!(gaps, [best_gap])
            append!(best_final_heuristic, [best_heuristic])
        end

    end
    df = DataFrame(Instances = name_instances,
                   Opts = opt_instances, 
                   Best_heuristic_value = best_initial_cost,
                   Best_heuristic = best_initial_heuristic,
                   Best_value_found = sol_values,
                   Gap_to_opt= gaps,
                   Elapsed_time = times,
                   Best_start_heuristic = best_final_heuristic)
    CSV.write("results/VND_tabu_gap_c_d_instances_min.csv", df, delim=';') 
end


main()

# Profile.clear()  # Clear any previous profiling data
# @profile main()

# # Print out profiling data
# Profile.print()