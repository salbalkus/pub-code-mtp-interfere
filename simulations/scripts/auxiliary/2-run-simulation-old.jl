include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
config = maketruth(@strdict name seed ntruth scm intervention)

LinearRegressor = @load LinearRegressor pkg=MLJLinearModels
LogisticClassifier = @load LogisticClassifier pkg=MLJLinearModels
XGBoostRegressor = @load XGBoostRegressor pkg=XGBoost
XGBoostClassifier = @load XGBoostClassifier pkg=XGBoost


mean_estimator = SuperLearner([
    LinearRegressor(),
    XGBoostRegressor(objective = "reg:squarederror", num_round = 1, 
                    colsample_bynode = 0.8, eta = 1, max_depth = 6, num_parallel_tree = 100, subsample = 0.8, tree_method = "hist"),
    XGBoostRegressor(objective = "reg:squarederror", 
                    eta = 0.3, max_depth = 6),
    XGBoostRegressor(objective = "reg:squarederror", 
                    eta = 0.1, max_depth = 6),
    XGBoostRegressor(objective = "reg:squarederror", 
                    num_round = 300, eta = 0.01, max_depth = 3),
    XGBoostRegressor(objective = "reg:squarederror", tree_method = "exact",
                    num_round = 50, eta = 0.3, max_depth = 20, min_child_weight = 20),
], CV(nfolds = 4))

sl = SuperLearner([
    LogisticClassifier(),
    XGBoostClassifier(objective = "binary:logistic", num_round = 1, 
                      colsample_bytree = 0.2, min_child_weight = 40,
                      eta = 1, max_depth = 30, num_parallel_tree = 100, subsample = 1.0, 
                      tree_method = "exact"),
    XGBoostClassifier(objective = "binary:logistic", num_round = 40, 
                      eta = 0.1, lambda = 0.01, alpha = 1.0, max_depth = 20,
                      min_child_weight = 30, subsample = 1.0, 
                      colsample_bytree = 0.2, tree_method = "exact"),
    XGBoostClassifier(objective = "binary:logistic", num_round = 40, 
                      eta = 0.4, lambda = 0.001, alpha = 1.0, max_depth = 40,
                      min_child_weight = 40, subsample = 1.0, 
                      colsample_bytree = 0.2, tree_method = "exact"),
    XGBoostClassifier(objective = "binary:logistic", num_round = 40, 
                      eta = 0.3, lambda = 0.001, alpha = 0.001, max_depth = 40,
                      min_child_weight = 20, subsample = 1.0, 
                      colsample_bytree = 0.2, tree_method = "exact",
                      max_delta_step = 0.6),
    XGBoostClassifier(objective = "binary:logistic", num_round = 40, 
                      eta = 0.3, lambda = 0.001, alpha = 0.001, max_depth = 40,
                      min_child_weight = 40, subsample = 1.0, 
                      colsample_bytree = 0.2, tree_method = "exact",
                      max_delta_step = 0.6),
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
