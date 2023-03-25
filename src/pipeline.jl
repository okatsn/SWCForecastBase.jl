function simplepipeline(arg1, fns::Function...)
    ∘(reverse(fns)...)(arg1)
end
