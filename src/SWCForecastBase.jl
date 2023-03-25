module SWCForecastBase

# Write your package code here.
using Impute, Dates, Statistics, DataFrames
include("myimputation/myimpute.jl")
export imputemean!, imputeinterp!, removeunreasonables!


include("myimputation/checkmissnan.jl")
export chknnm, isnnm, islnan

include("pipeline.jl")
export simplepipeline

using Chain
include("combinegroup.jl")
export combinegroup_allcols

using ShiftedArrays
include("series2supervised.jl")
export series2supervised



using NaNMath
include("precipitation.jl")
export movingaverage

using MLJ
include("mljmodels/treemodels.jl")
export fstree, twofstree, manytrees

include("traintest.jl")

using DataFrames
include("preparetable.jl")
export PrepareTable, DefaultPrepareTable, preparetable!, ConfigAccumulate, ConfigPreprocess, ConfigSeriesToSupervised



include("forplot/dataoverview.jl") # only for test

using Dates, Statistics, DataFrames, ShiftedArrays, StructArrays
using CairoMakie
include("forplot/dataratio.jl")
export dataratio, DataRatio, transform_datetime!
end
