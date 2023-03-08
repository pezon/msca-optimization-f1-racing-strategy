include("tire_degregation.jl")


function calculate_race_times(;
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
    strategy::Vector{Tuple{Int,Int,String,Int}},
    m_fuel_init::Union{Float64,Int},
    b_fuel_perlap::Float64,
    tire_pars::Dict{String, Any}
)
    length(strategy) == 0 && error("Start compound information must be provided")
    length(strategy) == 1 && error("There is no pitstop given in the strategy data. Cars must pit at least once")
    0 in [length(x) == 4 for x in strategy] && error("Inserted strategy data does not contain [inlap, outlap, compound, age] for all pit stops!")

    #make sure strategy pit stops are in sequential order
    pit_order = [x[1] for x in strategy]
    for x in length(pit_order) - 1
        if pit_order[x] >= pit_order[x+1]
            error("The given inlaps are not sorted in a rising order!")
        end
    end

    # ------------------------------------------------------------------------------------------------------------------
    # CONSIDER BASE LAP TIME, FUEL MASS LOSS AND RACE START ------------------------------------------------------------
    # ------------------------------------------------------------------------------------------------------------------

    # set base lap time
    t_laps = vec(ones(1, tot_no_laps) .* t_base)

    # add fuel mass time loss for every lap (considered with fuel mass at start of respective lap)
    t_laps += (m_fuel_init .- b_fuel_perlap .* [0:1:tot_no_laps-1;]) .* t_lap_sens_mass

    #add race start losses
    t_laps[1] += t_loss_firstlap + (p_grid - 1) * t_loss_pergridpos

    # ------------------------------------------------------------------------------------------------------------------
    # CONSIDER TIRE DEGRADATION ----------------------------------------------------------------------------------------
    # ------------------------------------------------------------------------------------------------------------------

    # loop through all the pit stops
    for idx in 1:length(strategy)
        cur_inlap = strategy[idx][1]
        cur_outlap = strategy[idx][2]

        # get current stint length
        len_cur_stint = strategy[idx][2] - strategy[idx][1]

        # get compound until current pitstop
        comp_cur_stint = strategy[idx][3]

        # get tire age at the beginning of this stint
        age_cur_stint = strategy[idx][4]

        # add tire losses (degradation considered on basis of the tire age at the start of a lap)
        t_laps[cur_inlap+1:cur_outlap] += calculate_tire_degradation(;
            tire_age_start=age_cur_stint,
            stint_length=len_cur_stint,
            compound=comp_cur_stint,
            tire_pars=tire_pars
        )

        # consider cold tires in the first lap of a stint (if inlap is not the last lap of the race)
        if cur_inlap < tot_no_laps
            t_laps[cur_inlap+1] += cold_tire_pen
        end
    end

    # ------------------------------------------------------------------------------------------------------------------
    # CONSIDER PIT STOPS -----------------------------------------------------------------------------------------------
    # ------------------------------------------------------------------------------------------------------------------

    # create array which is not affected by FCY phases afterwards
    t_laps_pit = vec(zeros(1,tot_no_laps))


    # loop through all the pit stops -----------------------------------------------------------------------------------
    for idx in 1:length(strategy)
        cur_inlap = strategy[idx][1]

        # continue if this is the start stint of the strategy list (i.e. no real pit stop)
        if cur_inlap == 0
            continue
        end

        # pit losses (inlap) -------------------------------------------------------------------------------------------
        t_pit_inlap = 0.0

        # consider standstill time
        if !pits_aft_finishline
            t_pit_inlap += t_pit_tirechange
        end
        # pit driving (inlap)
        t_pit_inlap += t_pitdrive_inlap

        # add pit stop loss to t_laps_pit
        t_laps_pit[cur_inlap] += t_pit_inlap

        # pit losses (outlap) ------------------------------------------------------------------------------------------
        # continue if inlap was the last lap of the race and therefore outlap is not driven anymore
        if cur_inlap >= tot_no_laps
            continue
        end

        t_pit_outlap = 0.0

        # consider standstill time
        if pits_aft_finishline
            t_pit_outlap += t_pit_tirechange
        end

        # pit driving (outlap)

        t_pit_outlap += t_pitdrive_outlap

        # add pit stop loss to t_laps_pit
        t_laps_pit[cur_inlap+1] += t_pit_outlap
    end

    # ------------------------------------------------------------------------------------------------------------------
    # CALCULATE LAPWISE RACE TIMES -------------------------------------------------------------------------------------
    # ------------------------------------------------------------------------------------------------------------------

    t_race_lapwise = cumsum(t_laps + t_laps_pit)

    #return t_race_lapwise
    return t_race_lapwise[end]
end