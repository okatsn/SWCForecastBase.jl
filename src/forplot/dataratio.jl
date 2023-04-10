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
This is intended to extend Makie `convert_arguments` methods for `DataRatio`, but it does not work with Makie.heatmap. Checkout git branch try-convert_arguments for more details.

# Example
```julia
using Dates, SWCExampleDatasets, CairoMakie
ari0 = SWCExampleDatasets.dataset("NCUWiseLab", "ARI_G2F820_example")
DR = DataRatio(ari0, Month(1), SWCForecastBase.islnan)
DR |> convert_arguments |> x -> heatmap(x...)
```
"""
function CairoMakie.convert_arguments(DR::DataRatio)

    iter_columns = pairs(eachcol(DR.table))

    # y is index to column (which data/variable), x is index to row (which interval_id)
    name_points = [colname => (x, y, v) for (y,(colname, colval)) in enumerate(iter_columns) for (x, v) in enumerate(colval)]

    # ytick_label = [(y,name) for (y,(name, val)) in enumerate(iter_columns)]
    # xtick_label = [(row.interval_id, Dates.format(row.dt0, "u.")) for row in eachrow(dfranges)]


    npts = name_points
    xs = first.(last.(npts))       .|> Float64
    ys = getindex.(last.(npts), 2) .|> Float64
    vs = last.(last.(npts))        .|> Float64

    args = (xs, ys, vs)
    # kwargs = (ytick_label)
    # return (args = args, kwargs = kwargs)
    return args
end

"""
# Example
```julia
using CairoMakie, SWCForecastBase
f = Figure(; resolution=(800,600))
ax = Axis(f[1,1])
hmap = heatmap!(ax, DR::DataRatio; colormap = "diverging_rainbow_bgymr_45_85_c67_n256")
Colorbar(f[1, 2], hmap, label = "missing data rate")
```

See `DataRatio` and `SWCForecastBase.convert_arguments`.

"""
function CairoMakie.heatmap!(ax, DR::DataRatio; kwargs...)
    hmap = CairoMakie.heatmap!(ax, convert_arguments(DR)...; kwargs...)
    ytick_label = DR.table |> names
    xlabels = DR.dataintervals.from |> dt -> Dates.format.(dt, "d/u.")
    xticks = DR.dataintervals.identifier # interval_id
    xtick_label = [(t, l) for (t, l) in zip(xticks, xlabels)]

    ax.yticks[] = (eachindex(ytick_label), ytick_label) # a tuple (values, names)
    ax.xticks[] = (first.(xtick_label), string.(last.(xtick_label)))
    return hmap
end
