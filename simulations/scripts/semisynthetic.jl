using DrWatson
@quickactivate :networkMTPsim
using DataFrames, CSV, SimpleWeightedGraphs
using Random, GLM

include(scriptsdir("auxiliary", "1-setup.jl"))

name = "semisynthetic-trunc.jl"
include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
ntruth = n
samples = [n]
config = @strdict name ntruth scm intervention

# Compute the truth assuming an additive intervention
add_shift = intervention.δb(1)
ψ = mean((0.5 .* (reg .+ 4) .+ 0.01 .* reg2 .+ add_shift) .* (1.0 .+ vec(sum(neighbors, dims=2))) .+ 0.2 .* reg + 0.01 .* reg2)
#reps = 10000
#σ2 = mean([var(conmean(scm, rand(scm, 1), :Y)) for i in 1:reps]) / n


config["ψ"] = ψ
#config["ψ_dif"] = mean(ψdifs)
config["eff_bound"] = NaN#σ2
netname = "finite43"#"reps=$(reps)"

# Correctly-specified linear model
include(scriptsdir("auxiliary", "2-run-simulation-linear.jl"))

tbl = opchars(result, config; varsymb = :σ2net, methodnames = ["tmle", "tmle_iid", "ols"])
tbl2 = DataFrames.select(tbl, [:method, :bias, :pct_bias, :variance, :coverage, :ci_width])

# Super Learning
netname = "approx=$(k);super"
include(scriptsdir("auxiliary", "2-run-simulation.jl"))
config
tbl_super = opchars(result, config; varsymb = :σ2net, methodnames = ["tmle", "tmle_iid", "ols"])
tbl2_super = DataFrames.select(tbl_super, [:method, :bias, :pct_bias, :variance, :coverage])

tbl2_super[!, "method"] = tbl2_super[!, "method"] .* "_super"
tbl_final = vcat(tbl2, tbl2_super[1:2, :])

output_path = joinpath(projectdir(), "..", "data", "semisynthetic-summary.csv")
CSV.write(output_path, tbl_final)



