function combinegroup_allcols(df, gpby, withwhat)
    df = @chain df begin
        groupby(gpby)
        combine(All() .=> withwhat; renamecols=false)
    end
    return df
end


"""
`combine` the `df` which were grouped by `:hour` taking only the `last`.
"""
function take_hour_last(df)
    combinegroup_allcols(df, :hour, last)
end
