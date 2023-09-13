# function preparetable!(::PrepareTable, PTC::PrepareTableConfig)
# # Fallback
# end

"""
`preparetable!(PT::PrepareTable, PTC::ConfigPreprocess)`
generates `datetime` column by `PTC.timeargs`, `sort!` by `:datetime`, do `PTC.preprocessing` in `@chain` and check if the table is continuous in time.

!!! note
    This method will raise essential error, unless that `PTC::ConfigPreprocess` is the first `arg` in `args` of `PrepareTable(PT, args...)` as it should be.
    This is intended since `ConfigAccumulate` or `ConfigSeriesToSupervised` is designed to work on a well preprocessed data, and it may give incorrect results without error (e.g., time tag mismatch) if `preparetable!` with `ConfigPreprocess` is not conducted before.
"""
function preparetable!(PT::PrepareTable, PTC::ConfigPreprocess)
    _check(PT, PTC)

    transform!(PT.table, AsTable(PTC.timeargs) => ByRow(args -> DateTime(args...)) => :datetime)
    sort!(PT.table, :datetime)
    select!(PT.table, :datetime, PTC.timeargs, PTC.input_features, PTC.target_features)
    PT.status = Prepare((
        timeargs=PTC.timeargs,
        input_features=PTC.input_features,
        target_features=PTC.target_features
    )) # for later use
    PT.cache.prepare = PT.status
    # PT.table = @chain(PT.table, PTC.preprocessing...) # This will fail
    PT.table = simplepipeline(PT.table, PTC.preprocessing...)
    try
        Δt = PT.table.datetime |> diff |> unique |> only
    catch e
        @error "The loaded data is not continuous in time."
        throw(e)
    end
    push!(PT.configs, PTC)
    return PT
end

"""
`preparetable!(PT::PrepareTable, PTC::ConfigAccumulate)`
generates derived variables as new columns. See `ConfigAccumulate`.

"""
function preparetable!(PT::PrepareTable, PTC::ConfigAccumulate)
    _check(PT, PTC)

    sfx = accu_unit_suffix_function(PTC.unit)
    apd = Dict(sfx.(PTC.intervals) .=> PTC.intervals) # create a dictionary
    for var in PTC.variables.cols
        addcol_accumulation!(PT.table, [var], apd)
    end
    push!(PT.configs, PTC)
    return PT
end

"""
`accu_unit_suffix_function` returns a suffix function `sfx(i)` for generates the keys for `apd = Dict(sfx.(PTC.intervals) .=> PTC.intervals)` that is going to be fed into `addcol_accumulation!`, where `PTC::ConfigAccumulate`.

`accu_unit_suffix_function(PTCunit::AbstractString)` returns `i -> "\$i\$(PTCunit)"`.

This returned function is essential for generate readable tags appended as the new column names when using `PrepareTable`, `PrepareTableDefault`, or `preparetable!` with the configuration `ConfigAccumulate`.
"""
function accu_unit_suffix_function(PTCunit::AbstractString)
    return i -> "$i$(PTCunit)"
end

"""

If input is a function, it simply returns its argument:
`accu_unit_suffix_function(PTCunit::Function) = PTCunit`.

This is for the case for customized suffix-generating function.

See also `ConfigAccumulate`.
"""
accu_unit_suffix_function(PTCunit::Function) = PTCunit

"""
`preparetable!(PT::PrepareTable, PTC::ConfigSeriesToSupervised)` creates `SeriesToSupervised` as `PT.supervised_tables` for training and testing for supervised models.
"""
function preparetable!(PT::PrepareTable, PTC::ConfigSeriesToSupervised)
    _check(PT, PTC)

    df = PT.table
    fullX, y0, t0 = series2supervised(
        df[!, PT.status.args.input_features] => PTC.shift_x,
        df[!, PT.status.args.target_features] => PTC.shift_y,
        df[!, [:datetime]] => PTC.shift_y)

    # t0v = only(eachcol(t0))
    # x0v = eachindex(t0v) |> collect
    # TX = TimeAsX(x0v, t0v; check_approxid = true)
    PT.supervised_tables = SeriesToSupervised(fullX, y0, t0)

    push!(PT.configs, PTC)

    return PT
    # return fullX, y0, TX
end
