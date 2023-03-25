function simplepipeline(arg1, fns::Function...)
    for f in fns
        arg1 = f(arg1)
    end
    return arg1
end
