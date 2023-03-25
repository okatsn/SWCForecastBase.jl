@testset "pipeline.jl" begin
    function simplepipe4test(arg1, fns...)
        for f in fns
            arg1 = f(arg1)
        end
        return arg1
    end
    flist = [sin, cos, tan]
    for i = 1:10
        arg1 = 10*randn() + randn()
        @test isequal(simplepipe4test(arg1, flist...), SWCForecastBase.simplepipeline(arg1, flist...))
    end
end
