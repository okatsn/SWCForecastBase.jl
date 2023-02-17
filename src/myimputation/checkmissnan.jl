"""
Return true if it is literally not a number.
For example, `all(islnan.(["#VALUE!", "nan", "NaN", "Nan", nothing]))` is `true`.
"""
function islnan(x::AbstractString)
    if in(x, ["#VALUE!", "nan", "NaN", "Nan"])
        return true
    else
        return false
    end
end

listfalse = "`Nothing`, `Missing`, `DateTime`, and `AbstractString`"

"""
For `x` being the type other than the types listed above, `islnan(x)` falls back to `isnnm(x)`.

See `isnnm`.
"""
function islnan(x::Any)
    return isnnm(x)
end

"""
Check if `x` is `missing`, `nothing` or `NaN`.
Different from `isnan`, for `x` being either of $listfalse, `islnan(x)` returns `true` for `Nothing` and `Missing`, and returns `false` for the rest.


The difference between `islnan` and `isnnm` is that, `isnnm` check only `NaN` for Not-a-Number. If you input something like `"#VALUE!", "NaN"`, it returns `false` (NOT `missing`, `nothing` or `NaN`).
"""
isnnm(x::Missing) = true
isnnm(x::Nothing) = true
isnnm(x::DateTime) = false
isnnm(x::AbstractString) = false
isnnm(x) = isnan(x)
# function isnnm(x)
#     any(map(fn -> fn(x), (ismissing, isnothing, isnan)))
# end


# Drop missing, nothing and nan (deprecated):
# df_input = filter(row -> !any(f -> any(f.([r for r in row])), (ismissing, isnothing, islnan)), df_all[!,featkeys])
# See: https://stackoverflow.com/questions/62789334/how-to-remove-drop-rows-of-nothing-and-nan-in-julia-dataframe



"""
`chknnm(df)` check if DataFrame `df` contains missing values or NaN.
    Use this before input `df` into machine.
"""
function chknnm(df)
    ddf = describe(df)
    if sum(ddf.nmissing) > 0
        error("There are still missing value(s) in the DataFrame.")
    end

    if any(islnan.(ddf.mean))
        error("Data contains NaN; which might cause crash in model training.")
    end
end
