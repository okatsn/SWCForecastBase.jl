@testset "dataratio.jl" begin
    using SWCExampleDatasets, Dates
    ari0 = SWCExampleDatasets.dataset("NCUWiseLab", "ARI_G2F820_example")

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
    using Dates, SWCExampleDatasets, CairoMakie
    ari0 = SWCExampleDatasets.dataset("NCUWiseLab", "ARI_G2F820_example")
    DR = DataRatio(ari0, Month(1), SWCForecastBase.islnan)
    DR |> convert_arguments |> x -> heatmap(x...)
    @test true


    iter_columns = pairs(eachcol(DR.table))

    # y is index to column (which data/variable), x is index to row (which interval_id)
    name_points = [colname => (x, y, v) for (y,(colname, colval)) in enumerate(iter_columns) for (x, v) in enumerate(colval)]

    ytick_label = [(y,name) for (y,(name, val)) in enumerate(iter_columns)]
    xtick_label = [(interval_id, Dates.format(dt0, "d/u.")) for (interval_id, dt0) in zip(DR.dataintervals.identifier, DR.dataintervals.from)]
    f = Figure(; resolution=(800,600))
    ax = Axis(f[1,1])
    hmap = heatmap!(ax, DR; colormap = "diverging_rainbow_bgymr_45_85_c67_n256")
    @test ax.yticks[] == (first.(ytick_label), string.(last.(ytick_label))) # a tuple (values, names)
    @test ax.xticks[] == (first.(xtick_label), string.(last.(xtick_label)))
    Colorbar(f[1, 2], hmap, label = "missing data rate")
end
