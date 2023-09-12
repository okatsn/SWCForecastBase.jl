"""
`imputemean!(df)` substitute literal `nan` values with the statistical means.
If all missing for a column, value `999` is imputed.

# Notice
- You should be aware that `imputemean!` might does nothing without error message if the input is a view of dataframe (e.g., df[!, Not(:datetime)]).

See also `islnan` for literal `nan`.
"""
function imputemean!(df)
    _replacenanbymissing!(df) # make all literal nan be missing
    _dealwithallmissingby!(df, 999) # if a column is all missing, make it all 999
    Impute.substitute!(df; statistic=mean) # impute missing
    # disallowmissing!(df) # sadly, disallowmissing! does not support subdataframe (e.g., df1 = @view df1[:, Not(:datetime)]; disallowmissing!(df1))
end

"""
Similar to `imputemean!(df)`, `imputeinterp!(df)` interpolate literal `nan` values using linear interpolation, and extrapolate using Next Observation Carried Backward (NOCB) and Last Observation Carried Forward (LOCF).

See also `imputemean!`.
"""
function imputeinterp!(df)
    _replacenanbymissing!(df)
    _dealwithallmissingby!(df, 999)
    Impute.interp!(df)
    Impute.locf!(df)
    Impute.nocb!(df)
    # Reference:
    # https://docs.juliahub.com/Impute/tKYqZ/0.6.8/
    # https://docs.juliahub.com/Impute/tKYqZ/0.5.0/api/impute/#Impute.interp
    # https://docs.juliahub.com/Impute/tKYqZ/0.5.0/api/imputors/#Impute.LOCF
end


function _replacenanbymissing!(df)
    select!(df, AsTable(:) => ByRow(nt -> map(x -> (islnan(x) ? missing : x), nt)) => AsTable) # Also see SWCForecastBase.islnan
    # Substitute NaN by missing:
    # - `df_all = ifelse.(ismissing.(df_all) .| isnan.(df_all), missing, df_all)`
    # - the first `ismissing` since `isnan(missing)` returns `missing`
    # - `true | missing` returns `true`
    # - `false | missing` returns `missing` but it won't happen (since ismissing(x) is false, isnan(x) cannot be missing)
end

function _dealwithallmissingby!(df, to_substitute)
    select!(df, All() .=> (x -> all(ismissing.(x)) ? to_substitute : x); renamecols=false) # if all missing then 999 (e.g., to_substitute = 999)

end


"""
Return `true` if `value` is out of the interval between `l0` and `l1`.
Noted that if value is `missing`, `nothing`, or literally `nan` (see `islnan`), it returns `false` (NOT out-of-range).
"""
isoutofrange(value, l0, l1) = isnnm(value) ? false : (value < l0 || value > l1)

function outer2missing!(df_all, colnames, limits)
    l0, l1 = limits
    df = df_all[!, colnames]
    df_all[!, colnames] = ifelse.(isoutofrange.(df, l0, l1), missing, df)
    df_all
end


"""
`removeunreasonables!(df_all)` convert all column-name specific unreasonable values to `missing`. Noted that `missing`, `nothing` and literal `nan` is not "unreasonable values".

Noted that `removeunreasonables!` will NOT deal with literally Not-a-Number value nor raising an error for any literally Not-a-Number value.
See `isoutofrange`, `islnan`.
"""
function removeunreasonables!(df_all)
    colnames = names(df_all, r"soil_water_content")
    limits = (0, 100)
    outer2missing!(df_all, colnames, limits)

    colnames = names(df_all, r"soil_temperature")
    limits = (-30, 100)
    outer2missing!(df_all, colnames, limits)

    colnames = names(df_all, r"water_temperature")
    limits = (-30, 100)
    outer2missing!(df_all, colnames, limits)

    colnames = names(df_all, r"air_temperature")
    limits = (-30, 100)
    outer2missing!(df_all, colnames, limits)

    colnames = names(df_all, r"humidity")
    limits = (0, 100)
    outer2missing!(df_all, colnames, limits)

    colnames = names(df_all, r"wind_speed")
    limits = (0, Inf)
    outer2missing!(df_all, colnames, limits)

    colnames = names(df_all, r"pressure")
    limits = (0, Inf)
    outer2missing!(df_all, colnames, limits)
end
