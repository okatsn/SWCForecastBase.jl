struct SlidingTrainTestWindow
    ref::TimeType
    step::TimePeriod
    window_train::TimePeriod # duration of train/test window (max)
    window_test::TimePeriod  # duration of train/test window (max)
    n_window::Int # number of sliding window
end

function SlidingTrainTestWindow(ref, step, window_train)
    # CHECKPOINT: SlidingTrainTestWindow04200910
    window_test = step
end


function SlidingTrainTestWindow(ref0, ref1; step = stp, length = len)
# CHECKPOINT: SlidingTrainTestWindow04200910
end



Base.length(STTW::SlidingTrainTestWindow) = STTW.n_window

function Base.iterate(STTW::SlidingTrainTestWindow, state)
    if state > length(STTW)
        next = nothing
    else
        state += 1
        val = (
            train_from  = ,
            train_until = ,
            test_from   = ,
            test_until  = ,
        )# CHECKPOINT: SlidingTrainTestWindow04200910
        next = (val, state)
    end

    return next

end

Base.iterate(STTW::SlidingTrainTestWindow) = Base.iterate(DI, 1) # required
