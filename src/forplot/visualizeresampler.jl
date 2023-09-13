# referring: https://docs.makie.org/stable/explanations/recipes/index.html#example_stock_chart

function formatnfold(y)
    sfx = ordinalsuffix(y)
    "$y$sfx fold"
end
function ordinalsuffix(y)
    y = Int(y)
    if y == 12 # exceptions
        remy10 = y
    else
        remy10 = rem(y, 10)
    end
    suffix = Dict(1 => "st", 2 => "nd", 3 => "rd", 12 => "th")
    sfx = get(suffix, remy10, "th")
    return sfx
end

struct TwoBar{T<:Real}
    left0::T
    left1::T
    right0::T
    right1::T
end


@recipe(ResamplerSpan) do scene # noted that this creates `resamplerspan` & `resamplerspan!`
    Attributes(
        leftcolor=:cyan2,
        rightcolor=:plum1,
    )
end

function Makie.plot!(
    sc::ResamplerSpan{<:Tuple{AbstractVector{<:Real},AbstractVector{<:TwoBar}}})

    # our first argument is an observable of parametric type AbstractVector{<:Real}
    times = sc[1]
    # our second argument is an observable of parametric type AbstractVector{<:TwoBar}}
    stockvalues = sc[2]

    # we predefine a couple of observables for the linesegments
    # and barplots we need to draw
    # this is necessary because in Makie we want every recipe to be interactively updateable
    # and therefore need to connect the observable machinery to do so
    linesegs = Observable(Point2f[])
    bar_froms = Observable(Float32[])
    bar_tos = Observable(Float32[])
    colors = Observable(Bool[])

    # this helper function will update our observables
    # whenever `times` or `stockvalues` change
    function update_plot(times, stockvalues)
        colors[]

        # clear the vectors inside the observables
        empty!(linesegs[])
        empty!(bar_froms[])
        empty!(bar_tos[])
        empty!(colors[])

        # then refill them with our updated values
        for (t, s) in zip(times, stockvalues)
            push!(linesegs[], Point2f(t, s.low))
            push!(linesegs[], Point2f(t, s.high))
            push!(bar_froms[], s.open)
            push!(bar_tos[], s.close)
        end
        append!(colors[], [x.close > x.open for x in stockvalues])
        colors[] = colors[]
    end

    # connect `update_plot` so that it is called whenever `times`
    # or `stockvalues` change
    Makie.Observables.onany(update_plot, times, stockvalues)

    # then call it once manually with the first `times` and `stockvalues`
    # contents so we prepopulate all observables with correct values
    update_plot(times[], stockvalues[])

    # for the colors we just use a vector of booleans or 0s and 1s, which are
    # colored according to a 2-element colormap
    # we build this colormap out of our `downcolor` and `upcolor`
    # we give the observable element type `Any` so it will not error when we change
    # a color from a symbol like :red to a different type like RGBf(1, 0, 1)
    colormap = Observable{Any}()
    map!(colormap, sc.downcolor, sc.upcolor) do dc, uc
        [dc, uc]
    end

    # in the last step we plot into our `sc` ResamplerSpan object, which means
    # that our new plot is just made out of two simpler recipes layered on
    # top of each other
    linesegments!(sc, linesegs, color=colors, colormap=colormap)
    barplot!(sc, times, bar_froms, fillto=bar_tos, color=colors, strokewidth=0, colormap=colormap)

    # lastly we return the new ResamplerSpan
    sc
end
