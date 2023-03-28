var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = SWCForecastBase","category":"page"},{"location":"#SWCForecastBase","page":"Home","title":"SWCForecastBase","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for SWCForecastBase.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [SWCForecastBase]","category":"page"},{"location":"#SWCForecastBase.DataInterval","page":"Home","title":"SWCForecastBase.DataInterval","text":"struct DataInterval\n    from\n    until\n    identifier\nend\n\nfor DataRatio.\n\n\n\n\n\n","category":"type"},{"location":"#SWCForecastBase.DataRatio","page":"Home","title":"SWCForecastBase.DataRatio","text":"struct DataRatio\n    table::DataFrame\n    dataintervals::StructArray\nend\n\nAn DataRatio object that stores the results of dataratio.\n\n\n\n\n\n","category":"type"},{"location":"#SWCForecastBase.DataRatio-Tuple{Any, Any, Any}","page":"Home","title":"SWCForecastBase.DataRatio","text":"DataRatio constructor accept exactly the same arguments as dataratio.\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.PrepareTable","page":"Home","title":"SWCForecastBase.PrepareTable","text":"Constructor\n\nPrepareTable(table) = new(table, PrepareTableConfig[])\n\nField\n\ntable::DataFrame\nconfigs::Vector{<:PrepareTableConfig}\n\n\n\n\n\n","category":"type"},{"location":"#SWCForecastBase.PrepareTable-Tuple{DataFrames.DataFrame, SWCForecastBase.PrepareTableConfig, Vararg{SWCForecastBase.PrepareTableConfig}}","page":"Home","title":"SWCForecastBase.PrepareTable","text":"Given a table::DataFrame and PTCs::PrepareTableConfig..., PrepareTable runs preparetable!(_, PTC::PrepareTableConfig) for PTC in PTCs in @chain.\n\nExample\n\n    PrepareTable(df::DataFrame, ConfigPreprocess(), ConfigSeriesToSupervised())\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.SeriesToSupervised","page":"Home","title":"SWCForecastBase.SeriesToSupervised","text":"T is the datetime of Y.\n\n\n\n\n\n","category":"type"},{"location":"#MakieCore.convert_arguments-Tuple{DataRatio}","page":"Home","title":"MakieCore.convert_arguments","text":"convert_arguments(DR::DataRatio) returns xs, ys, vs for heatmap!(ax, xs, ys, vs,...). This is intended to extend Makie convert_arguments methods for DataRatio, but it does not work with Makie.heatmap. Checkout git branch try-convert_arguments for more details.\n\nExample\n\nusing Dates, SWCDatasets, CairoMakie\nari0 = SWCDatasets.dataset(\"NCUWiseLab\", \"ARI_G2F820\")\nDR = DataRatio(ari0, Month(1), SWCForecastBase.islnan)\nDR |> convert_arguments |> x -> heatmap(x...)\n\n\n\n\n\n","category":"method"},{"location":"#MakieCore.heatmap!-Tuple{Any, DataRatio}","page":"Home","title":"MakieCore.heatmap!","text":"Example\n\nf = Figure(; resolution=(800,600))\nax = Axis(f[1,1])\nhmap = SWCForecastBase.heatmap!(ax, DR::DataRatio; colormap = \"diverging_rainbow_bgymr_45_85_c67_n256\")\nColorbar(f[1, 2], hmap, label = \"missing data rate\")\n\nSee DataRatio and SWCForecastBase.convert_arguments.\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.PrepareTableDefault-Tuple{DataFrames.DataFrame}","page":"Home","title":"SWCForecastBase.PrepareTableDefault","text":"Default data processing:\n\nPrepareTableDefault(df::DataFrame) = PrepareTable(df, ConfigPreprocess(), ConfigAccumulate(), ConfigSeriesToSupervised())\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase._series2supervised-Tuple{Any, Any}","page":"Home","title":"SWCForecastBase._series2supervised","text":"series2supervised(data, range_shift, range_out)\n\nTansform a time series dataset into a supervised learning dataset.\n\nThe features will always be suffixed by an addtional time shift tag \"t-i\". Also see `splittimetag()andformattime_tag`.\n\nReferences:\n\nhttps://machinelearningmastery.com/convert-time-series-supervised-learning-problem-python/\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.addcol_accumulation!-Tuple{Any, Any, Any}","page":"Home","title":"SWCForecastBase.addcol_accumulation!","text":"Add columns that are derived by accumulating corresponding variables using movingaverage.\n\nExample\n\nall_precipstr = names(df, r\"precipitation\")\n\napd = Dict( # time intervals to accumulates precipitation\n    \"1hour\" => 6,\n    \"12hour\" => 6*12,\n    \"1day\" => 6*24,\n    \"2day\" => 6*24*2,\n    \"3day\" => 6*24*3\n)\n\naddcol_accumulation!(df, all_precipstr, apd)\n\n\nSee also: movingaverage.\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.cccount-Tuple{Any}","page":"Home","title":"SWCForecastBase.cccount","text":"Of a time series ts, cccount(ts) calculate by default the cumulative counts of elements that approximates zero consecutively.\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.chknnm-Tuple{Any}","page":"Home","title":"SWCForecastBase.chknnm","text":"chknnm(df) check if DataFrame df contains missing values or NaN.     Use this before input df into machine.\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.convert_types-Tuple{Any, Any}","page":"Home","title":"SWCForecastBase.convert_types","text":"convert_types(df, column_names_types)\n\nConverts the element type of each column to a user-specified type.\n\nArguments\n\ndf: Dataframe for which you want to convert the eltype of each column\ncolumn_names_types: Column names and target types. The type of column_names_types   should be able to be unpacked into column names and target types in a for loop.\n\nReferences\n\nhttps://discourse.julialang.org/t/how-to-change-field-names-and-types-of-a-dataframe/43991/11\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.dataoverview-Tuple{DataFrames.DataFrame, DataType}","page":"Home","title":"SWCForecastBase.dataoverview","text":"dataoverview(df::DataFrame, xtype::DataType; gridsize = gridsize, set_left_edge=leftfn, set_right_edge=rightfn) plot the overview of data in  DataFrame df. xtype specify the only column type (e.g., DateTime) for x-axis.\n\nExample\n\nusing Dates, DataFrames, OkMakieToolkits, Makie\na = randn(100)\na[1:20] .= NaN\nb = Vector{Union{Missing, Float64}}(undef, 100)\nb[1:70] .= randn(70)\nb[71:90] .= NaN\nb[91:100] .= missing\ntable_nan = DataFrame(:a => [1,2,NaN], :b => [missing,missing,5], :dt => collect(DateTime(\"2022-01-01T00:00:00\"):Day(1):DateTime(\"2022-01-03T00:00:00\")))\nxs, ys, vs, xtick_label, ytick_label = dataoverview(table_nan, DateTime)\n\nMakie.save(\"Fig_dataoverview.eps\", f)\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.dataratio-Tuple{DataFrames.DataFrame, Dates.DatePeriod, Function}","page":"Home","title":"SWCForecastBase.dataratio","text":"dataratio(df::DataFrame, gridsize::DatePeriod, iswhat::Function;\n                        groupbycol=:datetime)\n\nGiven data (df), and size of intervals in DatePeriod (gridsize), dataratio returns a combined dataframe of all Not(groupbycol) with interval_id where iswhat for each element in a column ByRow is true.\n\nAlso see DataRatio.\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.diffsstable!-Tuple{DataFrames.DataFrame, Any, Any}","page":"Home","title":"SWCForecastBase.diffsstable!","text":"Of a variable of name varnm, diffsstable!(X0::DataFrame, varnm, tshift) calculates the difference between the non-shifted (suffixed by \"_t0\") and time-shifted (e.g., \"_t-6\"), where the difference is the new column for the series-to-supervised table X0.\n\nExample\n\n    (X0,) = series2supervised(...)\n    diffsstable!(X0, \"precipitation_1hr\", -6)\n\nthat creates a new column diff6_precipitation_1hr = X0[:, \"precipitation_1hr_t0\"] .- X0[:, \"precipitation_1hr_t-6\"].\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.fstree-Tuple{}","page":"Home","title":"SWCForecastBase.fstree","text":"Return a composite tree model with FeatureSelector.\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.imputemean!-Tuple{Any}","page":"Home","title":"SWCForecastBase.imputemean!","text":"imputemean!(df) substitute literal nan values with the statistical means. If all missing for a column, value 999 is imputed.\n\nNotice\n\nYou should be aware that imputemean! might does nothing without error message if the input is a view of dataframe (e.g., df[!, Not(:datetime)]).\n\nSee also islnan for literal nan.\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.islnan-Tuple{AbstractString}","page":"Home","title":"SWCForecastBase.islnan","text":"Return true if it is literally not a number. For example, all(islnan.([\"#VALUE!\", \"nan\", \"NaN\", \"Nan\", nothing])) is true.\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.islnan-Tuple{Any}","page":"Home","title":"SWCForecastBase.islnan","text":"For x being the type other than the types listed above, islnan(x) falls back to isnnm(x).\n\nSee isnnm.\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.isnnm-Tuple{Missing}","page":"Home","title":"SWCForecastBase.isnnm","text":"Check if x is missing, nothing or NaN. Different from isnan, for x being either of Nothing, Missing, DateTime, and AbstractString, islnan(x) returns true for Nothing and Missing, and returns false for the rest.\n\nThe difference between islnan and isnnm is that, isnnm check only NaN for Not-a-Number. If you input something like \"#VALUE!\", \"NaN\", it returns false (NOT missing, nothing or NaN).\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.isoutofrange-Tuple{Any, Any, Any}","page":"Home","title":"SWCForecastBase.isoutofrange","text":"Return true if value is out of the interval between l0 and l1. Noted that if value is missing, nothing, or literally nan (see islnan), it returns false (NOT out-of-range).\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.manytrees-Tuple{}","page":"Home","title":"SWCForecastBase.manytrees","text":"A random forest using EnsembleModel\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.movingaverage-Tuple{Vector{<:AbstractFloat}, Int64}","page":"Home","title":"SWCForecastBase.movingaverage","text":"movingaverage(v, n) returns a vector of moving averaged v by every n.\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.narrow_types!-Tuple{Any}","page":"Home","title":"SWCForecastBase.narrow_types!","text":"narrow_types!(df)\n\nNarrows the eltype of each column to the type that actually exists in the each column of dataframe.\n\nArguments\n\ndf: Dataframe for which you want to narrow the eltype of each column\n\nReferences\n\nhttps://discourse.julialang.org/t/how-to-change-field-names-and-types-of-a-dataframe/43991/9\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.precipmax!-Tuple{DataFrames.DataFrame}","page":"Home","title":"SWCForecastBase.precipmax!","text":"precipmax!(df::DataFrame) creates precipitation_max by maximize Cols(r\"\\Aprecipitation\") ByRow.\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.preparetable!-Tuple{PrepareTable, ConfigAccumulate}","page":"Home","title":"SWCForecastBase.preparetable!","text":"\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.preparetable!-Tuple{PrepareTable, ConfigPreprocess}","page":"Home","title":"SWCForecastBase.preparetable!","text":"preparetable!(PT::PrepareTable, PTC::ConfigPreprocess) generates datetime column by PTC.timeargs, sort! by :datetime, do PTC.preprocessing in @chain and check if the table is continuous in time.\n\nnote: Note\nThis method will raise essential error, that PTC::ConfigPreprocess should be the first arg in args of PrepareTable(PT, args...). Otherwise, the succeeding processing such as ConfigAccumulate or ConfigSeriesToSupervised may give incorrect results without error.\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.removeunreasonables!-Tuple{Any}","page":"Home","title":"SWCForecastBase.removeunreasonables!","text":"removeunreasonables!(df_all) convert all column-name specific unreasonable values to missing. Noted that missing, nothing and literal nan is not \"unreasonable values\".\n\nNoted that removeunreasonables! will NOT deal with literally Not-a-Number value nor raising an error for any literally Not-a-Number value. See isoutofrange, islnan.\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.save-Tuple{PrepareTable, Any}","page":"Home","title":"SWCForecastBase.save","text":"save(PT::PrepareTable, dir0) save cache in PT to the directory dir0.\n\nExample\n\ndir0 = \"MyResults\"\nsave(PT::PrepareTable, dir0)\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.save-Tuple{PrepareTable}","page":"Home","title":"SWCForecastBase.save","text":"Without specifying the parent folder dir0, a folder with randomstring will be generated.\n\nExample\n\nsave(PT::PrepareTable) # save results to /Tables_Fsd0w4/... for example\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.series2supervised-Tuple{Vararg{Pair}}","page":"Home","title":"SWCForecastBase.series2supervised","text":"To transform a time series dataset into a supervised learning dataset\n\nExample\n\nA = randn(500,20)\ndf = DataFrame(A, :auto)\nX0,y0 = series_to_supervised(df[:,1:end-1], df[:,end])\nX1,y1 = series2supervised(\n    df[:,1:end-1] => range(-6, -1; step=1),\n    df[:,end] => range(0, 0; step=-1)\n    )\n\nNOTICE!\n\nThe input DataFrame (df) must have complete rows; that is, the corresponding time tag (it might be df.datetime for example) must be consecutive because df is converted to Matrix and shifted using lag.\nThis function filter the dataframe using completecases.\n\nReferences:\n\nhttps://machinelearningmastery.com/convert-time-series-supervised-learning-problem-python/\n\nTODO: write test for series2supervised, by making sure the datetime shift is correct (e.g., \"datetimet0\" should always be 1 hour ahead of \"datetimet-6\" for a 10-minute sampling data).\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.take_hour_last-Tuple{Any}","page":"Home","title":"SWCForecastBase.take_hour_last","text":"combine the df which were grouped by :hour taking only the last.\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.transform_datetime!-Tuple{DataFrames.DataFrame, Any}","page":"Home","title":"SWCForecastBase.transform_datetime!","text":"transform_datetime!(df::DataFrame, groupbycol; list=[:year, :month, :day, :hour, :minute, :second]) attempts to convert the groupbycol = :datetime column from :year, :month, :day, :hour, :minute, :second.\n\nNoted that once transformed, columns in list will be removed by default.\n\n\n\n\n\n","category":"method"},{"location":"#SWCForecastBase.twofstree-Tuple{}","page":"Home","title":"SWCForecastBase.twofstree","text":"Return a composite tree model with TWO FeatureSelector: selector_1 and selector_2.\n\n\n\n\n\n","category":"method"}]
}
