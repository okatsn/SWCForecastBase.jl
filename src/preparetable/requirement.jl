# struct Requirement
#     checkfn
# end

_check(PT::PrepareTable) = _check(PT, PT.status) # for those in no need with PTC (e.g., train!, test!)
_check(PT::PrepareTable, PTC::PrepareTableConfig) = _check(PT, PTC, PT.status) # for those with PTC (e.g., preparetable!)

_check(PT::PrepareTable, PTC::PrepareTableConfig, PTstatus::Union{Nothing, TrainTestState}) = @error "StatusError: Set `PrepareTeable` with $(typeof(PTC)) is not allowed in the current status `$(PTstatus)`"

function _check(PT::PrepareTable, PTC::ConfigPreprocess, PTstatus::Nothing)
# TODO: _check before preparetable!(PT, PTC::ConfigPreprocess)
end

function _check(PT::PrepareTable, PTC::ConfigAccumulate, PTstatus::Prepare)
    # TODO: _check before preparetable!(PT, PTC::ConfigAccumulate)
    # (PTstatus should be `Prepare`d before calculating accumulation)
end

function _check(PT::PrepareTable, PTC::ConfigSeriesToSupervised, PTstatus::Prepare)
    # TODO: _check before preparetable!(PT, PTC::ConfigSeriesToSupervised)
    # (PTstatus should be `Prepare`d before calculating table for supervised model training)
end


function _check(PT::PrepareTable, PTstatus::Prepare)
    # TODO: _check before train!(PT)
end

function _check(PT::PrepareTable, PTstatus::Train)
    # TODO: _check before test!(PT)
end

"""
`_check(PT::PrepareTable, ::Nothing)` check when the status is `nothing`.
"""
function _check(PT::PrepareTable, ::Nothing)

end




"""
`_check(PT::PrepareTable, PR::Prepare)` check after the status is `Prepare`d.
"""
function _check(PT::PrepareTable, PR::Prepare)

end
