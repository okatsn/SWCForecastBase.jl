abstract type PrepareTableConfig end

struct ConfigSeriesToSupervised <: PrepareTableConfig
    shift_x
    shift_y
    function ConfigSeriesToSupervised(;
        shift_x         = [0, -6, -12, -24, -36, -48, -60, -72],
        shift_y         = [1],
        )
        new(shift_x, shift_y)
    end
end

struct ConfigPreprocess <: PrepareTableConfig
    time
    input_features
    target_features
    accumulates
    preprocessing
    function ConfigPreprocess(;
        time            = [:year, :month, :day, :hour], # sort, group by, and combine according to the last
        input_features  = Cols(r"air_temp", r"humidity", r"pressure", r"windspeed"),
        target_features = Cols(r"soil_water_content"),
        accumulates     = Dict("precipitation_max" => [1, 12, 24, 48, 36]),
        preprocessing   = [removeunresonables!, imputeinterp!],
        )
        new(
            time,
            input_features,
            target_features,
            accumulates,
            preprocessing,
        )
    end
end

struct PrepareTable
    config::Vector{<:PrepareTableConfig}
    table::DataFrame
    function PrepareTable(df::DataFrame, PTCs::PrepareTableConfig...)
        df = deepcopy(df)
        for PTC in PTCs
            preparetable!(df, PTC)
        end
        new(PTCs, df)
    end
end


function preparetable!(df, PTC::PrepareTableConfig)
    return nothing # do nothing if the corresponding methods not created
end


function preparetable!(df, PTC::ConfigPreprocess)
    transform!(ari0, [:year, :month, :day, :hour] => ByRow((y,m,d,h) -> DateTime(y,m,d, h, 0, 0)) => :datetime)

    all_precipstr = names(ari0, r"precipitation")

    df = @chain ari0 begin
        removeunreasonables!
        imputeinterp!
        filter!(:datetime => timeselector, _)
        disallowmissing!
        SWCForecastBase.addcol_accumulation!(_, all_precipstr, apd)
    end

    try
        Δt = df.datetime |> diff |> unique |> get1var
    catch
        @warn "The loaded data is not continuous in time."
    end # make sure the data is continuous

end

function preparetable!(df, PTC::ConfigSeriesToSupervised)
    fullX, y0, t0 = series2supervised(
        df[!, Cols(featureselector)]    => tpast,
        df[!, Cols(targetselector)]     => tfuture,
        df[!, [:datetime]]              => tfuture)

    t0v = only(eachcol(t0))
    x0v = eachindex(t0v) |> collect
    TX = TimeAsX(x0v, t0v; check_approxid = true)

    # return fullX, y0, TX
end
