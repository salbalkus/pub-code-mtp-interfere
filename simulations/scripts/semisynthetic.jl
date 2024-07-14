using DrWatson
@quickactivate :networkMTPsim
using DataFrames, CSV, SimpleWeightedGraphs
using Random, GLM

include(scriptsdir("auxiliary", "1-setup.jl"))

name = "semisynthetic.jl"
include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
ntruth = n
samples = [n]
k = 1000
config = @strdict name ntruth scm intervention k

function simulate_truths(config::Dict)
    seeds = [abs(rand(Int16)) for i in 1:config["k"]]
    ψs = Vector{Float64}(undef, config["k"])
    ψdifs = Vector{Float64}(undef, config["k"])
    for i in 1:config["k"]
        println("Running truth simulation $(i)")
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
config_name = "approx=$(k);centered"

include(scriptsdir("auxiliary", "2-run-simulation-linear.jl"))

tbl = opchars(result, config; varsymb = :σ2, methodnames = ["tmle", "tmle_iid", "ols"])

