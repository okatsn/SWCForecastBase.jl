@testset "preparetable.jl" begin
    using SWCDatasets
    passed = false

    try
        df = SWCDatasets.dataset("NCUWiseLab", "ARI_G2F820")
        PT = PrepareTable(df)
        PT = PrepareTableDefault(df)

        train!(PT; train_before = DateTime(2022, 03, 21))
        test!(PT; test_after = DateTime(2022, 3, 22))

        fnm = PT.supervised_tables.T |> names |> only |> Symbol
        firstid = (PT.supervised_tables.T[!, fnm] .<= DateTime(2022,3,22)) |> findlast
        PT.supervised_tables.T[firstid, fnm] = DateTime(2099, 1,1)
        @test isequal(DateTime(2099, 1,1), PT.cache.test.args.t[1])


        passed = true
    catch e
        passed = false
    end
    @test passed || "Basic load and preprocess by default using PrepareTable failed"
    # TODO: it might be more appropriate to have this test in TWAISWCF, since it has SWCDatasets and SWCForecastBase both involved.

end
