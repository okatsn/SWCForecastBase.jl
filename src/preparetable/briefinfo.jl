function _brief_info(otherwise)
    str = string(otherwise)
    lens = length(str)
    str[1:minimum([lens, 50])]
end
_brief_info(df::AbstractDataFrame) = "$(nrow(df)) by $(ncol(df)) `$(typeof(df))`"
function _brief_info(v::Vector)
    str = string(v)
    if length(str) > 40
        str = str[1:40]*"..."
    end
    "$(length(v)) elements of vector `$str`."
end

function _brief_info(v::Vector{<:TimeType})
    t0, t1 = extrema(v)
    "[$t0, ..., $t1]"
end
