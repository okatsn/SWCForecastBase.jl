module SWCForecastBase

# # Imputation
using Impute, Dates, Statistics, DataFrames
include("myimputation/myimpute.jl")
export imputemean!, imputeinterp!, removeunreasonables!

# # Fundamental utilities

include("myimputation/checkmissnan.jl")
export chknnm, isnnm, islnan

include("pipeline.jl")
export simplepipeline

using Chain
include("combinegroup.jl")
export combinegroup_allcols
include("dataframeutilities/take_hour_last.jl")
export take_hour_last


using NaNMath
include("precipitation.jl")
export movingaverage

# # Series to supervised

using ShiftedArrays
include("series2supervised.jl")
export series2supervised

# # MLJ Model wrappers

using MLJ
include("mljmodels/treemodels.jl")
export fstree, twofstree, manytrees

# # Prepare the table

using DataFrames
include("preparetable/briefinfo.jl")
include("preparetable/preparetable0.jl")
include("preparetable/requirement.jl")
include("preparetable/preparetable.jl")

export PrepareTable, PrepareTableDefault, preparetable!, ConfigAccumulate, ConfigPreprocess, ConfigSeriesToSupervised

# # Train and test

using OkTableTools
include("preparetable/traintest.jl")
export traintest!, train!, test!

using CSV, Random, FileTrees
include("preparetable/save.jl")
export save

# # Plotting

include("forplot/dataoverview.jl") # only for test

using Dates, Statistics, DataFrames, ShiftedArrays, StructArrays
using CairoMakie
include("forplot/dataratio.jl")
export dataratio, DataRatio, transform_datetime!


include("forplot/visualizeresampler.jl")
end
