include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
config = maketruth(@strdict name seed ntruth scm intervention)

XGBoostRegressor = @load XGBoostRegressor pkg=XGBoost
XGBoostClassifier = @load XGBoostClassifier pkg=XGBoost


mean_estimator = SuperLearner([
    XGBoostRegressor(objective = "reg:squarederror", booster="gblinear"),
    XGBoostRegressor(objective = "reg:squarederror", num_round = 1, 
                    colsample_bynode = 0.8, eta = 1, max_depth = 6, num_parallel_tree = 100, subsample = 0.8, tree_method = "hist"),
    XGBoostRegressor(objective = "reg:squarederror", 
                    eta = 0.1, max_depth = 6, subsample = 1.0),
], CV(nfolds = 4))

sl = SuperLearner([
    XGBoostClassifier(objective = "binary:logistic", booster="gblinear"),
    XGBoostClassifier(objective = "binary:logistic", num_round = 1, 
                      colsample_bynode = 0.8, eta = 1, max_depth = 6, num_parallel_tree = 100, subsample = 0.8, tree_method = "hist"),
    XGBoostClassifier(objective = "binary:logistic",
                      num_round = 500, eta = 0.01, max_depth = 3, subsample = 0.5),
], CV(nfolds = 4))

density_ratio_estimator = DensityRatioClassifier(sl)
#density_ratio_estimator = DensityRatioPlugIn(OracleDensityEstimator(scm))

cv_splitter = CV(nfolds = 4)
#cv_splitter = nothing
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