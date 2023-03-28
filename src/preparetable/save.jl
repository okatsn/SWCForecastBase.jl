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
    println("Results saved as the followings: ")
    show(FileTree(dir0))
end

"""
Without specifying the parent folder `dir0`,
a folder of name of randomstring will be created as the parent folder.

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

function save(tts::TrainTestState, targetdir)
    # targetpaths = String[]
    for (k, v) in pairs(tts.args)
        tp = _save(targetdir, k, v)
        # ifelse(isnothing(tp), nothing, push!(targetpaths, tp))
    end
    # return targetpaths
end

_save(targetdir, k, v) = nothing # do nothing if v is not in the followings.


function _save(targetdir, k, v::AbstractDataFrame)
    CSV.write(joinpath(targetdir, "variable=$k.csv"), v)
end


function _save(targetdir, k, v::AbstractVector{<:Union{AbstractString, Real, DateTime}})
    CSV.write(joinpath(targetdir, "variable=$k.csv"), DataFrame(k => v))
end
