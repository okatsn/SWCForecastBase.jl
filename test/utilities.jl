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
