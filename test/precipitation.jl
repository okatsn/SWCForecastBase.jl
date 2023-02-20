@testset "cccount" begin
    ts =  [0,0,1,1,1,0,0,1,1,0,0,0]
    ccc = [1,2,0,0,0,1,2,0,0,1,2,3]
    @test isequal(SWCForecastBase.cccount(ts), ccc)

    ts =  Float64[0,0,1,1,1,0,0,1,1,0,0,0]
    @test isequal(SWCForecastBase.cccount(ts), ccc)
end
