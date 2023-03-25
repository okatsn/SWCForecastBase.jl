function simplepipeline(arg1, fns::Function...)
    ∘(fns...)(arg1)
end
