using DrWatson
@quickactivate :networkMTPsim

include(scriptsdir("auxiliary", "1-setup.jl"))

getgraph(n) = erdos_renyi(n, 4/n)
name = "synthetic-3-stepwise-trunc.jl"
netname = "er-super-fast"

###

include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
config = maketruth(@strdict name seed ntruth scm intervention)

LinearRegressor = @load LinearRegressor pkg=MLJLinearModels
LogisticClassifier = @load LogisticClassifier pkg=MLJLinearModels
XGBoostRegressor = @load XGBoostRegressor pkg=XGBoost
XGBoostClassifier = @load XGBoostClassifier pkg=XGBoost
FillImputer = @load FillImputer pkg=MLJModels
ElasticNetRegressor = @load ElasticNetRegressor pkg=MLJLinearModels
DeterministicConstantRegressor = @load DeterministicConstantRegressor pkg=MLJModels

mean_estimator = FillImputer(continuous_fill = x -> NaN) |>
    SuperLearner([
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

sl = FillImputer(continuous_fill = x -> NaN) |> SuperLearner([
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

location_model = CrossFitModel(FillImputer(continuous_fill = x -> NaN) |> 
                    SuperLearner([
                        XGBoostRegressor(objective = "reg:squarederror", tree_method = "exact",
                            num_round = 40, eta = 0.3, max_depth = 20, min_child_weight = 40,
                            lambda = 0.001, alpha = 0.001),
                        XGBoostRegressor(objective = "reg:squarederror", tree_method = "exact",
                            num_round = 40, eta = 0.3, max_depth = 6, min_child_weight = 20,
                            lambda = 0.001, alpha = 0.001),
                        XGBoostRegressor(objective = "reg:squarederror", tree_method = "exact",
                            num_round = 40, eta = 0.3, max_depth = 3, min_child_weight = 10,
                            lambda = 0.001, alpha = 0.001)
                    ], CV(nfolds = 4)), CV(nfolds = 5))

#scale_model = XGBoostRegressor(objective = "reg:squarederror", tree_method = "exact",
#                    num_round = 40, eta = 0.3, max_depth = 20, min_child_weight = 10,
#                    lambda = 1, alpha = 1)
#scale_model = FeatureSelector(features=[:F, ], ignore=false) |> 
#                SuperLearner([DeterministicConstantRegressor(),
#                                LinearRegressor(),
#                                ElasticNetRegressor(lambda = 5.0, gamma = 5.0),
#                                ElasticNetRegressor(lambda = 1.0, gamma = 1.0),
#                                ], CV(nfolds = 5))
scale_model = DeterministicConstantRegressor()
density_model = KDE(0.001, Epanechnikov)
r = range(density_model, :bandwidth, lower=0.01, upper=0.3)
lse_model = LocationScaleDensity(location_model, scale_model, density_model, r, CV(nfolds=5))
scale_model_iid = LinearRegressor()
lse_model_iid = LocationScaleDensity(location_model, scale_model_iid, density_model, r, CV(nfolds=5))
model = lse_model

LAs, L, A, treatment_name, summary_name = ModifiedTreatment.get_summarized_data(dat)
LAδinterventions, Aderivatives = ModifiedTreatment.get_intervened_data(LAs, L, AdditiveShift(-0.2), treatment_name, summary_name)

# Fit the location model
X = L
y = A.data.A
    location_mach = machine(model.location_model, X, y) |> fit!
    μ = predict(location_mach, X)

    scatter(μ, conmean(scm, dat, :A), label = "Location Model Predictions")
    scatter(μ, y, label = "Location Model Predictions")

    # Fit the scale model
    ε = @. y - μ
    scatter(ε, y .- conmean(scm, dat, :A), label = "Residuals")
    ε2 = @. ε^2
    scale_mach = machine(model.scale_model, X, ε2) |> fit!

    # Fit the density model
    σ2 = predict(scale_mach, X)
    scatter(convar(scm, dat, :As), σ2, label = "Scale Model Predictions")

    σ2[σ2 .<= 0.001] .= 0.001


    ε = @. ε / sqrt(σ2)
    #ε = (y .- conmean(scm, dat, :As)) ./ sqrt.(convar(scm, dat, :As))
    ε[isnan.(ε)] .= 0.0


    import MLJTuning as MT
    tuned_density_model = MT.TunedModel(
        # TODO: Pick better default bandwidth?
        model = model.density_model,
        # TODO: Choose better MT.TuningStrategy
        tuning = MT.Grid(resolution = 100),
        resampling = model.resampling,
        measure = negmeanloglik,
        operation = predict,
        range = model.r_density
        )
    
    density_mach = machine(tuned_density_model, (ε = ε,), zeros(length(ε))) |> fit!

# Get residual model predictions
    μ = predict(location_mach, X)
    σ2 = predict(scale_mach, X)
    σ2[σ2 .<= 0.001] .= 0.001
    rootσ2 = @. sqrt(σ2)
    # Return density of standardized residual 
    #ε = (y .- conmean(scm, dat, :As)) ./ sqrt.(convar(scm, dat, :As))
    #ε[isnan.(ε)] .= 0.0
    ε = (y .- μ) ./ rootσ2
    dens = predict(density_mach, (ε = ε,)) ./ rootσ2

    true_dens = propensity(scm, summarize(dat), :A)
    ε_true = (A.data.A .- conmean(scm, dat, :A)) ./ sqrt.(convar(scm, dat, :A))
    ord = sortperm(ε_true)
    ε_true[ord]
    scatter(ε_true[ord], true_dens[ord])
    ord2 = sortperm(ε)
    scatter!(ε[ord2], dens[ord2])

G = dat.arrays.G
μs = G * μ
σ2s = G * σ2

rootσ2s = sqrt.(σ2s)
εs = (summarize(dat).data.As .- μs) ./ rootσ2s
εs_true = (summarize(dat).data.As .- conmean(scm, dat, :As)) ./ sqrt.(convar(scm, dat, :As))
scatter(εs, εs_true, label = "Standardized Errors")

tuned_density_model = MT.TunedModel(
        # TODO: Pick better default bandwidth?
        model = model.density_model,
        # TODO: Choose better MT.TuningStrategy
        tuning = MT.Grid(resolution = 100),
        resampling = model.resampling,
        measure = negmeanloglik,
        operation = predict,
        range = model.r_density
        )
    
εs[isnan.(εs)] .= 0.0
density_mach = machine(tuned_density_model, (εs = εs,), zeros(length(ε))) |> fit!
dens = predict(density_mach, (εs = εs,)) ./ rootσ2s

true_dens = propensity(scm, summarize(dat), :As)
ord = sortperm(εs_true)
scatter(εs_true[ord], true_dens[ord])
ord2 = sortperm(εs)
scatter!(εs[ord2], dens[ord2])

scatter(dens, true_dens)

density_ratio_estimator = DensityRatioPlugIn(lse_model)
density_ratio_estimator_iid = DensityRatioPlugIn(lse_model_iid)

dre = DecomposedPropensityRatio(density_ratio_estimator)
mach = machine(dre, L, A) |> fit!

#mach = machine(density_ratio_estimator, LAδinterventions, LAs) |> fit!

a = predict(mach, LAδinterventions, LAs)
b = propensity(scm, LAδinterventions, :A) ./ propensity(scm, LAs, :A) 
cor(b, a)
scatter(b, a, label = "Density Ratio Estimator")
histogram(a .- b)

# WORKS FINE WHEN WE DON'T USE CROSS-FITTING
#cv_splitter = CV(nfolds = 5)
# THE IDEA INSTEAD IS TO USE CROSS-FITTING ONLY ON COMPONENTS WE KNOW NOT TO BE DONSKER
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

c = dict_list(config)[3]
ct = simulate_data(c)
i = 1
params = Dict("data" => ct["data"], "mtp" => config["mtp"], "mtp_iid" => config["mtp_iid"], "intervention" => config["intervention"], "samples" => c["samples"], "i" => 1,
                                "bootstrap" => config["bootstrap"], "bootstrap_samples" => config["bootstrap_samples"])
summary_vars = keys(params["data"].summaries)
no_summaries = Tuple(setdiff(keys(params["data"].causes), keys(params["data"].summaries)))
using NamedTupleTools
new_causes = NamedTupleTools.select(params["data"].causes, no_summaries)
new_causes = NamedTuple{no_summaries}(map(x -> setdiff(x, summary_vars), new_causes))
new_treatment = intersect(params["data"].treatment, no_summaries)
iid = false
dat = iid ? CausalTables.replace(params["data"]; treatment = new_treatment, summaries = (;), arrays = (;), causes = new_causes) : params["data"]

mtpmach = machine(config["mtp"], dat, config["intervention"]) |> fit!
foo = report(mtpmach)

scatter(foo.Qn, conmean(scm, ct["data"], :Y))

Hntrue = propensity(scm, intervene(ct["data"], additive_mtp(-0.2)), :A) ./ propensity(scm, ct["data"], :A)
scatter(foo.Hn[foo.Hn .< 10], Hntrue[foo.Hn .< 10])
ipw(mtpmach, config["intervention"])

r = simulate_mtp_fit(params, false)
r2 = simulate_mtp_fit(params, true)
r_ols = simulate_ols_fit(params, true)

###

include(scriptsdir("auxiliary", "2-run-simulation.jl"))

makeplots(result, config; ci = [false, false, false],  methodnames = ["tmle", "tmle_iid", "ols"], varsymb = :σ2net)
savetable(result, config; varsymb = :σ2net)
savetruth(config)