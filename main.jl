include("readfile.jl")
include("heuristic.jl")
include("first_neighborhood.jl")
using Profile
using CSV
using DataFrames
using OrderedCollections

function main()
    df = CSV.read("Instance_perfs.csv", DataFrame)
    Heuristic_perf = Int[]
    Gaps = AbstractFloat[]
    for i in 1:12
        println(i)
        for j in 0:4
            # println("###############")
            # println("Instance $j")
            readfile("instances/gap$i.txt", "instances/opt.txt", i, j)
            x = descente(r, b, m, t, c)
            cost_final_sol = cost_sol(c, x)
            verif = verify_sol(x, r, b)
            # println("gap : $(opt - cost_final_sol)")
            if !verif
                print("Bad solution")
            else
                push!(Heuristic_perf, cost_final_sol)
                push!(Gaps, round.((opt-cost_final_sol)/opt*100, digits=2))
            end
        end
    end
    df[:, "VND_1_val"] = Heuristic_perf
    df[:, "VND_1_gap"] = Gaps

    CSV.write("Instance_perf_2.csv", df, delim=';')
end

main()

# Profile.clear()  # Clear any previous profiling data
# @profile main()

# # Print out profiling data
# Profile.print()