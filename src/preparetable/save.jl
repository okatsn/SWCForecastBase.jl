"""
`save(PT::PrepareTable, dir0)` save `cache` in `PT` to the directory `dir0`.

# Example
```julia
dir0 = "MyResults"
save(PT::PrepareTable, dir0)
```
"""
function save(PT::PrepareTable, dir0)
    for nm in fieldnames(Cache)
        targetdir = mkpath(joinpath(dir0, string(nm)))
        tts = getfield(PT.cache, nm)
        # if !isempty(tts.args)
        save(tts, targetdir)
        # end
    end
end

"""
Without specifying the parent folder `dir0`,
a folder with randomstring will be generated.

# Example
```julia
save(PT::PrepareTable) # save results to /Tables_Fsd0w4/... for example
```
"""
function save(PT::PrepareTable)
    tag = randstring(6)
    dir0 = "Tables_$tag"
    save(PT, dir0)
end

_save(targetdir, k, v) = nothing

function save(tts::TrainTestState, targetdir)
    for (k, v) in pairs(tts.args)
        _save(targetdir, k, v)
    end
end


function _save(targetdir, k, v::AbstractDataFrame)
    CSV.write(joinpath(targetdir, "variable=$k.csv"), v)
end


function _save(targetdir, k, v::AbstractVector{<:Union{AbstractString, Real, DateTime}})
    CSV.write(joinpath(targetdir, "variable=$k.csv"), DataFrame(k => v))
end
