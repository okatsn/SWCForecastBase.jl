using Dates, DataFrames, OkMakieToolkits
@testset "dataoverview.jl" begin
    a = randn(100)
    a[1:20] .= NaN
    b = Vector{Union{Missing, Float64}}(undef, 100)
    b[1:70] .= randn(70)
    b[71:90] .= NaN
    b[91:100] .= missing
    table_nan = DataFrame(:a => [1,2,NaN], :b => [missing,missing,5], :dt => collect(DateTime("2022-01-01T00:00:00"):Day(1):DateTime("2022-01-03T00:00:00")))
    f, ax, dfxx = dataoverview!(table_nan, DateTime; resolution = (800,500))

    @test true
end
