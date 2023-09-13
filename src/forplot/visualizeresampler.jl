# referring: https://docs.makie.org/stable/explanations/recipes/index.html#example_stock_chart

struct ResamplerSpan{T<:Real}
    left0::T
    left1::T
    right0::T
    right1::T
end


@recipe(ResamplerSpan) do scene
    Attributes(
        leftcolor=:cyan2,
        rightcolor=:plum1,
    )
end
