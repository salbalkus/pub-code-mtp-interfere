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
    for i in 1:config["k"]
        println("Running truth simulation $(i)")
        Random.seed!(seeds[i])
        ct = rand(config["scm"], config["ntruth"])
        ψs[i] = compute_true_MTP(config["scm"], ct, config["intervention"]).ψ
    end

    return ψs
end

ψs = simulate_truths(config)
println("Standard error of true ψ: $(sqrt(var(ψs) / n) )")

config["ψ"] = mean(ψs)
config["eff_bound"] = std(NaN)
config_name = "approx=$(k)"

include(scriptsdir("auxiliary", "2-run-simulation-linear.jl"))

# Manipulate the results
tmp = opchars(result, config; methodnames = ["tmle", "tmle_iid", "ols"], varsymb = :σ2net)




