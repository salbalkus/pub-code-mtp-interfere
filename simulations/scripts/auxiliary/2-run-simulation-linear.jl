include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
config = maketruth(@strdict name seed ntruth scm intervention)

LinearRegressor = @load LinearRegressor pkg=MLJLinearModels
LogisticClassifier = @load LogisticClassifier pkg=MLJLinearModels
mean_estimator = LinearRegressor()

#density_ratio_estimator = DensityRatioPlugIn(OracleDensityEstimator(scm), true)
#density_ratio_estimator = DensityRatioKLIEP([100.0, 1000.0], [50])
#LogisticClassifier = @load LogisticClassifier pkg=MLJLinearModels
density_ratio_estimator = DensityRatioClassifier(LogisticClassifier())
#density_ratio_estimator = DensityRatioKernel(LSIF(σ = 1000.0))
#density_ratio_estimator = DensityRatioKMM(; σ = 50.0, λ = 0.001)


cv_splitter = nothing#CV(nfolds = 4)
boot_sampler = BasicSampler()

mtp = MTP(mean_estimator, density_ratio_estimator, cv_splitter)

# Define simulation parameters
config["samples"] = samples
config["nreps"] = nreps
config["mtp"] = mtp
config["bootstrap"] = bootstrap
config["bootstrap_samples"] = bootstrap_samples
config["netname"] = config_name

# Run the simulation
@time result = networkMTPsim.simulate(config; print_every = config["nreps"] ÷ 10)
result[result.estimate .== "σ2net", "value"] .= abs.(result[result.estimate .== "σ2net", "value"]);

# Visualize the results
makeplots(result, config; ci = [false, false, false], methodnames = ["tmle", "tmle_iid", "ols"], varsymb = :σ2)
plotparams = Dict("netname" => config["netname"], "nreps" => config["nreps"], "name" => name, "samples" => config["samples"])
Plots.savefig(plotsdir(savename(plotparams, allowedtypes = (Real, String, Symbol, Vector))) * ".png")