"""
```julia
struct DataInterval
    from
    until
    identifier
end
```

for `DataRatio`.
"""
struct DataInterval
    from
    until
    identifier
end

"""
```julia
struct DataRatio
    table::DataFrame
    dataintervals::StructArray
end
```
An `DataRatio` object that stores the results of `dataratio`.
"""
struct DataRatio
    table::DataFrame
    dataintervals::StructArray{DataInterval}
end

"""
`DataRatio` constructor accept exactly the same arguments as `dataratio`.
"""
function DataRatio(df, gridsize, iswhat; kwargs...)
    table = dataratio(df, gridsize, iswhat)
    DR = DataRatio(table, StructArray{DataInterval}((
                        table.range_from,
                        table.range_until,
                        table.interval_id)
                        )
                    )
    table = select!(table, Not([:range_from, :range_until, :interval_id])) # Noted that DR.table is (should) be changed!
    return DR
end


"""
```julia
dataratio(df::DataFrame, gridsize::DatePeriod, iswhat::Function;
                        groupbycol=:datetime)
```

Given data (`df`), and size of intervals in `DatePeriod` (`gridsize`), `dataratio` returns a combined dataframe of all `Not(groupbycol)` with `interval_id` where `iswhat` for each element in a column `ByRow` is true.

Also see `DataRatio`.
"""
function dataratio(df::DataFrame, gridsize::DatePeriod, iswhat::Function;
                        groupbycol=:datetime)
    df = deepcopy(df)
    set_left_edge(t) = floor(minimum(t), gridsize)
    set_right_edge(t) = ceil(maximum(t), gridsize)


    if columnindex(df, groupbycol) > 0 # first check if groupbycol exists
        @assert eltype(df[!, groupbycol]) <: TimeType
        xname = groupbycol
    else # if not, try to find the only column of DateTime
        iddt = isequal.(eltype.(eachcol(df)), DateTime)
        if any(iddt)
            xname = df[!, iddt] |> names |> only |> Symbol
        else
            transform_datetime!(df, groupbycol)
            xname = groupbycol
        end
    end
    # sort!(df, [xname]);


    # datax0, datax1= extrema(df[!,xname])

    ledge = set_left_edge(df[!, xname]) # Set the most-left edge
    redge = set_right_edge(df[!, xname]) # Set the most-right edge
    range0 = range(ledge, redge, step = gridsize) |> collect
    # extend one step anyway to allow the last point to be covered in the later chkdt

    dfranges = DataFrame(:dt0 => ShiftedArrays.lag(range0), :dt1 => range0) |> dropmissing
    DataFrames.transform!(dfranges, [:dt0, :dt1] => ByRow((t0, t1) -> (t -> (t0 <= t <= t1))) => :fnx)
    DataFrames.transform!(dfranges, eachindex => :interval_id)
    # fnx = [t -> row.dt0 <= t < row.dt1 for row in eachrow(dfranges)]
    # insertcols!(dfranges, :fnx => fnx)

    chkdt(dt::DateTime) = last(findall(map(fn -> fn(dt), dfranges.fnx))) # check a DateTime dt belonging to which group

    select!(df, xname, Not(xname) .=> ByRow(val -> iswhat(val) ); renamecols=false)
    DataFrames.transform!(df, xname => ByRow(chkdt) => :interval_id )
    dfmsrate = combine(groupby(df, :interval_id), Not(xname) .=> mean; renamecols=false)
    insertcols!(dfmsrate, 1, :range_from => dfranges.dt0, :range_until => dfranges.dt1)
    return dfmsrate
end

"""
`transform_datetime!(df::DataFrame, groupbycol; list=[:year, :month, :day, :hour, :minute, :second])` attempts to convert the `groupbycol = :datetime` column from `:year`, `:month`, `:day`, `:hour`, `:minute`, `:second`.

Noted that once transformed, columns in `list` will be removed by default.
"""
function transform_datetime!(df::DataFrame, groupbycol;
            list=[:year, :month, :day, :hour, :minute, :second])
    iscol = columnindex.([df], list) .> 0

    defaults = fill(0, sum(.!iscol))
    fn = (args...) -> DateTime(args..., defaults...)

    args = list[iscol]
    @assert length(args) + length(defaults) == length(list) # fixme: this test is excessive
    transform!(df, args => ByRow(fn) => groupbycol)
    select!(df, Not(args)) # remove args (:year, :month, ...)
end


"""
`convert_arguments(DR::DataRatio)` returns `xs, ys, vs` for `heatmap!(ax, xs, ys, vs,...)`.
This extends Makie `convert_arguments` methods for `DataRatio`.
"""
function SWCForecastBase.convert_arguments(DR::DataRatio)

    iter_columns = pairs(eachcol(DR.table))

    # y is index to column (which data/variable), x is index to row (which interval_id)
    name_points = [colname => (x, y, v) for (y,(colname, colval)) in enumerate(iter_columns) for (x, v) in enumerate(colval)]

    # ytick_label = [(y,name) for (y,(name, val)) in enumerate(iter_columns)]
    # xtick_label = [(row.dtgroup, Dates.format(row.dt0, "u.")) for row in eachrow(dfranges)]


    npts = name_points
    xs = first.(last.(npts))       .|> Float64
    ys = getindex.(last.(npts), 2) .|> Float64
    vs = last.(last.(npts))        .|> Float64

    return (xs, ys, vs) # failed at ERROR: MethodError: no method matching to_rgba_image(::Vector{Float64}, ::Heatmap{Tuple{Vector{Float64}, Vector{Float64}, Vector{Float64}}})
    # return (xs[:,:], ys[:,:], vs[:,:]) # heatmap(DR) works BUT the heatmap is apparently not what we want.
end

# FIXME:
# - Without `SWCForecastBase.` (i.e., `SWCForecastBase.convert_arguments`), it won't work (MethodError: no method matching convert_arguments in test)
# - With `SWCForecastBase.` and the following function, test passed BUT not worked in either this or another environment.
SWCForecastBase.convert_arguments(P::DiscreteSurface, x::DataRatio) = convert_arguments(x)
