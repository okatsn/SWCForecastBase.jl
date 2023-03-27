abstract type TrainTestState end

mutable struct Train <: TrainTestState
    args::NamedTuple
end

Train() = Train(NamedTuple())

mutable struct Test <: TrainTestState
    args::NamedTuple
end
Test() = Test(NamedTuple())

mutable struct Prepare <: TrainTestState
    args::NamedTuple
end
Prepare() = Prepare(NamedTuple())



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
        preprocessing   = [take_hour_last, removeunreasonables!, imputeinterp!, disallowmissing!, precipmax!],
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
    supervised_tables::Union{SeriesToSupervised, Nothing}
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
function PrepareTable(df::DataFrame, PTC1::PrepareTableConfig, PTCs::PrepareTableConfig...)
    PT = PrepareTable(df)
    preparetable!(PT, PTC1) # To prevent ERROR: StackOverflow due to the inner constructor PrepareTable(table)
    for PTC in PTCs
        preparetable!(PT, PTC)
    end
    return PT
end

"""
Default data processing:

`PrepareTableDefault(df::DataFrame) = PrepareTable(df, ConfigPreprocess(), ConfigAccumulate(), ConfigSeriesToSupervised())`
"""
function PrepareTableDefault(df::DataFrame)
    PrepareTable(df, ConfigPreprocess(), ConfigAccumulate(; unit="hr"), ConfigSeriesToSupervised())
end

function Base.show(io::IO, mime::MIME"text/plain", PT::PrepareTable)
    # See this post for good indentation of show:
    # https://discourse.julialang.org/t/get-fieldnames-and-values-of-struct-as-namedtuple/8991/2
    df = PT.table
    println(io, "PrepareTable")
    println(io, "table:   $(nrow(df)) by $(ncol(df)) `$(typeof(df))`")
    println(io, "configs: ")
    indent = get(io, :indent, 0)
    for config in PT.configs
        show(IOContext(io, :indent => indent +4), mime, config)
        println(io, "")
    end
    println(io, "state:   $(typeof(PT.state))(...)")
    println(io, "supervised_tables:")
    show(IOContext(io, :indent => indent +4), mime, PT.supervised_tables)
end

function Base.show(io::IO, PTC::PrepareTableConfig)
    fnames = fieldnames(typeof(PTC))
    println(io, ' '^get(io, :indent, 0), string(typeof(PTC)))
    for nm in fnames
        str = string(getfield(PTC, nm))
        # str = str[1:minimum([30, length(str)])]
        println(io, ' '^(get(io, :indent, 0)+4), "$(nm): ", str)
    end
end
