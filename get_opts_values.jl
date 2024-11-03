function getOpts()::Dict{String,Int32}
    opts = Dict{String,Int32}()
    all_opt = readdlm("instances/opt.txt")
    for i in 1:12
        for j in 1:5
            opts["gap$(i)_$(j)"] = all_opt[i, j]
        end
    end
    return opts
end
