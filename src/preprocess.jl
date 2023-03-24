struct PrepareTable
    shift_x
    shift_y
    time
    input_features
    merge_by
    accumulates
    preprocessing
    table::DataFrame
    function PrepareTable(df::DataFrame;
            shift_x         = [0, -6, -12, -24, -36, -48, -60, -72],
            shift_y         = [1],
            time            = [:year, :month, :day, :hour], # sort, group by, and combine according to the last
            input_features  = Cols(r"air_temp", r"humidity", r"pressure", r"windspeed"),
            target_features = Cols(r"soil_water_content"),
            accumulates     = Dict("precipitation_max" => [1, 12, 24, 48, 36]),
            preprocessing   = [removeunresonables!, imputeinterp!],
        )
    end
end
