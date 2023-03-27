@testset "preparetable.jl" begin
    using SWCDatasets
    passed = false

    df = SWCDatasets.dataset("NCUWiseLab", "ARI_G2F820")
    PT = PrepareTable(df)
    PT = PrepareTableDefault(df)
    PTx = PrepareTableDefault(df)

    train!(PT; train_before = DateTime(2022, 03, 21))
    test!(PT; test_after = DateTime(2022, 3, 22))

    fnm = PT.supervised_tables.T |> names |> only |> Symbol
    firstid = (PT.supervised_tables.T[!, fnm] .<= DateTime(2022,3,22)) |> findlast
    PT.supervised_tables.T[firstid, fnm] = DateTime(2099, 1,1)
    @test isequal(DateTime(2099, 1,1), PT.cache.test.args.t[1])

    traintest!(PTx; test_after = DateTime(2022, 3, 22), train_before = DateTime(2022, 03, 21))

    @test isequal(PTx.cache.train.args.t, PT.cache.train.args.t)
    @test isequal(PTx.cache.train.args.t, PT.cache.train.args.t)

    # TODO: it might be more appropriate to have this test in TWAISWCF, since it has SWCDatasets and SWCForecastBase both involved.

end
