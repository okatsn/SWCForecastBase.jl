abstract type TrainTestState end

mutable struct Train <: TrainTestState
    args::NamedTuple
end

Train() = Train(NamedTuple())

mutable struct Test <: TrainTestState
    args::NamedTuple
end
Test() = Test(NamedTuple())

mutable struct Prepare <: TrainTestState
    args::NamedTuple
end
Prepare() = Prepare(NamedTuple())
