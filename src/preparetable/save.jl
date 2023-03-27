function save(PT::PrepareTable)
    tag = randstring(6)
    dir0 = "Tables_$tag"

    for nm in fieldnames(Cache)
        targetdir = mkpath(joinpath(dir0, string(nm)))
        tts = getfield(PT.cache, nm)
        # if !isempty(tts.args)
        save(tts, targetdir)
        # end
    end
end

save(tts) = nothing # do nothing otherwise
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
