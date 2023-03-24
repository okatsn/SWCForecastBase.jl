abstract type PrepareTableConfig end

struct ConfigSeriesToSupervised <: PrepareTableConfig
    shift_x::Vector{<:Int}
    shift_y::Vector{<:Int}
    function ConfigSeriesToSupervised(;
        shift_x         = [0, -6, -12, -24, -36, -48, -60, -72],
        shift_y         = [1],
        )
        new(shift_x, shift_y)
    end
end


struct ConfigPreprocess <: PrepareTableConfig
    timeargs::Cols
    input_features::Cols
    target_features::Cols
    preprocessing
    function ConfigPreprocess(;
        timeargs            = Cols(:year, :month, :day, :hour), # sort, group by, and combine according to the last
        input_features  = Cols(r"air_temp", r"humidity", r"pressure", r"windspeed", r"precipitation"), # FIXME: you need a precipmax! to ensure precipitation_max is generated
        target_features = Cols(r"soil_water_content"),
        preprocessing   = [take_hour_last, removeunresonables!, imputeinterp!],
        )
        new(
            timeargs,
            input_features,
            target_features,
            preprocessing,
        )
    end
end

struct ConfigAccumulate <: PrepareTableConfig
    variables::Cols
    intervals::Vector{<:Int}
    unit # unit of intervals as appended string of the new column, e.g., day.
    function ConfigAccumulate(; variables = Cols(:precipitation_max),
                                intervals = [1, 12, 24, 48, 36],
                                unit = ""
        )
        new(variables, intervals, unit)
    end
end

"""
# Constructor
`PrepareTable(table) = new(table, PrepareTableConfig[])`

# Field
```julia
table::DataFrame
configs::Vector{<:PrepareTableConfig}
```
"""
mutable struct PrepareTable
    table::DataFrame
    configs::Vector{<:PrepareTableConfig}
    state::Union{TrainTestState, Nothing}
    sts::Union{SeriesToSupervised, Nothing}
    function PrepareTable(table)
        new(table, PrepareTableConfig[], nothing, nothing)
    end
end

"""
Given a `table::DataFrame` and `PTCs::PrepareTableConfig...`, `PrepareTable` runs `preparetable!(_, PTC::PrepareTableConfig)` for `PTC` in `PTCs` in `@chain`.

# Example
```julia
    PrepareTable(df::DataFrame, ConfigPreprocess(), ConfigSeriesToSupervised())
```
"""
function PrepareTable(df::DataFrame, PTCs::PrepareTableConfig...)
    PT = PrepareTable(df)
    for PTC in PTCs
        preparetable!(PT, PTC)
    end
    return PT
end

"""
Default data processing:

`DefaultPrepareTable(df::DataFrame) = PrepareTable(df, ConfigPreprocess(), ConfigAccumulate(), ConfigSeriesToSupervised())`
"""
function DefaultPrepareTable(df::DataFrame)
    PrepareTable(df, ConfigPreprocess(), ConfigAccumulate(; unit="hr"), ConfigSeriesToSupervised())
end


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
    PT.state = Prepare((
        timeargs        = PTC.timeargs,
        input_features  = PTC.input_features,
        target_features = PTC.target_features
    )) # for later use
    PT.table = @chain(PT.table, PTC.preprocessing...)
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
        addcol_accumulation!(PT.table, var, apd)
    end
    push!(PT.configs, PTC)
    return PT
end


function preparetable!(PT::PrepareTable, PTC::ConfigSeriesToSupervised) # TODO: not finished
    df = PT.table
    fullX, y0, t0 = series2supervised(
        df[!, PT.state.input_features]  => PTC.shift_x,
        df[!, PT.state.target_features] => PTC.shift_y,
        df[!, [:datetime]]              => PTC.shift_y)

    # t0v = only(eachcol(t0))
    # x0v = eachindex(t0v) |> collect
    # TX = TimeAsX(x0v, t0v; check_approxid = true)
    PT.sts = SeriesToSupervised(fullX, y0, t0)

    push!(PT.configs, PTC)
    PT.state = Train()

    return PT
    # return fullX, y0, TX
end
