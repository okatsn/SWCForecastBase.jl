@testset "mvwinmean" begin
    ## Test deprecated functions
    # See also: https://discourse.julialang.org/t/nanmean-options/4994/12

    """
    `mvmean(arr, n)` retruns an array of element `length(arr) - n` of moving averaged results.

    This is the function that performs best on https://stackoverflow.com/questions/59562325/moving-average-in-julia.
    """
    function mvmean(arr::Vector{<:AbstractFloat}, n)
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

    function slowmvnanmean(y::Vector{<:AbstractFloat}, winsz)
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
    function mymovwinmean(y::Vector{<:AbstractFloat}, winsz)
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
        return out
    end # TODO: untested or problematic

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
    end # TODO: untested or problematic


    function rolling_mean4(arr, n)
        rs = cumsum(arr)[n:end] .- cumsum([0.0; arr])[1:end-n]
        return rs ./ n
    end

    q0 = collect(2.0:6.0)
    a0 = [2.5,3.5,4.5,5.5]

    @test isequal(moving_average(q0, 2), a0)
    @test isequal(rolling_mean4(q0, 2), a0)
    @test isequal(mvmean(q0, 2), a0)
    y = randn(10);
    n = 3;
    @test isapprox(mvmean(y, n), moving_average(y,n))
    @test isequal(mvnanmean([1.0, 2.0, 3.0, NaN, 5.0],2), [NaN, 1.5,2.5,1.5,2.5])
    @test isequal(mvnanmean([1.0, 2.0, 3.0, NaN,NaN, 5.0],2), [NaN, 1.5,2.5,1.5,0.0,2.5]) # WARN: all NaN in the moving window results zero, NOT NaN.
    @test isequal(slowmvnanmean([1.0, 2.0, 3.0, NaN,NaN, 5.0],2), [NaN, 1.5,2.5,1.5,NaN,2.5])




    ## Test movingaverage
    @testset "movingaverage" begin
        @test isequal(movingaverage(q0, 2), a0)
        y = randn(10);
        n = 3;
        @test isapprox(mvmean(y, n), movingaverage(y,n))
        @test isequal(movingaverage([1.0, 2.0, 3.0, NaN, 5.0],2), [1.5,2.5,1.5,2.5])
        @test isequal(movingaverage([1.0, 2.0, 3.0, NaN,NaN, 5.0],2), [1.5,2.5,1.5,NaN,2.5])
        @test isequal(slowmvnanmean([1.0, 2.0, 3.0, NaN,NaN, 5.0],2),
                            movingaverage([1.0, 2.0, 3.0, NaN,NaN, 5.0],2))

    end
end
