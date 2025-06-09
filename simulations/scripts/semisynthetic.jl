using DrWatson
@quickactivate :networkMTPsim
using DataFrames, CSV, SimpleWeightedGraphs
using Random, GLM

include(scriptsdir("auxiliary", "1-setup.jl"))

name = "semisynthetic-trunc.jl"
include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
ntruth = n
samples = [n]
k = 5000
config = @strdict name ntruth scm intervention k

# Approximate the truth mean using the DGP
function simulate_truths(config::Dict)
    seeds = [abs(rand(Int16)) for i in 1:config["k"]]
    ψs = Vector{Float64}(undef, config["k"])
    ψdifs = Vector{Float64}(undef, config["k"])
    for i in 1:config["k"]
        #println("Running truth simulation $(i)")
        Random.seed!(seeds[i])
        ct = rand(config["scm"], config["ntruth"])
        truth = compute_true_MTP(config["scm"], ct, config["intervention"])
        ψs[i] = truth.ψ
        ψdifs[i] = truth.ψ_dif
    end
    return ψs, ψdifs
end

ψs, ψdifs = simulate_truths(config)

config["ψ"] = mean(ψs)
#config["ψ_dif"] = mean(ψdifs)
config["eff_bound"] = NaN
netname = "approx=$(k)"

# Correctly-specified linear model
include(scriptsdir("auxiliary", "2-run-simulation-linear.jl"))

tbl = opchars(result, config; varsymb = :σ2, methodnames = ["tmle", "tmle_iid", "ols"])
tbl2 = DataFrames.select(tbl, [:method, :bias, :pct_bias, :variance, :coverage])

# Super Learning
netname = "approx=$(k);super"
include(scriptsdir("auxiliary", "2-run-simulation.jl"))
config
tbl_super = opchars(result, config; varsymb = :σ2, methodnames = ["tmle", "tmle_iid", "ols"])
tbl2_super = DataFrames.select(tbl_super, [:method, :bias, :pct_bias, :variance, :coverage])

tbl2_super[!, "method"] = tbl2_super[!, "method"] .* "_super"
tbl_final = vcat(tbl2, tbl2_super[1:2, :])

output_path = joinpath(projectdir(), "..", "data", "semisynthetic-summary.csv")
CSV.write(output_path, tbl_final)



