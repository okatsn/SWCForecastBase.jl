@testset "cccount" begin
    ts = [0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0]
    ccc = [1, 2, 0, 0, 0, 1, 2, 0, 0, 1, 2, 3]
    @test isequal(SWCForecastBase.cccount(ts), ccc)

    ts = Float64[0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0]
    @test isequal(SWCForecastBase.cccount(ts), ccc)
end


@testset "addcol_accumulation!" begin
    hello = 1.0:22.0 |> collect
    df = DataFrame(
        "hello" => hello,
    )
    @test_throws SWCForecastBase.NotSufficientRows SWCForecastBase.addcol_accumulation!(df, ["hello"], Dict("csum23" => 23))

    SWCForecastBase.addcol_accumulation!(df, ["hello"], Dict("csum5" => 5))
    chello = map(sum, [hello[(i-5+1):i] for i = 5:22])
    @test isequal(chello, df.hello_csum5)
end


@testset "precipmax! 1" begin
    df = DataFrame(
        "precipitation" => randn(101),
        "precipitation_hello_world" => randn(101),
        "not_precipitation" => randn(101),
    )
    maxp = [maximum([p1, p2]) for (p1, p2) in zip(df.precipitation, df.precipitation_hello_world)]
    SWCForecastBase.precipmax!(df)
    @test isequal(maxp, df.precipitation_max)
end



@testset "precipmax! 2" begin
    using DataFrames
    df = DataFrame(
        :a => randn(3),
        :precipitation_01mm => [1, 3, 2],
        :b => randn(3),
        :precipitation_05mm => [4, 5, 1],
        :c => randn(3),
        :precipitation => [2, 4, 3],
        :d => randn(3),
    )
    SWCForecastBase.precipmax!(df)
    # Test interface ("precipitation_max") and functionality
    @test isequal(df.precipitation_max, [4, 5, 3])
    @test isequal(propertynames(df), [:a, :b, :c, :d, :precipitation_max])

end
