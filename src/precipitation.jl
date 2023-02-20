"""
`movingaverage(v, n)` returns a vector of moving averaged `v` by every `n`.
"""
function movingaverage(v::Vector{<:AbstractFloat}, n::Int)
    lenv = length(v)
    @assert isequal(eachindex(v), 1:lenv) "`eachindex(v)` is not equal to `1:length(v)`."
    [NaNMath.mean(v[id0:id1]) for (id0, id1) in zip(n:lenv, 1:(lenv-n+1))]
end


"""
Add columns that are derived by accumulating corresponding variables using `movingaverage`.

# Example
```julia
all_precipstr = names(df, r"precipitation")

apd = Dict( # time intervals to accumulates precipitation
    "1hour" => 6,
    "12hour" => 6*12,
    "1day" => 6*24,
    "2day" => 6*24*2,
    "3day" => 6*24*3
)

addcol_accumulation!(df, all_precipstr, apd)

```

See also: `movingaverage`.
"""
function addcol_accumulation!(df, all_precipstr, apd)
    if !isempty(apd)
        for pstr in all_precipstr
            for (k, v) in apd
                DataFrames.transform!(df, pstr => (x -> movingaverage(x, v).*v) => Symbol("$(pstr)_$k"))
            end
        end

        deleteat!(df, 1:(maximum(values(apd))-1))
    else
        @warn "apd is empty."
    end
    return df
end

# CHECKPOINT: write a function cumulate! that given a dataframe, returns accumulative columns as that in addcol_accumulation!, but make the first few necessarly rows `missing` instead of `deleteat!` them.

"""
Of a time series `ts`, `cccount(ts)` calculate by default the cumulative counts of elements that approximates zero consecutively.
"""
function cccount(ts)
    # It is OK to execute this piece of code directly in REPL, but an error will occurred if `include`d.
    # In julia to prevent "spooky action at a distance", `noraincounts` will always redefined as new local if the piece of code execute by `include`.
    # see https://docs.julialang.org/en/v1/manual/variables-and-scoping/#On-Soft-Scope
        nts = deepcopy(ts)
        noraincounts = 0
        for (i, ti) in enumerate(ts)
            if isapprox(ti, 0.0)
                noraincounts += 1
            else
                noraincounts = 0
            end
            nts[i] = noraincounts
        end
        return nts
end
