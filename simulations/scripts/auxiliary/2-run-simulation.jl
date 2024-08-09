include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
config = maketruth(@strdict name seed ntruth scm intervention)

DecisionTreeRegressor = @load DecisionTreeRegressor pkg=DecisionTree
XGBoostRegressor = @load XGBoostRegressor pkg=XGBoost

DecisionTreeClassifier = @load DecisionTreeClassifier pkg=DecisionTree
XGBoostClassifier = @load XGBoostClassifier pkg=XGBoost
RandomForestClassifier = @load RandomForestClassifier pkg=DecisionTree


#mean_estimator = SuperLearner([
#    LinearRegressor(),
#    KNNRegressor(),
#    DecisionTreeRegressor(),
#    XGBoostRegressor()
#], CV(nfolds = 4))

mean_estimator = XGBoostRegressor(objective = "reg:squarederror", 
                                      num_round = 100, eta = 0.1, max_depth = 6, min_child_weight = 1.0, subsample = 1.0, lambda = 0.1)


#mean_estimator = XGBoostRegressor(objective = "reg:squarederror", )
#mean_estimator = DecisionTreeRegressor()

#mean_estimator = LGBMRegressor(linear_tree = true, force_col_wise=true, objective = "regression", metric = ["rmse"],
#                                num_iterations = 100, learning_rate = 0.1, num_leaves = 127, min_data_per_group = 10)


#density_ratio_estimator = DensityRatioKMM(; σ = 100.0, λ = 0.001)

#sl = SuperLearner([LogisticClassifier(), 
#                   XGBoostClassifier(objective = "binary:logistic"),
#                       ], CV(nfolds = 5))
#density_ratio_estimator = DensityRatioClassifier(sl)
#density_ratio_estimator = DensityRatioClassifier(LogisticClassifier())
density_ratio_estimator = DensityRatioClassifier(XGBoostClassifier(booster = "gbtree", objective = "binary:logistic",
    num_round = 500, eta = 0.01, max_depth = 3, min_child_weight = 1.0, subsample = 0.5, lambda = 1))
#density_ratio_estimator = DensityRatioClassifier(LGBMClassifier(linear_tree = true, force_col_wise=true, objective = "binary", metric = ["binary_logloss"],
#                                                 num_iterations = 100, learning_rate = 0.001, num_leaves = 1000, min_data_per_group = 5))
#density_ratio_estimator = DensityRatioPlugIn(OracleDensityEstimator(scm))

#cv_splitter = CV(nfolds = 5)
cv_splitter = nothing
mtp = MTP(mean_estimator, density_ratio_estimator, cv_splitter)

# Define simulation parameters
config["samples"] = samples
config["nreps"] = nreps
config["mtp"] = mtp
config["bootstrap"] = bootstrap
config["bootstrap_samples"] = bootstrap_samples
config["netname"] = netname

dat = rand(scm, 1000)
mach = machine(MTP(mean_estimator, density_ratio_estimator, cv_splitter), dat, intervention) |> fit!
#mach2 = machine(MTP(mean_estimator, DensityRatioPlugIn(OracleDensityEstimator(scm)), nothing), dat, intervention) |> fit!
ModifiedTreatment.estimate(mach, intervention)
#maximum(abs.(report(mach).Hn .- report(mach2).Hn))
#mean(abs.(report(mach).Hn .- report(mach2).Hn))
#report(mach).Hn
#report(mach2).Hn

#mean(abs.(conmean(scm, dat, :Y) .- report(mach).Qn))
#report(mach).Qn .- conmean(scm, dat, :Y)

# Run the simulation
@time result = networkMTPsim.simulate(config; print_every = config["nreps"] ÷ 10)
result[result.estimate .== "σ2net", "value"] .= abs.(result[result.estimate .== "σ2net", "value"]);

# Visualize the results
makeplots(result, config; ci = [false, false, false], methodnames = ["onestep", "onestep_iid", "ols"], varsymb = :σ2net)

plotparams = Dict("netname" => config["netname"], "nreps" => config["nreps"], "name" => name, "samples" => config["samples"])
Plots.savefig(plotsdir(savename(plotparams, allowedtypes = (Real, String, Symbol, Vector))) * ".png")