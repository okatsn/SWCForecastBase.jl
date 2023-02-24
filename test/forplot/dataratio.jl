@testset "dataratio.jl" begin
    using SWCDatasets, Dates
    ari0 = SWCDatasets.dataset("NCUWiseLab", "ARI_G2F820")

    df0 = deepcopy(ari0)
    transform_datetime!(df0, :datetime)

    rows = rand(1:nrow(ari0), 1)
    row = rows[1]

    ## Test if :datetime column successfully and correctly transformed
    @test DateTime(ari0[row, [:year, :month, :day, :hour]]..., 0,0) == floor(df0.datetime[row], Hour)
    @test DateTime(ari0[row, [:year, :month, :day]]..., 0,0) == floor(df0.datetime[row], Day)

    ## Test if the original [:year, :month, :day, :hour, :minute, :second] columns are removed after transformed.
    for ind in [:year, :month, :day, :hour, :minute, :second]
        @test try df0[!, ind]; false; catch e; true end
    end


    for gridsize in [Month(1), Day(1)]
        df0 = deepcopy(ari0)
        table = dataratio(df0, gridsize, SWCForecastBase.islnan)
        DR = DataRatio(df0, gridsize, SWCForecastBase.islnan)

        # Test dataratio basic behaviors
        @test isequal(df0, ari0) # input df0 should not be modified.

        # `DR.table` does not contains info of [:range_from, :range_until, :interval_id]
        @test isequal(table[!, 4:end], DR.table)

        # test the equality of results from dataratio and DataRatio
        @test isequal(table.range_from, DR.dataintervals.from)
        @test isequal(table.range_until, DR.dataintervals.until)
        @test isequal(table.interval_id, DR.dataintervals.identifier)
    end
end

@testset "convert_arguments(DR::DataRatio)" begin
    using SWCDatasets, CairoMakie
    ari0 = SWCDatasets.dataset("NCUWiseLab", "ARI_G2F820")
    heatmap(DataRatio(ari0, Month(1), SWCForecastBase.islnan))
    @test true
end
