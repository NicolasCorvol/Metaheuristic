function getOpts_max()::Dict{String,Int32}
    opts = Dict{String,Int32}()
    names = readdir("./gap_1_12")
    all_opt = readdlm("opt_values/opt_gap_1_12.txt")
    for (i, name) in enumerate(names)
        for j in 1:5
            opts["$(name)_$(j)"] = all_opt[i, j]
        end
    end
    return opts
end

function getOpts_min()::Dict{String,Int32}
    opts = Dict{String,Int32}()
    names = readdir("./gap_abcd")
    all_opt = readdlm("opt_values/opt_gap_abcd.txt")
    for (i, name) in enumerate(names)
        for j in 1:6
            opts["$(name)_$(j)"] = all_opt[i, j]
        end
    end
    return opts
end
