# Changelog

## v0.1.0
- Initiating the project.

## v0.2.0
Add utilities
- `series2supervised` for time-shifting of input features
- `addcol_accumulation!` for calculating accumulated precipitation

New features
- `movingaverage`

## v0.3.0
Add basic tree models

## v0.3.1
Fix dependencies and update compat

## v0.3.2
`DataRatio` for `Makie`'s recipe for `dataratio` calculation per `DataInterval` and plot as `heatmap!`

## v0.4.0
`PrepareTable` and associated data-preparing API, with `preparetable!` with `ConfigPreprocess`, `ConfigAccumulate` and `ConfigSeriesToSupervised`. With:
- `table::DataFrame`
- `configs::Vector{<:PrepareTableConfig}`
- `status::Union{TrainTestState, Nothing}`
- `supervised_tables::Union{SeriesToSupervised, Nothing}`

Preprocess utilities
- `precipmax!`
- `take_hour_last`

Change in behavior
- `imputemean!` does not by default do `disallowmissing!`

Workflow overview:
- `PrepareTable`
- `traintest!`
- `save`

## v0.4.10
- Better `show` for `SeriesToSupervised`
- Fix `take_last_hour`

## v0.4.12
- Fix `precipmax!` and add some tests for it.

## v0.4.13
- Remove unreasonable `wind_speed` and `pressure`; Fix typo.