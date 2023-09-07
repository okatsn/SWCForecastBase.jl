#  ━━▶ ━━━┓
# ━┃ ┓ ┗┓⮕
# ┻ ┳┛┏
# ⯅⯆⯇⯈▲▼▶◀
# ┛┻╋┣━━━━━┫
"""
`TrainTestState` is an abstract type of `Prepare`, `Train`, and `Test`, which indicate the current `status` and be in the latest `cache` of the `PrepareTable`.

# Status in the workflow
```
 `PT.status`:
        `nothing`         `Prepare`d
 ╠═══════════════════════╬════════════════════╬...

 PT::PrepareTable
  ┃
  ┗━━━━ preparetable! ━━━┳━━━━━━▶ preparetable!
         ▲               ┃        that creates
         ┗━━━━━━━━━━━━━━━┛    `T.supervised_tables`
       (preprocessing using                   ┃
        different configs)                    ┃
                                              ▼
                           ┏━━ test! ◀━━ train!
     (change parameters to ┃          ▲       ┃
     train or tested again)┗━━━━━━━━━━┻━━━━━━━┛

                         ..═══════════╬═════════..
                          .`Test`ed and `Train`ed
```

# Field
```
args::NamedTuple
```

See also `Cache`.
"""
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

function Base.show(io::IO, tts::TrainTestState)
    indent = get(io, :indent, 0)
    println(io, ' '^(indent + 4), "$(typeof(tts)):")
    for (k, v) in pairs(tts.args)
        println(io, ' '^(indent + 8), "$k: $(_brief_info(v))")
    end
end

"""
# Field
```
prepare::Prepare
train::Train
test::Test
```

See also `TrainTestState`.
"""
mutable struct Cache
    prepare::Prepare
    train::Train
    test::Test
end


abstract type PrepareTableConfig end
PTCdocstring = "Use keyword arguments to construct the object."

"""
`ConfigSeriesToSupervised` controls how the data being shifted; it is for preparing the data for supervised model training.

$PTCdocstring

# Example
```julia
ConfigSeriesToSupervised(;
        shift_x         = [0, -6, -12, -24, -36, -48, -60, -72],
        shift_y         = [1],
        )
```

- `shift_x`: the time shift for the data using as the input features
- `shift_y`: the time shift for the data using as the target features
"""
struct ConfigSeriesToSupervised <: PrepareTableConfig
    shift_x::Vector{<:Int}
    shift_y::Vector{<:Int}
    function ConfigSeriesToSupervised(;
        shift_x=[0, -6, -12, -24, -36, -48, -60, -72],
        shift_y=[1]
    )
        new(shift_x, shift_y)
    end
end

"""
`ConfigPreprocess` controls the primary feature selection and how the data being preprocessed before training.

$PTCdocstring

# Example
```julia
ConfigPreprocess(;
        timeargs = Cols(:year, :month, :day, :hour),
        input_features  = Cols(r"air_temp", r"humidity", r"pressure", r"windspeed", r"precipitation"),
        target_features = Cols(r"soil_water_content"),
        preprocessing   = [take_hour_last, removeunreasonables!, imputeinterp!, disallowmissing!, precipmax!],
        )
```
"""
struct ConfigPreprocess <: PrepareTableConfig
    timeargs::Cols
    input_features::Cols
    target_features::Cols
    preprocessing
    function ConfigPreprocess(;
        timeargs=Cols(:year, :month, :day, :hour), # sort, group by, and combine according to the last
        input_features=Cols(r"air_temp", r"humidity", r"pressure", r"windspeed", r"precipitation"),
        target_features=Cols(r"soil_water_content"),
        preprocessing=[take_hour_last, removeunreasonables!, imputeinterp!, disallowmissing!, precipmax!]
    )
        new(
            timeargs,
            input_features,
            target_features,
            preprocessing,
        )
    end
end

