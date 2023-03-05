using Combinatorics
using JuMP, Gurobi


function generate_strategies(;
    tires::Vector{Vector{Union{Int64, String}}},
    min_pit_stops::Int,
    max_pit_stops::Int
)
    tire_combinations = []
    for n_pit_stops in min_pit_stops:max_pit_stops
        candidates = unique(permutations(tires, n_pit_stops))
        for candidate in candidates
            compounds = [c[1] for c in candidate]
            if length(unique(compounds)) > 1
                # println(candidate)
                append!(tire_combinations, [candidate])
            end
        end
    end
    # length(tire_combinations)
    return tire_combinations
end


function optimize_strategy(;
    tire_pars::Dict{String, Any},
    tires::Vector{Vector{Union{Int64, String}}},
    tot_no_laps::Union{Float64,Int}
)
    k_1_lin_array = [tire_pars[x[1]]["k_1_lin"] for x in tires]
    k_0_array = [tire_pars[x[1]]["k_0"] for x in tires]
    age_array = [x[2] for x in tires]
    no_stints = length(tires)
    
    # set up problem matrices (P = H and q = f in quadprog)
    P = Diagonal(0.5 .* k_1_lin_array .* 2)  # * 2 because of standard form
    q = (0.5 .+ age_array) .* k_1_lin_array + k_0_array
    
    G = -Matrix{Float64}(I, no_stints, no_stints)
    h = fill(-1.0, no_stints)
    
    A = ones(1, no_stints)  # sum of stints must equal total number of laps
    b = [tot_no_laps]
    
    # create integer design variables
    model = Model(Gurobi.Optimizer)
    @variable(model, x[1:no_stints], Int)
    
    # set up problem using objective and constraints
    @objective(model, Min, 0.5 * dot(x, P * x) + dot(q, x))
    @constraint(model, G * x .<= h)
    @constraint(model, A * x .== b)
    
    @time begin
        status = optimize!(model)
    end
    println("Objective value: ", JuMP.objective_value(model))
    println("x = ", JuMP.value.(x))
    stints = JuMP.value.(x)
    stint_starts = Int.(cumsum(stints) .- stints)
    strategy = [
        (stint_start, tire[1], tire[2])
        for (stint_start, tire) in zip(stint_starts, tires)
    ]
    return strategy
end