"""
```julia
dataratio(df::DataFrame, gridsize::DatePeriod;
        groupbycol=:datetime,
        iswhat::Function=islnan)
```

Given data (`df`), and size of intervals in `DatePeriod` (`gridsize`), `dataratio` returns a combined dataframe of all `Not(groupbycol)` with `ratio_in_interval`.

"""
function dataratio(df::DataFrame, gridsize::DatePeriod;
                        groupbycol=:datetime,
                        iswhat::Function=islnan)
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
    DataFrames.transform!(dfranges, eachindex => :ratio_in_interval)
    # fnx = [t -> row.dt0 <= t < row.dt1 for row in eachrow(dfranges)]
    # insertcols!(dfranges, :fnx => fnx)

    chkdt(dt::DateTime) = last(findall(map(fn -> fn(dt), dfranges.fnx))) # check a DateTime dt belonging to which group

    select!(df, xname, Not(xname) .=> ByRow(val -> iswhat(val) ); renamecols=false)
    DataFrames.transform!(df, xname => ByRow(chkdt) => :ratio_in_interval )
    dfmsrate = combine(groupby(df, :ratio_in_interval), Not(xname) .=> mean; renamecols=false)

end

"""
`transform_datetime!(df::DataFrame, groupbycol; list=[:year, :month, :day, :hour, :minute, :second])` attempts to convert the `groupbycol = :datetime` column from `:year`, `:month`, `:day`, `:hour`, `:minute`, `:second`.
"""
function transform_datetime!(df::DataFrame, groupbycol; list=[:year, :month, :day, :hour, :minute, :second])
    iscol = columnindex.([df], list) .> 0

    defaults = fill(0, sum(.!iscol))
    fn = (args...) -> DateTime(args..., defaults...)

    args = list[iscol]
    @assert length(args) + length(defaults) == length(list) # fixme: this test is excessive
    transform!(df, args => ByRow(fn) => groupbycol)
end
