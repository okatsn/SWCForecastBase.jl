"""
`mvmean(arr, n)` retruns an array of element `length(arr) - n` of moving averaged results.

This is the function that performs best on https://stackoverflow.com/questions/59562325/moving-average-in-julia.
"""
function mvmean(arr, n)
    return rolling_mean(arr, n)
end

"""
`mvnanmean(arr, n)` use `mvmean` but ignoring `NaN`.
The output array has the same dimensions as the input one, with the first `n - 1` element be `NaN`.

# WARNING
You may have to do imputation first before calculating moving average because
ALL `NaN` are considered to be 0 when calculating moving average; that is, the average will be zero when all elements in the moving window are all `NaN`.

"""
function mvnanmean(arr, n)
    arr[isnan.(arr)] .= 0
    lena = length(arr)
    out = fill(NaN, lena)
    out[1:n-1] .= NaN
    out[n:end] = mvmean(arr, n)
    return out
end

function slowmvnanmean(y, winsz)
    leny = length(y)
    ind0s = 1:(leny-winsz+1)
    ind1s = winsz:leny

    nansum(x) = sum(filter(!isnan, x))
    y1 = copy(y)
    y1[1:winsz-1] .= NaN
    invwinsz = 1/winsz
    for (ind0, ind1) in zip(ind0s, ind1s)
        yi = @view y[ind0:ind1]
        if all(isnan.(yi))
            y1[ind1] = NaN
        else
            y1[ind1] = nansum(yi)*invwinsz
        end
    end
    return y1
end


function slowmvnanmean2(y, winsz)
    leny = length(y)
    nansum(x) = sum(filter(!isnan, x))
    y1 = fill(NaN, size(y))

    invwinsz = 1/winsz
    for i in winsz:leny
        yi = @view y[(i-winsz+1):i]
        if !all(isnan.(yi))
            y1[i] = nansum(yi)*invwinsz
        end
    end
    return y1
end

function slowmvnanmean3(y, winsz) # no difference in performance comparing with slowmvnanmean2
    leny = length(y)
    invwinsz = 1/winsz

    nansum(x) = sum(filter(!isnan, x))
    function assigny1!(y1, i)
        yi = @view y[(i-winsz+1):i]
        if !all(isnan.(yi))
            y1[i] = nansum(yi)*invwinsz
        end
    end
    y1 = fill(NaN, size(y))


    for i in winsz:leny
        assigny1!(y1, i)
    end
    return y1
end

# todo: move these functions to a certain module

"""
my moving average function of poor performance
"""
function mymovwinmean(y::Vector{Float64}, winsz)
    leny = length(y)
    ind0s = 1:leny-winsz+1
    ind1s = winsz:leny

    y1 = copy(y)
    y1[1:winsz-1] .= NaN

    for (ind0, ind1) in zip(ind0s, ind1s)
        y1[ind1] = sum(y[ind0:ind1])/winsz
    end
    return y1
end

moving_average(vs,n) = [sum(@view vs[i:(i+n-1)])/n for i in 1:(length(vs)-(n-1))]

function moving_average2(vs, n)
    out = Array{Float64}(undef,size(vs))# fill(NaN, size(vs))
    for i in 1:(length(vs)-(n-1))
        out[i+n-1] = sum(@view vs[i:(i+n-1)])/n
    end
end

function rolling_sum(arr, n)
    so_far = sum(arr[1:n])
    out = zero(arr[n:end])
    out[1] = so_far
    for (i, (start, stop)) in enumerate(zip(arr, arr[n+1:end]))
        so_far += stop - start
        out[i+1] = so_far
    end
    return out
end

rolling_mean(arr, n) = rolling_sum(arr, n) ./ n

function rolling_mean2(arr, n)
    return imfilter(arr, OffsetArray(fill(1/n, n), -n), Inner())
end

function rolling_mean3(arr, n)
    so_far = sum(arr[1:n])
    out = zero(arr[n:end])
    out[1] = so_far
    for (i, (start, stop)) in enumerate(zip(arr, arr[n+1:end]))
        so_far += stop - start
        out[i+1] = so_far / n
    end
    return out
end

function rolling_mean3nan(arr, n)
    so_far = sum(arr[1:n])
    out = zero(arr[n:end])
    out[1] = so_far
    for (i, (start, stop)) in enumerate(zip(arr, arr[n+1:end]))
        so_far += stop - start
        out[i+1] = so_far / n
    end
    return vcat(fill(NaN,n-1), out)
end


function rolling_mean4(arr, n)
    rs = cumsum(arr)[n:end] .- cumsum([0.0; arr])[1:end-n]
    return rs ./ n
end

# y = randn(100000);
# n = 325;

# @benchmark movavgtest(y, n) # which has the least required memory
# @benchmark rolling_mean(y, n) # good+
# @benchmark rolling_mean2(y, n) # not good (almost 10 times slower than best)
# @benchmark rolling_mean3(y, n) # fastest and low memory
# @benchmark rolling_mean4(y, n) # good-
# @benchmark mymovwinmean(y,n) # miserable (200x slower and 100x memory usage)

# @benchmark mvnanmean(arr, n)
# @benchmark slowmvnanmean(arr, n)

# @benchmark rolling_mean3nan(y, n)
