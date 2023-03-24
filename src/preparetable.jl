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
        input_features  = Cols(r"air_temp", r"humidity", r"pressure", r"windspeed"),
        target_features = Cols(r"soil_water_content"),
        preprocessing   = [removeunresonables!, imputeinterp!],
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

struct PrepareTable
    table::DataFrame
    config::Vector{<:PrepareTableConfig}
    function PrepareTable(df::DataFrame, PTCs::PrepareTableConfig...)
        df = deepcopy(df)
        for PTC in PTCs
            preparetable!(df, PTC)
        end
        new(df, PTCs)
    end
end

"""
Default data processing:

`PrepareTable(df::DataFrame) = PrepareTable(df, ConfigPreprocess(), ConfigAccumulate(), ConfigSeriesToSupervised())`
"""
function PrepareTable(df::DataFrame)
    PrepareTable(df, ConfigPreprocess(), ConfigAccumulate(; unit="hr"), ConfigSeriesToSupervised())
end


function preparetable!(df, PTC::PrepareTableConfig)
    @error "There is no corresponding method for $(typeof(PTC)) yet. Please create one."
    # return nothing # do nothing if the corresponding methods not created
end

"""
`preparetable!(df, PTC::ConfigPreprocess)`
generates `datetime` column by `PTC.timeargs`, `sort!` by `:datetime`, do `PTC.preprocessing` in `@chain` and check if the table is continuous in time.

This method will raise essential error, that `PTC::ConfigPreprocess` should be the first `arg` in `args` of `PrepareTable(df, args...)`.
Otherwise, the succeeding processing such as `ConfigAccumulate` or `ConfigSeriesToSupervised` may give incorrect results without error.
"""
function preparetable!(df, PTC::ConfigPreprocess)
    transform!(df, AsTable(PTC.timeargs) => ByRow(args -> DateTime(args...)) => :datetime)
    sort!(df, :datetime)
    df = @chain(df, PTC.preprocessing...)
    # TODO: you didn't combine to lowest timeargs yet.
    try
        Δt = df.datetime |> diff |> unique |> get1var
    catch
        @error "The loaded data is not continuous in time."
    end
    return df
end

"""
"""
function preparetable!(df, PTC::ConfigAccumulate)
    sfx(i) = "$i$(PTC.unit)"
    apd = sfx.(PTC.intervals) .=> PTC.intervals # create a dictionary
    for var in PTC.variables.cols
        addcol_accumulation!(df, var, apd)
    end
    return df
end


function preparetable!(df, PTC::ConfigSeriesToSupervised) # TODO: not finished
    fullX, y0, t0 = series2supervised(
        df[!, Cols(featureselector)]    => tpast,
        df[!, Cols(targetselector)]     => tfuture,
        df[!, [:datetime]]              => tfuture)

    t0v = only(eachcol(t0))
    x0v = eachindex(t0v) |> collect
    TX = TimeAsX(x0v, t0v; check_approxid = true)

    # return fullX, y0, TX
end
