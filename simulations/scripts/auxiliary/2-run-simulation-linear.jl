include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
config = maketruth(@strdict name seed ntruth scm intervention)

LinearRegressor = @load LinearRegressor pkg=MLJLinearModels
LogisticClassifier = @load LogisticClassifier pkg=MLJLinearModels
DeterministicConstantRegressor = @load DeterministicConstantRegressor pkg=MLJModels
mean_estimator = LinearRegressor()
location_model = LinearRegressor()
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
#makeplots(result, config; ci = [false, false, false], methodnames = ["tmle", "tmle_iid", "ols"], varsymb = :σ2)
makeplots(result, config; ci = [false, false, false], methodnames = ["tmle"], varsymb = :σ2net)
plotparams = Dict("netname" => config["netname"], "nreps" => config["nreps"], "name" => name, "samples" => config["samples"])
Plots.savefig(plotsdir(savename(plotparams, allowedtypes = (Real, String, Symbol, Vector))) * ".png")