gridsize = Month(1)
leftfn(t) = floor(minimum(t), gridsize)
rightfn(t) = ceil(maximum(t), gridsize)


"""
`dataoverview!(df::DataFrame, xtype::DataType; gridsize = gridsize, set_left_edge=leftfn, set_right_edge=rightfn)` plot the overview of data in  DataFrame `df`. `xtype` specify the only column type (e.g., `DateTime`) for x-axis.

# Example
```julia
using Dates, DataFrames, OkMakieToolkits, Makie
a = randn(100)
a[1:20] .= NaN
b = Vector{Union{Missing, Float64}}(undef, 100)
b[1:70] .= randn(70)
b[71:90] .= NaN
b[91:100] .= missing
table_nan = DataFrame(:a => [1,2,NaN], :b => [missing,missing,5], :dt => collect(DateTime("2022-01-01T00:00:00"):Day(1):DateTime("2022-01-03T00:00:00")))
f, ax, dfxx = dataoverview!(table_nan, DateTime; resolution = (800,500))
Makie.save("Fig_dataoverview.eps", f)
```
"""
function dataoverview!(df::DataFrame, xtype::DataType; gridsize = gridsize, set_left_edge=leftfn, set_right_edge=rightfn, resolution = (800,600))

    iddt = isequal.(eltype.(eachcol(df)), xtype)
    xname = df[!, iddt] |> names |> only |> Symbol # You can have only 1 colume with its eltype being `DateTime`
    sort!(df, [xname]);

    datax0, datax1= extrema(df[!,xname])

    ledge = set_left_edge(df[!, xname]) # Set the most-left edge
    redge = set_right_edge(df[!, xname]) # Set the most-right edge
    range0 = range(ledge, redge, step = gridsize) |> collect
    # extend one step anyway to allow the last point to be covered in the later chkdt

    dfranges = DataFrame(:dt0 => lag(range0), :dt1 => range0) |> dropmissing
    dftrans!(dfranges, [:dt0, :dt1] => ByRow((t0, t1) -> (t -> (t0 <= t <= t1))) => :fnx)
    dftrans!(dfranges, eachindex => :dtgroup)
    # fnx = [t -> row.dt0 <= t < row.dt1 for row in eachrow(dfranges)]
    # insertcols!(dfranges, :fnx => fnx)

    chkdt(dt::DateTime) = last(findall(map(fn -> fn(dt), dfranges.fnx))) # check a DateTime dt belonging to which group

    select!(df, xname, Not(xname) .=> ByRow(val -> islnan(val) ); renamecols=false)
    dftrans!(df, xname => ByRow(chkdt) => :dtgroup )
    dfmsrate = combine(groupby(df, :dtgroup), Not(xname) .=> mean; renamecols=false)

    # col = eachcol(dfmsrate) |> last

    # [(n, i) for (i,(n,v)) in enumerate(pairs(eachcol(dfmsrate)))]


    iter_columns = pairs(eachcol(select(dfmsrate, Not(:dtgroup))))

    name_points = [colname => (x, y, v) for (y,(colname, colval)) in enumerate(iter_columns) for (x, v) in enumerate(colval)]
    # [(x, colname, v) for (x, v) in enumerate(colval) for (colname, colval) in pairs(eachcol(dfmsrate)) ] # wrong

    ytick_label = [(y,name) for (y,(name, val)) in enumerate(iter_columns)]
    xtick_label = [(row.dtgroup, Dates.format(row.dt0, "u.")) for row in eachrow(dfranges)]

    npts = name_points
    xs = first.(last.(npts))       .|> Float64
    ys = getindex.(last.(npts), 2) .|> Float64
    vs = last.(last.(npts))        .|> Float64


    f = Figure(; resolution=resolution)
    ax = Axis(f[1,1])
    hmap = heatmap!(ax, xs, ys, vs; colormap = "diverging_rainbow_bgymr_45_85_c67_n256")
    ax.yticks[] = (first.(ytick_label), string.(last.(ytick_label))) # a tuple (values, names)
    ax.xticks[] = (first.(xtick_label), string.(last.(xtick_label)))
    Colorbar(f[1, 2], hmap, label = "missing data rate")

    return f, ax, dfmsrate

# todo: heatmap with values on each cell: https://discourse.julialang.org/t/makie-how-to-set-custom-x-and-y-tick-values-in-a-makie-heatmap/81397

end
