## Test movingaverage
@testset "movingaverage" begin

    ## moving average that cannot handle NaN
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

    """
    `mvmean(arr, n)` retruns an array of element `length(arr) - n` of moving averaged results.

    This is the function that performs best on https://stackoverflow.com/questions/59562325/moving-average-in-julia.
    """
    function mvmean(arr::Vector{<:AbstractFloat}, n)
        return rolling_mean(arr, n)
    end


    moving_average(vs,n) = [sum(@view vs[i:(i+n-1)])/n for i in 1:(length(vs)-(n-1))]


    q0 = collect(2.0:6.0)
    a0 = [2.5,3.5,4.5,5.5]
    @test isequal(mvmean(q0, 2), a0)
    @test isequal(movingaverage(q0, 2)[2:end], a0)


    y = randn(10);
    n = 3;
    @test isapprox(mvmean(y, n), movingaverage(y,n)[n:end])
    @test isapprox(mvmean(y, n), moving_average(y,n))

    @test isequal(movingaverage([1.0, 2.0, 3.0, NaN, 5.0],2),
                                [NaN, 1.5, 2.5, 3.0, 5.0])
    @test isequal(movingaverage([1.0, 2.0, 3.0, NaN, NaN, 5.0],2),
                                [NaN, 1.5, 2.5, 3.0, NaN, 5.0])


end
