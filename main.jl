include("readfile.jl")
include("heuristic.jl")
include("metaheuristics.jl")
include("get_opts_values.jl")
include("tabu_search.jl")

using Profile
using CSV
using DataFrames
using OrderedCollections
using Base.Threads



function main()
    println(Threads.nthreads())
    my_lock = ReentrantLock()
    opts = Dict{String,Int32}()
    all_opts = getOpts()
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
            best_cost = 0
            println(j)
            opt = all_opts["gap$(i)_$(j+1)"]
            # println("Instance $j")
            readfile("instances/gap$i.txt", j)
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
                    x, task_to_agent, best_cost = descente_VND(r, b, m, t, c, opt, x, task_to_agent)
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
                if best_cost_all_methods == opt
                    found_optimal[] = true
                    break
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
    df[:, "Best initial value"] = best_initial_cost
    df[:, "Best initial heuristic"] = best_initial_heuristic
    df[:, "Final values"] = sol_values
    df[:, "Elapsed time"] = times
    df[:, "Gap to opt"] = gaps
    df[:, "Best final heuristic"] = best_final_heuristic
    CSV.write("results/multi_start_VND_tabu.csv", df, delim=';')
end




main()

# Profile.clear()  # Clear any previous profiling data
# @profile main()

# # Print out profiling data
# Profile.print()