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
config
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
config["mtpname"] = "linear"

# Run the simulation
@time result = networkMTPsim.simulate(config; print_every = config["nreps"] ÷ 10)
result

# Visualize the results
makeplots(result, config; ci = [true, false, false], methodnames = ["plugin", "onestep", "tmle"], varsymb = :σ2)
plotparams = Dict("mtpname" => config["mtpname"], "nreps" => config["nreps"], "name" => name, "samples" => config["samples"])
Plots.savefig(plotsdir(savename(plotparams, allowedtypes = (Real, String, Symbol, Vector))) * ".png")

### Non-IID ###
name = "quicksimnet.jl"

# Generate ground truth
include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
config = maketruth(@strdict name seed ntruth scm intervention)
config

density_ratio_estimator = DensityRatioPlugIn(OracleDensityEstimator(scm))
cv_splitter = nothing
mtp = MTP(mean_estimator, density_ratio_estimator, cv_splitter)

# Define simulation parameters
config["samples"] = (10:10:40).^2
config["nreps"] = 500
config["mtp"] = mtp
config["bootstrap"] = BasicSampler()
config["bootstrap_samples"] = 0
config["mtpname"] = "linear"

# Run the simulation
@time result = networkMTPsim.simulate(config; print_every = config["nreps"] ÷ 10)

# Visualize the results
makeplots(result, config; ci = [true, false, false], methodnames = ["plugin", "onestep", "tmle"], varsymb = :σ2net)
plotparams = Dict("mtpname" => config["mtpname"], "nreps" => config["nreps"], "name" => name, "samples" => config["samples"])
Plots.savefig(plotsdir(savename(plotparams, allowedtypes = (Real, String, Symbol, Vector))) * ".png")





