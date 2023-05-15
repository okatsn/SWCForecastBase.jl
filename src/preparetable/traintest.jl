"""
Training with `PrepareTable`.

# Example

```julia
train!(PT::PrepareTable;
        train_before = :auto, # default
        model = manytrees(),    # default
        numpoints_train = 24*120 # default
    )
```

- `train_before`: The `DateTime` or `Date` before which the data is used for training; if `:auto`, `train_before = now()`.
- `model`: The model; it can be any `MLJ` model.
- `numpoints_train`: from `train_before` how many data points (number of rows) to be included for model training.
"""
function train!(PT::PrepareTable;
        train_before = :auto,
        model = manytrees(),
        numpoints_train = 24*120,
        dummykwargs...
    )
    # CHECKPOINT: SlidingTrainTestWindow04200910
    # - [ ] train!(PT, SlidingTrainTestWindow(); ...)
    # - [ ] test!(PT, SlidingTrainTestWindow(); ...)
    # - [ ] traintest!(PT, SlidingTrainTestWindow(); ...)

    _check(PT)
    if train_before == :auto
        train_before = now()
    end

    (id0, id1) = _train_id0id1(PT, train_before, numpoints_train)

    X = @view PT.supervised_tables.X[id0:id1, :]
    Y = @view PT.supervised_tables.Y[id0:id1, :]
    t = @view only(eachcol(PT.supervised_tables.T))[id0:id1]
    machs = _create_machines(model, X, Y)
    fit!.(machs)
    PT.status = Train((machines = machs, X = X, Y = Y, t = t))
    PT.cache.train = PT.status
    return PT
end

function _train_id0id1(PT, train_before, numpoints_train)
    _, id1s = sortbydist(PT.supervised_tables.T, Cols(r"\Adatetime"), [train_before]) # you can only have exactly one column started with "datetime"
    id1 = first(id1s)
    id0 = maximum([1, id1 - numpoints_train])
    return (id0, id1)
end
# CHECKPOINT: SlidingTrainTestWindow04200910: make _train_id0id1 and _test_id0id1 compatible with SlidingTrainTestWindow
# - ?Replace numpoints_train, numpoints_test by window_train, window_test
# - ?New method _train_id0id1(PT, STTW),
# - ?New method _test_id0id1(PT, STTW),
function _test_id0id1(PT, test_after, numpoints_test)
    _, id0s = sortbydist(PT.supervised_tables.T, Cols(r"\Adatetime"), [test_after])
    id0 = first(id0s)
    id1 = minimum([id0+numpoints_test, nrow(PT.supervised_tables.T)])
    return (id0, id1)
end

# TODO: future work: the learning network of 0.19.1:
# https://alan-turing-institute.github.io/MLJ.jl/stable/learning_networks/
function _create_machines(model, X, Y)
    machs = [machine(model, X, y) for y in eachcol(Y)]
end

"""
# Example

```julia
test!(PT::PrepareTable; test_after = :auto,  # default
    numpoints_test = 480)   # default
```

- `test_after`: the `DateTime` or `Date` after which model prediction (model testing stage) starts. If `:auto`, `test_after = now()`.
- `numpoints_test`: the number of data points in the "future" to be tested.

"""
function test!(PT::PrepareTable; test_after = :auto, numpoints_test = 480, dummykwargs...)
    _check(PT)
    if test_after == :auto
       test_after = now()
    end

    id0, id1 = _test_id0id1(PT, test_after, numpoints_test)

    Xt = @view PT.supervised_tables.X[id0:id1,:]
    Yt = @view PT.supervised_tables.Y[id0:id1,:]
    tt = @view only(eachcol(PT.supervised_tables.T))[id0:id1]

    machs = PT.status.args.machines # load trained machines

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
`traintest!(PT::PrepareTable; kwargs...)` do `train!` then `test!`, accepts all keyword arguments that `train!` or `test!` could have.
"""
function traintest!(PT::PrepareTable; kwargs...)
    train!(PT; kwargs...)
    test!(PT; kwargs...)
end
