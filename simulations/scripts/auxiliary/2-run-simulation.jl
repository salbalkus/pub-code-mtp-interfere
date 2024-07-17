include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
config = maketruth(@strdict name seed ntruth scm intervention)

LinearRegressor = @load LinearRegressor pkg=MLJLinearModels
KNNRegressor = @load KNNRegressor pkg=NearestNeighborModels
DecisionTreeRegressor = @load DecisionTreeRegressor pkg=DecisionTree
XGBoostRegressor = @load XGBoostRegressor pkg=XGBoost

#mean_estimator = SuperLearner([
#    LinearRegressor(),
#    KNNRegressor(),
#    DecisionTreeRegressor(),
#    XGBoostRegressor()
#], CV(nfolds = 4))
mean_estimator = XGBoostRegressor()

#density_ratio_estimator = DensityRatioPlugIn(OracleDensityEstimator(scm))
#density_ratio_estimator = DensityRatioKMM(; σ = 100.0, λ = 0.001)
LogisticClassifier = @load LogisticClassifier pkg=MLJLinearModels
density_ratio_estimator = DensityRatioClassifier(LogisticClassifier())

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