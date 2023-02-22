
fmttsuffix(t) = Regex("t$t\\Z")

"""
Given a vector `tpast` of integers, `iseithertpast(featname, tpast)` returns `true` if the string matches either `["t\$t" for t in tpast]` (e.g., `["t-1", "t-5", ....]`).

# Example
```julia
using MLJ, SWCForecastBase
fs = MLJ.FeatureSelector(features = str -> iseithertpast(str, tpast))
```
"""
iseithertpast(featname, tpast::Vector{<:Integer}) = any(occursin.(fmttsuffix.(tpast), string(featname)))

"""
` tpast::OrdinalRange` is OK.
"""
iseithertpast(featname, tpast::OrdinalRange) = iseithertpast(featname, collect(tpast))
