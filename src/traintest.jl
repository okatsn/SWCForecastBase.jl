function traintest!(PT::PrepareTable)

end

function train!(PT::PrepareTable; train_before = :auto, model = manytrees())
    if train_before == :auto
        train_before = now()
    end

    id0 = 1
    row, id1 = nearestrow(PT.supervised_tables.T, Cols(r"\Adatetime"), train_before)
    X = PT.supervised_tables.X[id0:id1]
    Y = PT.supervised_tables.Y[id0:id1]
    t = PT.supervised_tables.T[id0:id1] |> eachcol |> only
    machs = _create_machines(model, t, X, Y)
    fit!.(machs)
    PT.state = Train((machines = machs,))
    return PT
end

# TODO: future work: the learning network of 0.19.1:
# https://alan-turing-institute.github.io/MLJ.jl/stable/learning_networks/
function _create_machines(model, t, X, Y)
    machs = [machine(model, X, y) for y in eachcol(Y)]
end

function test!(PT::PrepareTable; test_after = :auto, test_numpoints = 240)
    if test_after == :auto
       test_after = now()
    end
    row, id0 = nearestrow(PT.supervised_tables.T, Cols(r"\Adatetime"), test_after)
    X = PT.supervised_tables.X[id0:(id0+test_numpoints)]
    Y = PT.supervised_tables.Y[id0:(id0+test_numpoints)]
    t = PT.supervised_tables.T[id0:(id0+test_numpoints)] |> eachcol |> only

    machs = _get_machines(PT.state)

    for (mach, y) in zip(machs, eachcol(Y))
        yhat = predict(mach, X, only(y))
    end
end

_get_machines(otherwise) = @error "It is not trained."
function _get_machines(Pt_state::Union{Train, Test})
    PT_state.machines
end
