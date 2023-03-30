struct IncorrectOrder <: Exception
    var::String
end

# # For those methods with `PrepareTable` (i.e., table already being prepared for training)

_check(PT::PrepareTable, PTC::PrepareTableConfig) = _check(PT, PTC, PT.status) # for those with PTC (e.g., preparetable!)

_check(PT::PrepareTable, PTC::PrepareTableConfig, PTstatus::Union{Nothing, TrainTestState}) = throw(IncorrectOrder("StatusError: Set up `PrepareTeable` with `$(typeof(PTC))` is not allowed in the current status `$(typeof(PTstatus))`. If you create a new struct <:PrepareTableConfig, you have to also define an additional check for making sure the order of preprocessing is correct."))

function _check(PT::PrepareTable, PTC::ConfigPreprocess, PTstatus::Nothing)
    @info "Currently there is no addtional check for `$(typeof(PTC))`."
end

function _check(PT::PrepareTable, PTC::ConfigAccumulate, PTstatus::Prepare)
    @info "Currently there is no addtional check for `$(typeof(PTC))`."
    # _check before preparetable!(PT, PTC::ConfigAccumulate)
    # (PTstatus should be `Prepare`d before calculating accumulation)
end

function _check(PT::PrepareTable, PTC::ConfigSeriesToSupervised, PTstatus::Prepare)
    @info "Currently there is no addtional check for `$(typeof(PTC))`."
    # TODO: _check before preparetable!(PT, PTC::ConfigSeriesToSupervised)
    # (PTstatus should be `Prepare`d before calculating table for supervised model training)
end





# # For those methods with `PrepareTable` and without `::PrepareTableConfig`.
_check(PT::PrepareTable) = _check(PT, PT.status) # for those in no need with PTC (e.g., train!, test!)
function _check(PT::PrepareTable, PTstatus::TrainTestState)
    if isnothing(PT.supervised_tables)
        throw(IncorrectOrder("Supervised table is not available, which is required for training and testing."))
    end
end

"""
`_check(PT::PrepareTable, ::Nothing)` check when the status is `nothing`.
"""
function _check(PT::PrepareTable, ::Nothing)
    throw(IncorrectOrder("`PT::PrepareTable` is not prepared at all."))
end
