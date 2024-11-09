function getOpts_max()::Dict{String,Int32}
    opts = Dict{String,Int32}()
    all_opt = readdlm("instances/opt.txt")
    for i in 1:12
        for j in 1:5
            opts["gap$(i)_$(j)"] = all_opt[i, j]
        end
    end
    return opts
end

function getOpts_min()::Dict{String,Int32}
    opts = Dict{String,Int32}()
    names = ["a", "b", "c", "d"]
    all_opt = readdlm("instances/opt_min.txt")
    for i in 1:5
        name = names[i]
        for j in 1:6
            opts["gap$(name)_$(j)"] = all_opt[i, j]
        end
    end
    return opts
end
