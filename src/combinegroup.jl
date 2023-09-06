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
    @chain df begin
        groupby([:year, :month, :day, :hour])
        combine(last; renamecols=false) # last(df::DataFrame) returns the last row
    end
end
