include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
config = maketruth(@strdict name seed ntruth scm intervention)

LinearRegressor = @load LinearRegressor pkg=MLJLinearModels
KNNRegressor = @load KNNRegressor pkg=NearestNeighborModels
DecisionTreeRegressor = @load DecisionTreeRegressor pkg=DecisionTree
XGBoostRegressor = @load XGBoostRegressor pkg=XGBoost

mean_estimator = SuperLearner([
    LinearRegressor(),
    KNNRegressor(),
    DecisionTreeRegressor(),
    XGBoostRegressor()
], CV(nfolds = 4))

density_ratio_estimator = DensityRatioPlugIn(OracleDensityEstimator(scm))
#density_ratio_estimator = DensityRatioKLIEP([1.0, 10.0, 100.0, 1000.0, 10000.0], [12])

cv_splitter = nothing#CV(nfolds = 5)
mtp = MTP(mean_estimator, density_ratio_estimator, cv_splitter)

# Define simulation parameters
config["samples"] = samples
config["nreps"] = nreps
config["mtp"] = mtp
config["bootstrap"] = bootstrap
config["bootstrap_samples"] = bootstrap_samples
config["netname"] = netname

# Run the simulation
@time result = networkMTPsim.simulate(config; print_every = config["nreps"] ÷ 10)
result[result.estimate .== "σ2net", "value"] .= abs.(result[result.estimate .== "σ2net", "value"]);

# Visualize the results
makeplots(result, config; ci = [false, false, false], methodnames = ["tmle", "tmle_iid", "ols"], varsymb = :σ2net)
plotparams = Dict("netname" => config["netname"], "nreps" => config["nreps"], "name" => name, "samples" => config["samples"])
Plots.savefig(plotsdir(savename(plotparams, allowedtypes = (Real, String, Symbol, Vector))) * ".png")