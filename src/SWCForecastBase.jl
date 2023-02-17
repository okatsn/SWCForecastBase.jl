module SWCForecastBase

# Write your package code here.
using Impute, Dates, Statistics, DataFrames
include("myimputation/myimpute.jl")
export imputemean!, imputeinterp!, removeunreasonables!


include("myimputation/checkmissnan.jl")
export chknnm, isnnm, islnan
end
