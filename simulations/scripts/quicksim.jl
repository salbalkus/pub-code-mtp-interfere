using DrWatson
@quickactivate :networkMTPsim
using CausalTables, Condensity, ModifiedTreatment
using Graphs
using Plots
using MLJ
using DensityRatioEstimation
using Distributions

using Logging
disable_logging(Logging.Info)
disable_logging(Logging.Warn)

### IID ###
# Ground Truth Parameters
seed = 1
ntruth = 10^6
name = "quicksim.jl"

# Generate ground truth
include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
config = maketruth(@strdict name seed ntruth scm intervention)

LinearRegressor = @load LinearRegressor pkg=MLJLinearModels

mean_estimator = LinearRegressor()

density_ratio_estimator = DensityRatioPlugIn(OracleDensityEstimator(scm))
cv_splitter = nothing
mtp = MTP(mean_estimator, density_ratio_estimator, cv_splitter)

# Define simulation parameters
config["samples"] = (10:10:40).^2
config["nreps"] = 500
config["mtp"] = mtp
config["bootstrap"] = BasicSampler()
config["bootstrap_samples"] = 0
config["mtpname"] = "comparison4"

# Run the simulation
@time result = networkMTPsim.simulate(config; print_every = config["nreps"] ÷ 10)

# Visualize the results
makeplots(result, config; ci = [false, false, false], methodnames = ["tmle", "tmle_iid", "ols"], varsymb = :σ2net)
plotparams = Dict("mtpname" => config["mtpname"], "nreps" => config["nreps"], "name" => name, "samples" => config["samples"])
Plots.savefig(plotsdir(savename(plotparams, allowedtypes = (Real, String, Symbol, Vector))) * ".png")

### Non-IID ###
name = "synthetic-linear-er.jl"

# Generate ground truth
include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
config = maketruth(@strdict name seed ntruth scm intervention)

density_ratio_estimator = DensityRatioPlugIn(OracleDensityEstimator(scm))
cv_splitter = nothing
mtp = MTP(mean_estimator, density_ratio_estimator, cv_splitter)

# Define simulation parameters
config["samples"] = (10:10:40).^2
config["nreps"] = 500
config["mtp"] = mtp
config["bootstrap"] = BasicSampler()
config["bootstrap_samples"] = 0
config["mtpname"] = "comparison4"

# Run the simulation
@time result = networkMTPsim.simulate(config; print_every = config["nreps"] ÷ 10)

opchars(result, config; methodnames = ["tmle", "plugin_iid", "ols"], varsymb = :σ2net)
# Visualize the results
makeplots(result, config; ci = [true, false, false], methodnames = ["tmle", "plugin_iid", "ols"], varsymb = :σ2net)
plotparams = Dict("mtpname" => config["mtpname"], "nreps" => config["nreps"], "name" => name, "samples" => config["samples"])
Plots.savefig(plotsdir(savename(plotparams, allowedtypes = (Real, String, Symbol, Vector))) * ".png")

config = dict_list(config)[1]
config["data"] = simulate_data(config)["data"]
config["i"] = 1
using Random
Random.seed!(config["seed"])
foo = simulate_mtp_fit(config, true)
Random.seed!(config["seed"])
foo2 = simulate_mtp_fit(config, false)

config["data"]

iid = true
data = iid ? CausalTables.replace(config["data"]; summaries = (;)) : config["data"]
mtpmach = machine(config["mtp"], data, config["intervention"]) |> fit!
fitted_params(nuisance_machines(mtpmach).machine_mean)
report(mtpmach).LAs

r2 = report(mtpmach)
scatter(r.Qδn, r2.Qδn)
scatter(r.Hn, r2.Hn)

mtpmach = machine(config["mtp"], data, config["intervention"]) |> fit!


# Compute causal estimates
result = ModifiedTreatment.estimate(mtpmach, config["intervention"])
ModifiedTreatment.bootstrap!(config["bootstrap"], result, config["bootstrap_samples"])
est = getestimate(result)