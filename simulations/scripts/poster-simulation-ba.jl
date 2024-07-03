using DrWatson
@quickactivate :networkMTPsim
using CausalTables
using Graphs
using Condensity
using ModifiedTreatment
using MLJ
using Plots

using Logging
disable_logging(Logging.Info)
disable_logging(Logging.Warn)

# Ground Truth Parameters
seed = 2024
ntruth = 10^6
name = "poster_ba2.jl"

# Generate ground truth
include(scriptsdir("dgp", "$(name)"))

config = maketruth(@strdict name seed ntruth dgp intervention)

#df = rand(dgp, 1000)
#A = df.tbl.A .+ df.tbl.As
#Y = df.tbl.Y
#scatter(A, Y)

# Set up MTP estimator
#mean_estimator = LinearRegressor()
#density_ratio_estimator = DensityRatioPlugIn(OracleDensityEstimator(dgp), false)
#cv_splitter = nothing

LinearRegressor = @load LinearRegressor pkg=MLJLinearModels
KNNRegressor = @load KNNRegressor pkg=NearestNeighborModels
RandomForestRegressor = @load RandomForestRegressor pkg=DecisionTree

mean_estimator = SuperLearner([
    LinearRegressor(),
    KNNRegressor(),
    RandomForestRegressor(n_trees=100)
], CV(nfolds = 5))
density_ratio_estimator = DensityRatioKLIEP([1.0, 10.0, 100.0, 1000.0], [15])
cv_splitter = CV(nfolds = 5)
boot_sampler = BasicSampler()

mtp = MTP(mean_estimator, density_ratio_estimator, cv_splitter)

# Define simulation parameters
config["samples"] = [100, 400, 900, 1600, 2500]
config["nreps"] = 500
config["mtp"] = mtp
config["bootstrap"] = boot_sampler
config["bootstrap_samples"] = 0
config["mtpname"] = "CV-SuperLearner"

# Run the simulation
@time result = networkMTPsim.simulate(config; print_every = config["nreps"])
# ensure we don't get any negative variances
result[!, "value"] = abs.(result[!, "value"])

makeplots(result, config; ci = [false, false, false], methodnames = ["sipw", "plugin", "onestep", "tmle"], varsymb = :σ2net)
plotparams = Dict("mtpname" => config["mtpname"], "nreps" => config["nreps"], "name" => name, "samples" => config["samples"])
Plots.savefig(plotsdir(savename(plotparams, allowedtypes = (Real, String, Symbol, Vector))) * "_network.png")



