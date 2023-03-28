"""
Training with `PrepareTable`.

# Example

```julia
train!(PT::PrepareTable;
        train_before = :auto,
        model = manytrees(),
        max_train_point = 24*120
    )
```
"""
function train!(PT::PrepareTable;
        train_before = :auto,
        model = manytrees(),
        max_train_point = 24*120,
        dummykwargs...
    )
    if train_before == :auto
        train_before = now()
    end

    _, id1s = sortbydist(PT.supervised_tables.T, Cols(r"\Adatetime"), [train_before]) # you can only have exactly one column started with "datetime"
    id1 = first(id1s)
    id0 = maximum([1, id1 - max_train_point])

    X = @view PT.supervised_tables.X[id0:id1, :]
    Y = @view PT.supervised_tables.Y[id0:id1, :]
    t = @view only(eachcol(PT.supervised_tables.T))[id0:id1]
    machs = _create_machines(model, X, Y)
    fit!.(machs)
    PT.status = Train((machines = machs, X = X, Y = Y, t = t))
    PT.cache.train = PT.status
    return PT
end

# TODO: future work: the learning network of 0.19.1:
# https://alan-turing-institute.github.io/MLJ.jl/stable/learning_networks/
function _create_machines(model, X, Y)
    machs = [machine(model, X, y) for y in eachcol(Y)]
end

"""
# Example

```julia
test!(PT::PrepareTable; test_after = :auto, test_numpoints = 480)
```
"""
function test!(PT::PrepareTable; test_after = :auto, test_numpoints = 480, dummykwargs...)
    if test_after == :auto
       test_after = now()
    end
    _, id0s = sortbydist(PT.supervised_tables.T, Cols(r"\Adatetime"), [test_after])
    id0 = first(id0s)
    id1 = minimum([id0+test_numpoints, nrow(PT.supervised_tables.T)])

    Xt = @view PT.supervised_tables.X[id0:id1,:]
    Yt = @view PT.supervised_tables.Y[id0:id1,:]
    tt = @view only(eachcol(PT.supervised_tables.T))[id0:id1]

    machs = PT.status.args.machines

    Yhat = DataFrame()
    for (mach, (coly, y)) in zip(machs, pairs(eachcol(Yt)))
        yhat = predict(mach, Xt)
        insertcols!(Yhat, coly => yhat)
    end
    PT.status = Test((machines = machs, X = Xt, Y = Yt, t = tt, Y_pred = Yhat))
    PT.cache.test = PT.status
    return PT
end

# _get_machines(otherwise) = @error "It is not trained."
# function _get_machines(Pt_state::Union{Train, Test})
#     PT_state.machines
# end

"""
`traintest!(PT::PrepareTable; kwargs...)` do `train!` then `test!`, taking exactly the same keyword arguments as `train!` or `test!`.
"""
function traintest!(PT::PrepareTable; kwargs...)
    train!(PT; kwargs...)
    test!(PT; kwargs...)
end
