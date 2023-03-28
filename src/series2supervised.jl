function colnamevars(data::DataFrame)
    _column_names = names(data)
    data_array = Array(data)  # convert DataFrame to Array to use ShiftedArrays lag function
    return _column_names, data_array
end

function colnamevars(data::Array)
    _column_names = ["var$i" for i in 1:size(data, 2)]
    return _column_names, data
end



"""
```julia
series2supervised(data, range_shift, range_out)
```
Tansform a time series dataset into a supervised learning dataset.

The features will always be suffixed by an addtional time shift tag "_t-i". Also see `split_time_tag()` and `format_time_tag`.

# References:
- https://machinelearningmastery.com/convert-time-series-supervised-learning-problem-python/
"""
function _series2supervised(data, range_shift)
    _column_names, data = colnamevars(data)

    column_values, column_names = [], String[]
    # input sequence
    for i in range_shift
        push!(column_values, Array(ShiftedArrays.lag(data, -i)))
        append!(column_names, string.(_column_names, "_t$i"))
    end

    # put it all together
    agg = cat(column_values...; dims=2)
    agg = DataFrame(agg, column_names)
    return agg
end

"""
To transform a time series dataset into a supervised learning dataset

# Example
```julia
A = randn(500,20)
df = DataFrame(A, :auto)
X0,y0 = series_to_supervised(df[:,1:end-1], df[:,end])
X1,y1 = series2supervised(
    df[:,1:end-1] => range(-6, -1; step=1),
    df[:,end] => range(0, 0; step=-1)
    )
```
# NOTICE!
- The input DataFrame (`df`) must have complete rows; that is, the corresponding time tag (it might be `df.datetime` for example) must be consecutive because `df` is converted to `Matrix` and shifted using `lag`.
- This function filter the dataframe using `completecases`.

# References:
- https://machinelearningmastery.com/convert-time-series-supervised-learning-problem-python/

# TODO: write test for series2supervised, by making sure the datetime shift is correct (e.g., "datetime_t0" should always be 1 hour ahead of "datetime_t-6" for a 10-minute sampling data).
"""
function series2supervised(X_Xshift::Pair...)
    masks = Vector{Bool}[]
    _column_types_Xs = []
    Xs = []
    for p in X_Xshift
        X, Xshift = p
        push!(_column_types_Xs, eltype.(eachcol(X)))
        X = _series2supervised(X, Xshift)
        push!(masks, completecases(X))
        push!(Xs, X)
    end
    mask = (&).(masks...)

    for (i, X) in enumerate(Xs)
        Xs[i] = disallowmissing(X[mask, :])
    end

    for (i, (X, typex)) in enumerate(zip(Xs, _column_types_Xs))
        column_types_X = repeat(
            typex, convert(Int, ncol(X) / length(typex))
        )
        Xs[i] = convert_types(X, Pair.(names(X), column_types_X))
    end
    return (Xs...,)
end


"""
Of a variable of name `varnm`, `diffsstable!(X0::DataFrame, varnm, tshift)` calculates the difference between the non-shifted (suffixed by "\\_t0") and time-shifted (e.g., "\\_t-6"), where the difference is the new column for the series-to-supervised table `X0`.

# Example
```julia
    (X0,) = series2supervised(...)
    diffsstable!(X0, "precipitation_1hr", -6)
```
that creates a new column `diff6_precipitation_1hr = X0[:, "precipitation_1hr_t0"] .- X0[:, "precipitation_1hr_t-6"]`.
"""
function diffsstable!(X0::DataFrame, varnm, tshift)
    DataFrames.transform!(X0, ["$(varnm)_t0", "$(varnm)_t$(tshift)"] => ((xnow, xpast) -> xnow .- xpast) => "diff$(0-tshift)_$(varnm)")
end


function gettshiftval(str::AbstractString)
    # str = "air_temperature_G2F820_t-25"
    mt = match(r"(?<=t)-?\d+", last(split(str, "_")))
    if isnothing(mt)
        return mt
    end

    return parse(Int, mt.match)
end

function gettshiftval(sym::Symbol)
    gettshiftval(String(sym))
end



"""
    narrow_types!(df)

Narrows the `eltype` of each column to the type that actually exists in the each column of
dataframe.

# Arguments
- `df`: Dataframe for which you want to narrow the `eltype` of each column

# References
https://discourse.julialang.org/t/how-to-change-field-names-and-types-of-a-dataframe/43991/9
"""
function narrow_types!(df)
    for column_name in names(df)
        df[!, column_name] = identity.(df[!, column_name])
    end
    return df
end

"""
    convert_types(df, column_names_types)

Converts the element type of each column to a user-specified type.

# Arguments
- `df`: Dataframe for which you want to convert the `eltype` of each column
- `column_names_types`: Column names and target types. The type of `column_names_types`
    should be able to be unpacked into column names and target types in a for loop.

# References
https://discourse.julialang.org/t/how-to-change-field-names-and-types-of-a-dataframe/43991/11
"""
function convert_types(df, column_names_types)
    for (column_name, column_type) in column_names_types
        df[!, column_name] = convert.(column_type, df[!, column_name])
    end
    return df
end


"""
`T` is the datetime of `Y`.
"""
struct SeriesToSupervised
    X
    Y
    T
end

function Base.show(io::IO, sts::SeriesToSupervised)
    indent = get(io, :indent, 0)
    println(io,' '^indent, "input features: $(_brief_info(sts.X)).")
    println(io,' '^indent, "target features: $(_brief_info(sts.Y)).")
    println(io,' '^indent, "time: $(_brief_info(only(eachcol(sts.T))))")
end
