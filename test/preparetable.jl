@testset "preparetable.jl" begin
    using SWCDatasets
    passed = false

    try
        df = SWCDatasets.dataset("NCUWiseLab", "ARI_G2F820")
        PT = PrepareTable(df)
        PT = PrepareTableDefault(df)
        passed = true
    catch e
        passed = false
    end
    @test passed || "Basic load and preprocess by default using PrepareTable failed"
    # TODO: it might be more appropriate to have this test in TWAISWCF, since it has SWCDatasets and SWCForecastBase both involved.
end
