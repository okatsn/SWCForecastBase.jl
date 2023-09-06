@testset "utilities.jl" begin
    using DataFrames

    df = DataFrame(a=repeat([1, 2, 3, 4], outer=[2]),
        b=repeat([2, 1], outer=[4]),
        c=1:8)
    df2 = SWCForecastBase.combinegroup_allcols(df, :b, minimum)
    sort!(df2, :b)
    @test nrow(df2) == 2
    @test df2.c[1] == 2
    @test df2.c[end] == 1
    @test isequal(df2.a, [2, 1])

end

@testset "take_last_hour" begin
    using DataFrames, Dates

    df3 = DataFrame(
        :datetime => DateTime(2018, 2, 5, 0, 0, 0):Second(1):DateTime(2018, 2, 7, 23, 59, 59)
    )
    # insertcols!(df3, :x)
    transform!(df3, :datetime => ByRow(dt -> (
        year=Dates.year(dt),
        month=Dates.month(dt),
        day=Dates.day(dt),
        hour=Dates.hour(dt),
        minute=Dates.minute(dt),
        second=Dates.second(dt),
    )) => AsTable)

    df3c = SWCForecastBase.take_hour_last(df3)
    @test all(df3c.minute .== 59)
    @test all(df3c.second .== 59)
end
