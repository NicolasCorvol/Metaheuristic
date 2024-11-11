using DelimitedFiles
global r, c, b, m, t, opt
function readfile(instance_fname, instance_id::Int, minimization=false)    # instance_id=le numero d'instance, de 0-nbInst-1
    all = readdlm(instance_fname)
    nbInst   = all[1,1]
    @assert(instance_id<nbInst)
    deb = 2                # instance 0 commence a ligne deb
    global m = all[2,1]
    global t = all[2,2]
    for i in 1:instance_id
        deb += 2m+2        # sauter instance i (2m+2 lignes)
        global m = all[deb,1]    
        global t = all[deb,2]    
    end
    global c = all[deb+1:deb+m,   1:t]
    if minimization
        c = c.* -1
    end
    global r = all[deb+m+1:deb+2m,1:t]
    global b = all[deb+2m+1,      1:m]
    return
end

    