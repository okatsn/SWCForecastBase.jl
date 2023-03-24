module SWCForecastBase

# Write your package code here.
using Impute, Dates, Statistics, DataFrames
include("myimputation/myimpute.jl")
export imputemean!, imputeinterp!, removeunreasonables!


include("myimputation/checkmissnan.jl")
export chknnm, isnnm, islnan

using ShiftedArrays
include("series2supervised.jl")
export series2supervised



using NaNMath
include("precipitation.jl")
export movingaverage

using MLJ
include("mljmodels/treemodels.jl")
export fstree, twofstree, manytrees


using DataFrames
include("preparetable.jl")
export PrepareTable



include("forplot/dataoverview.jl") # only for test

using Dates, Statistics, DataFrames, ShiftedArrays, StructArrays
import CairoMakie
include("forplot/dataratio.jl")
export dataratio, DataRatio, transform_datetime!
end
