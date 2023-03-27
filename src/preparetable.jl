function preparetable!(::PrepareTable, PTC::PrepareTableConfig)
    @error "There is no corresponding method for $(typeof(PTC)) yet. Please create one."
    # return nothing # do nothing if the corresponding methods not created
end

"""
`preparetable!(PT::PrepareTable, PTC::ConfigPreprocess)`
generates `datetime` column by `PTC.timeargs`, `sort!` by `:datetime`, do `PTC.preprocessing` in `@chain` and check if the table is continuous in time.

!!! note
    This method will raise essential error, that `PTC::ConfigPreprocess` should be the first `arg` in `args` of `PrepareTable(PT, args...)`.
    Otherwise, the succeeding processing such as `ConfigAccumulate` or `ConfigSeriesToSupervised` may give incorrect results without error.
"""
function preparetable!(PT::PrepareTable, PTC::ConfigPreprocess)
    transform!(PT.table, AsTable(PTC.timeargs) => ByRow(args -> DateTime(args...)) => :datetime)
    sort!(PT.table, :datetime)
    select!(PT.table, :datetime, PTC.timeargs, PTC.input_features, PTC.target_features)
    PT.status = Prepare((
        timeargs        = PTC.timeargs,
        input_features  = PTC.input_features,
        target_features = PTC.target_features
    )) # for later use
    # PT.table = @chain(PT.table, PTC.preprocessing...) # This will fail
    PT.table = simplepipeline(PT.table, PTC.preprocessing...)
    try
        Δt = PT.table.datetime |> diff |> unique |> only
    catch
        @error "The loaded data is not continuous in time."
    end
    push!(PT.configs, PTC)
    return PT
end

"""
"""
function preparetable!(PT::PrepareTable, PTC::ConfigAccumulate)
    sfx(i) = "$i$(PTC.unit)"
    apd = Dict(sfx.(PTC.intervals) .=> PTC.intervals) # create a dictionary
    for var in PTC.variables.cols
        addcol_accumulation!(PT.table, [var], apd)
    end
    push!(PT.configs, PTC)
    return PT
end


function preparetable!(PT::PrepareTable, PTC::ConfigSeriesToSupervised)
    df = PT.table
    fullX, y0, t0 = series2supervised(
        df[!, PT.status.args.input_features]  => PTC.shift_x,
        df[!, PT.status.args.target_features] => PTC.shift_y,
        df[!, [:datetime]]              => PTC.shift_y)

    # t0v = only(eachcol(t0))
    # x0v = eachindex(t0v) |> collect
    # TX = TimeAsX(x0v, t0v; check_approxid = true)
    PT.supervised_tables = SeriesToSupervised(fullX, y0, t0)

    push!(PT.configs, PTC)

    return PT
    # return fullX, y0, TX
end
