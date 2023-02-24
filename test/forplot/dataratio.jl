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



    gridsize = Month(1)
    df0 = deepcopy(ari0)

    DR = DataRatio(df0, gridsize, islnan)

    # Basic content check
    @test isequal(df0, ari0) # input df0 should not be modified.
    @test isequal(islnan, DR.ratioof)
    @test isequal(gridsize, DR.gridsize)
end
