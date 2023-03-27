@testset "cccount" begin
    ts =  [0,0,1,1,1,0,0,1,1,0,0,0]
    ccc = [1,2,0,0,0,1,2,0,0,1,2,3]
    @test isequal(SWCForecastBase.cccount(ts), ccc)

    ts =  Float64[0,0,1,1,1,0,0,1,1,0,0,0]
    @test isequal(SWCForecastBase.cccount(ts), ccc)
end


@testset "addcol_accumulation!" begin
    hello = 1.0:22.0 |> collect
    df = DataFrame(
        "hello" => hello,
    )
    SWCForecastBase.addcol_accumulation!(df, ["hello"], Dict("csum5" => 5))
    chello = map(sum, [hello[(i-5+1):i] for i = 5:22])
    @test isequal(chello, df.hello_csum5)
end


@testset "precipmax" begin
    df = DataFrame(
        "precipitation" => randn(101),
        "precipitation_hello_world" => randn(101),
        "not_precipitation" => randn(101),
    )
    maxp = [maximum([p1, p2]) for (p1, p2) in zip(df.precipitation, df.precipitation_hello_world)]
    SWCForecastBase.precipmax!(df)
    @test isequal(maxp, df.precipitation_max)
end
