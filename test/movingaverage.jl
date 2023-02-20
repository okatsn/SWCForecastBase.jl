@testset "mvwinmean" begin
    q0 = collect(2.0:6.0)
    a0 = [2.5,3.5,4.5,5.5]

    @test isequal(SWCForecastBase.moving_average(q0, 2), a0)
    @test isequal(SWCForecastBase.rolling_mean4(q0, 2), a0)
    # TODO: Check SWCForecastBase.moving_average2(a0, 2) and SWCForecastBase.rolling_mean3nan(a0, 2)

    @test isequal(SWCForecastBase.mvmean(q0, 2), a0)
    y = randn(10);
    n = 3;
    @test isapprox(SWCForecastBase.mvmean(y, n), SWCForecastBase.moving_average(y,n))
    @test isequal(SWCForecastBase.mvnanmean([1.0, 2.0, 3.0, NaN, 5.0],2), [NaN, 1.5,2.5,1.5,2.5])
    @test isequal(SWCForecastBase.mvnanmean([1.0, 2.0, 3.0, NaN,NaN, 5.0],2), [NaN, 1.5,2.5,1.5,0.0,2.5]) # WARN: all NaN in the moving window results zero, NOT NaN.

    @test isequal(SWCForecastBase.slowmvnanmean([1.0, 2.0, 3.0, NaN,NaN, 5.0],2), [NaN, 1.5,2.5,1.5,NaN,2.5])
end
