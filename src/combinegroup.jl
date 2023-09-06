function combinegroup_allcols(df, gpby, withwhat)
    df = @chain df begin
        groupby(gpby)
        combine(All() .=> withwhat; renamecols=false)
    end
    return df
end
