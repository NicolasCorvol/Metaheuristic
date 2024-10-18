include("readfile.jl")
include("heuristic.jl")
include("first_neighborhood.jl")


function main()
    for i in 1:12
        for j in 0:4
            println("###############")
            # println("Instance $j")
            readfile("instances/gap$i.txt", "instances/opt.txt", i, j)
            x = descente(r, b, m, t, c)
            cost_final_sol = cost_sol(c, x)
            println(cost_final_sol)
            verif = verify_sol(x, r, b)
            println("gap : $(opt - cost_final_sol)")
            if !verif
                print("Bad solution")
            end
        end
    end
end

main()
