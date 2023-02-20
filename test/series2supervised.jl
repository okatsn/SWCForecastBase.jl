using ShiftedArrays
@testset "series2supervised.jl" begin

    function series_to_supervised(
        data::Union{DataFrame,Array}; num_in=1, num_out=1, isdropmissing=true, time_step=1
    )
        is_dataframe = isa(data, DataFrame)
        if is_dataframe
            _column_names = names(data)
            data = Array(data)  # convert DataFrame to Array to use ShiftedArrays lag function
        else
            _column_names = ["var$i" for i in 1:size(data, 2)]
        end

        column_values, column_names = [], String[]
        # input sequence (t-num_in, ... t-1)
        for i in range(num_in, 1; step=-time_step)
            push!(column_values, Array(ShiftedArrays.lag(data, i)))
            append!(column_names, string.(_column_names, "_t-$i"))
        end
        # forecast sequence (t, t+1, ... t+num_out)
        for i in range(0, num_out - 1; step=time_step)
            push!(column_values, Array(ShiftedArrays.lag(data, -i)))
            if i == 0
                append!(column_names, string.(_column_names, "_t"))
            else
                append!(column_names, string.(_column_names, "_t+$i"))
            end
        end

        # WARN: features should always be suffixed by an addtional time shift tag "_t-i". Also see `split_time_tag()` and `format_time_tag`

        # put it all together
        agg = cat(column_values...; dims=2)
        agg = DataFrame(agg, column_names)
        if isdropmissing
            @debug "Remove rows with `missing` in a DataFrame"
            return dropmissing!(agg)
        else
            @debug "Keep rows with `missing` in a DataFrame"
            return agg
        end
    end

    """
    To transform a time series dataset into a supervised learning dataset

    # References:
    - https://machinelearningmastery.com/convert-time-series-supervised-learning-problem-python/
    """
    function series_to_supervised(X, y; x_num_in = 6, y_num_out=1)
        _column_types_X = eltype.(eachcol(X))
        _column_types_y = eltype.(eachcol(y))

        X = series_to_supervised(X; num_in=x_num_in, num_out=0, isdropmissing=false)
        y = series_to_supervised(y; num_in=0, num_out=y_num_out, isdropmissing=false)
        mask = completecases(X) .& completecases(y)
        X = disallowmissing(X[mask, :])
        y = disallowmissing(y[mask, :])  #[:, end-1:end]  # hard code

        column_types_X = repeat(
            _column_types_X, convert(Int, ncol(X) / length(_column_types_X))
        )
        column_types_y = repeat(
            _column_types_y, convert(Int, ncol(y) / length(_column_types_y))
        )
        X = SWCForecastBase.convert_types(X, Pair.(names(X), column_types_X))
        y = SWCForecastBase.convert_types(y, Pair.(names(y), column_types_y))

        return X, y
    end

    A = randn(500,5)
    df = DataFrame(A, [:x1, :x2, :x3, :x4, :y])
    X0,y0 = series_to_supervised(df[:,1:end-1], df[:,end])
    X1,y1 = series2supervised(
        df[:,1:end-1] => range(-6, -1; step=1),
        df[:,end:end] => range(0, 0; step=-1))
    @test isequal(X0,X1)

    @test isequal(X1[:,"x1_t-6"], ShiftedArrays.lag(df.x1, 6)[7:end])

    validateshift = [isequal(Matrix(X1[:,Regex("_t-$i")]), Matrix(select(df, [:x1, :x2, :x3, :x4] .=> (x -> ShiftedArrays.lag(x, i)); renamecols=false))[7:end,:]) for i in 1:6]

    @test all(validateshift)

    getshifty(i) = ShiftedArrays.lag(y1[:, "y_t0"], i) |> Vector # If shifted array is not converted to array, stack overflow error will occur in hcat

    # Check if the two matrices are equal
    validatexymatch = [isequal(
            Matrix(hcat(X1[:, Regex("t-$i")], getshifty(i))[i+1:end, :]),
            Matrix(df[7:end-i,:])
        ) for i in 1:6]
    @test all(validatexymatch)



    X0,y0 = series_to_supervised(A[:,1:end-1], A[:,end])
    X1,y1 = series2supervised(
        A[:,1:end-1] => range(-6, -1; step=1),
        A[:,end] => range(0, 0; step=-1))

    @test isequal(X0,X1)
end


@testset "gettshiftval" begin
    feats = [
        "hour_t-1",
        "hour_t-2",
        "hour_t-3",
        "pressure_t-1",
        "pressure_t-2",
        "pressure_t-3",
        "precipitation_t-1",
        "precipitation_t-2",
    ]
    @test isequal(SWCForecastBase.gettshiftval.(feats), [-1,-2,-3,-1,-2,-3,-1,-2])
end



using DataFrames
@testset "narrow_types! and convert_types" begin
    df = DataFrame(; x=Any[i for i in 1:10], y=Union{Float64,Missing}[i for i in 1:10])
    SWCForecastBase.narrow_types!(df)
    @test eltype.(eachcol(df)) == [Int64, Float64]

    df = DataFrame(; x=Any[i for i in 1:10], y=Union{Float64,Missing}[i for i in 1:10])
    df = SWCForecastBase.convert_types(df, [:x => Float64, :y => Float64])
    @test eltype.(eachcol(df)) == [Float64, Float64]
end
