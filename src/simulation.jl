include("race_times.jl")
include("strategies.jl")

using DataFrames


function simulate(;
    tires::Vector{Vector{Union{Int64, String}}},
    min_pit_stops::Int,
    max_pit_stops::Int,
    t_base::Union{Float64,Int},
    tot_no_laps::Union{Float64,Int},
    t_lap_sens_mass::Float64,
    t_pitdrive_inlap::Union{Float64,Int},
    t_pitdrive_outlap::Union{Float64,Int},
    t_pit_tirechange::Union{Float64,Int},
    pits_aft_finishline::Bool,
    cold_tire_pen::Union{Float64,Int},
    p_grid::Int,
    t_loss_pergridpos::Union{Float64,Int},
    t_loss_firstlap::Union{Float64,Int},
    m_fuel_init::Union{Float64,Int},
    b_fuel_perlap::Float64,
    tire_pars::Dict{String, Any}
)
    df = DataFrame(
        Race_Strategy = Vector[],
        Race_Time = Float64[]
    )
    strategies = generate_strategies(
        tires=tires,
        min_pit_stops=min_pit_stops,
        max_pit_stops=max_pit_stops
    )
    for i in 1:length(strategies)
        strategy = optimize_strategy(;
            tire_pars=tire_pars,
            tires=strategies[i],
            tot_no_laps=tot_no_laps
        )
        timer = calculate_race_times(;
            t_base=t_base, 
            tot_no_laps=tot_no_laps, 
            t_lap_sens_mass=t_lap_sens_mass, 
            t_pitdrive_inlap=t_pitdrive_inlap, 
            t_pitdrive_outlap=t_pitdrive_outlap, 
            t_pit_tirechange=t_pit_tirechange, 
            cold_tire_pen=cold_tire_pen,
            pits_aft_finishline= pits_aft_finishline, 
            p_grid=p_grid, 
            t_loss_firstlap=t_loss_firstlap, 
            t_loss_pergridpos=t_loss_pergridpos, 
            strategy=strategy, 
            m_fuel_init=m_fuel_init, 
            b_fuel_perlap=b_fuel_perlap,
            tire_pars=tire_pars
        )
        push!(df, [strategy, timer])
    end

    return sort!(df, :Race_Time)
end