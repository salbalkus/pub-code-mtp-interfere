include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
config = maketruth(@strdict name seed ntruth scm intervention)

LinearRegressor = @load LinearRegressor pkg=MLJLinearModels
LogisticClassifier = @load LogisticClassifier pkg=MLJLinearModels
XGBoostRegressor = @load XGBoostRegressor pkg=XGBoost
XGBoostClassifier = @load XGBoostClassifier pkg=XGBoost
FillImputer = @load FillImputer pkg=MLJModels
ElasticNetRegressor = @load ElasticNetRegressor pkg=MLJLinearModels
DeterministicConstantRegressor = @load DeterministicConstantRegressor pkg=MLJModels

mean_estimator = CrossFitModel(FillImputer(continuous_fill = x -> NaN) |>
    SuperLearner([
    XGBoostRegressor(objective = "reg:squarederror", num_round = 1, 
                    colsample_bynode = 0.8, eta = 1, max_depth = 6, num_parallel_tree = 100, subsample = 0.8, tree_method = "hist"),
    XGBoostRegressor(objective = "reg:squarederror", 
                    eta = 0.3, max_depth = 6),
    XGBoostRegressor(objective = "reg:squarederror", 
                    eta = 0.1, max_depth = 8, tree_method = "exact"),
    XGBoostRegressor(objective = "reg:squarederror", 
                    num_round = 300, eta = 0.01, max_depth = 3),
    XGBoostRegressor(objective = "reg:squarederror", tree_method = "exact",
                    num_round = 50, eta = 0.3, max_depth = 20, min_child_weight = 20),
], CV(nfolds = 5)), CV(nfolds = 5))

location_model = CrossFitModel(FeatureSelector(features=[:L1, :L2, :L3, :L4], ignore=false) |>
                    SuperLearner([
                        XGBoostRegressor(objective = "reg:squarederror", num_round = 1, 
                            colsample_bynode = 0.8, eta = 1, max_depth = 6, num_parallel_tree = 100, subsample = 0.8, tree_method = "hist"),
                        XGBoostRegressor(objective = "reg:squarederror", tree_method = "exact",
                            num_round = 40, eta = 0.3, max_depth = 20, min_child_weight = 40,
                            lambda = 0.001, alpha = 0.001),
                        XGBoostRegressor(objective = "reg:squarederror", tree_method = "exact",
                            num_round = 40, eta = 0.3, max_depth = 6, min_child_weight = 20,
                            lambda = 0.001, alpha = 0.001),
                        XGBoostRegressor(objective = "reg:squarederror", tree_method = "exact",
                            num_round = 40, eta = 0.3, max_depth = 3, min_child_weight = 10,
                            lambda = 0.001, alpha = 0.001)
                    ], CV(nfolds = 5)), CV(nfolds = 5))

scale_model = DeterministicConstantRegressor()
density_model = KDE(0.001, Normal)
r = range(density_model, :bandwidth, lower=0.001, upper=0.5)
density_ratio_estimator = SumRatioHSE(location_model, scale_model, density_model, r, CV(nfolds=5))
lse_model_iid = LocationScaleDensity(location_model, scale_model, density_model, r, CV(nfolds=5))
density_ratio_estimator_iid = DensityRatioPlugIn(lse_model_iid)

cv_splitter = nothing
mtp = MTP(mean_estimator, density_ratio_estimator, cv_splitter)
mtp_iid = MTP(mean_estimator, density_ratio_estimator_iid, cv_splitter)

# Define simulation parameters
config["samples"] = samples
config["nreps"] = nreps
config["mtp"] = mtp
config["mtp_iid"] = mtp_iid
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
