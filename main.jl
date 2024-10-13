include("readfile.jl")
include("heuristic.jl")

function main()
    for i in 1:12
        for j in 1:4
        readfile("instances/gap$i.txt", j)
        x = first_heuristic(r, b, m, t)cd 
        # println(x)
        println(cost_sol(c, x))
        verif = verify_sol(x, r, b)
        if !verif
            print("instance gap$i number $j")
        end
        end
    end

end

main()