"""
`ConfigAccumulate` generate derived variables as the new columns, by accumulating each variable in `variables` for every interval in each `intervals`.

$PTCdocstring

# Example
```julia
ConfigAccumulate(; variables = Cols(:precipitation_max),
                                intervals = [1, 12, 24, 48, 36],
                                unit = "hr"
        )
```

- `variables`: `Cols` column selector for selecting columns (variables) to be derived.
- `intervals`: the window length for accumulating an variable.
- `unit`: unit of intervals as appended string of the new column, e.g., day.

"""
@kwdef struct ConfigAccumulate <: PrepareTableConfig
    variables::Cols = Cols(:precipitation_max)
    intervals::Vector{<:Int} = [1, 12, 24, 48, 36]
    unit = "" # unit of intervals as appended string of the new column, e.g., day.
end


"""
# Constructor
`PrepareTable(table) = new(table, PrepareTableConfig[])`

# Field
```julia
table::DataFrame
configs::Vector{<:PrepareTableConfig}
status::Union{TrainTestState, Nothing}
supervised_tables::Union{SeriesToSupervised, Nothing}
cache::Cache
```


# Example

```julia
    PrepareTable(df::DataFrame, ConfigPreprocess(), ConfigAccumulate(), ConfigSeriesToSupervised())
```

is equivalently

```julia
    DefaultPrepareTable(df)
```

# Another example
```julia
PrepareTable(df,
    ConfigPreprocess(;target_features=Cols(r"soil_water_content_10cm")),
    ConfigAccumulate(),
    ConfigSeriesToSupervised(; shift_x=[0, -2])
)
```

See also `DefaultPrepareTable`.
"""
mutable struct PrepareTable
    table::DataFrame
    configs::Vector{<:PrepareTableConfig}
    status::Union{TrainTestState,Nothing}
    supervised_tables::Union{SeriesToSupervised,Nothing}
    cache::Cache
    function PrepareTable(table)
        new(table, PrepareTableConfig[], nothing, nothing,
            Cache(
                Prepare(),
                Train(),
                Test()
            )
        )
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
# Default data processing:

```julia
PrepareTableDefault(df::DataFrame) = PrepareTable(df, ConfigPreprocess(), ConfigAccumulate(), ConfigSeriesToSupervised())
```
"""
function PrepareTableDefault(df::DataFrame)
    PrepareTable(df, ConfigPreprocess(), ConfigAccumulate(; unit="hr"), ConfigSeriesToSupervised())
end

function Base.show(io::IO, mime::MIME"text/plain", PT::PrepareTable)
    # See this post for good indentation of show:
    # https://discourse.julialang.org/t/get-fieldnames-and-values-of-struct-as-namedtuple/8991/2
    df = PT.table
    println(io, "PrepareTable")
    println(io, "table:   $(_brief_info(df))`")
    println(io, "configs: ")
    indent = get(io, :indent, 0)
    for config in PT.configs
        show(IOContext(io, :indent => indent + 4), mime, config)
        println(io, "")
    end
    println(io, "status: ")
    # indent = get(io, :indent, 0)
    println(IOContext(io, :indent => indent + 4), "$(PT.status)")
    println(io, "supervised_tables:")
    show(IOContext(io, :indent => indent + 4), mime, PT.supervised_tables)
    println(io, "")
    println(io, "cache: ")
    # indent = get(io, :indent, 0)
    for fnm in fieldnames(Cache)
        println(IOContext(io, :indent => indent + 4), "$(getfield(PT.cache, fnm))")
    end
end

function Base.show(io::IO, PTC::PrepareTableConfig)
    fnames = fieldnames(typeof(PTC))
    println(io, ' '^get(io, :indent, 0), string(typeof(PTC)))
    for nm in fnames
        str = string(getfield(PTC, nm))
        # str = str[1:minimum([30, length(str)])]
        println(io, ' '^(get(io, :indent, 0) + 4), "$(nm): ", str)
    end
end
