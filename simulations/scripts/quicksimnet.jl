using DrWatson
@quickactivate :networkMTPsim

include(scriptsdir("auxiliary", "1-setup.jl"))

name = "quicksimnet.jl"
netname = "er"

###

Os = rand(scm, 2500)

δ = intervention
Y = ModifiedTreatment._get_response_vector(Os)
GA = CausalTables.adjacency_matrix(Os)
GD = CausalTables.dependency_matrix(Os)

model_intervention = InterventionModel()
LAs, Ls, As, LAδs, dAδs, LAδsinv, dAδsinv = intervene_on_data(model_intervention, Os, δ)
    
mach_intervention = machine(model_intervention, Os) |> fit!

tmp1 = MLJ.predict(mach_intervention, δ)
tmp2 = MLJ.transform(mach_intervention, δ)
tmp3 = MLJ.inverse_transform(mach_intervention, δ)

LAs, Ls, As = tmp1[1], tmp1[2], tmp1[3]
LAδs, dAδs = tmp2[1], tmp2[2]
LAδsinv, dAδsinv = tmp3[1], tmp3[2]
# Fit and estimate nuisance parameters
mach_mean, mach_density = ModifiedTreatment.crossfit_nuisance_estimators(mtp, Y, LAs, LAδsinv, Ls, As)
Qn, Qδn, Hn, Hshiftn = estimate_nuisances(mach_mean, mach_density, LAs, LAδs, LAδsinv, dAδs, dAδsinv)

# If the density ratio estimator is adaptive, we need to ensure multiple estimators are fit for each factorized component
    # (Otherwise, this is handled automatically by fixed density ratio estimators)
    ratio_model_type = typeof(mtp.density_ratio_estimator)
    if ratio_model_type <: Condensity.ConDensityRatioEstimatorAdaptive
        dprmodel = DecomposedPropensityRatio(mtp.density_ratio_estimator)
    else
        dprmodel = mtp.density_ratio_estimator
    end

    # Decide whether to cross-fit the models
    if isnothing(mtp.cv_splitter)
        mean_model = mtp.mean_estimator
        dr_model = dprmodel
    else
        mean_model = CrossFitModel(mtp.mean_estimator, mtp.cv_splitter)
        dr_model = CrossFitModel(dprmodel, mtp.cv_splitter)
    end

    # Construct machines bound to appropriate data
    mach_mean = machine(mtp.mean_estimator, LAs, Y) |> fit!
    if (ratio_model_type <: Condensity.ConDensityRatioEstimatorAdaptive) || (ratio_model_type <: SumRatioHSE)
        mach_density = machine(dr_model, Ls, As) |> fit!
    else # if ratio_model_type <: Condensity.ConDensityRatioEstimatorFixed
        mach_density = machine(dr_model, LAδsinv, LAs) |> fit!
    end

    # Get Conditional Mean
    Qn = MLJ.predict(mach_mean, LAs)
    Qδn = MLJ.predict(mach_mean, LAδs)
    
    scatter(conmean(scm, Os, :Y), Qn)


    # Get Density Ratio
    Hn = MLJ.predict(mach_density, LAδsinv, LAs) * prod(dAδsinv)

    # TODO: Check if we actually don't need to multiply by a derivative here
    Hshiftn = MLJ.predict(mach_density, LAs, LAδs)

    true_Hn = propensity(scm, LAδsinv, :A) ./ propensity(scm, LAs, :A)
    true_Hshiftn = propensity(scm, LAs, :A) ./ propensity(scm, LAδs, :A)

    scatter(true_Hn, Hn)
    scatter(true_Hshiftn, Hshiftn)

Os

fitted_params(mach_mean)

    Y[Hn .> 10, :]

    # Get causal estimates
    plugin_est, ipw_est, sipw_est, onestep_est, tmle_est = estimate_causal_parameters(Y, GA, GD, Qn, Qδn, Hn, Hshiftn)

include(scriptsdir("auxiliary", "2-run-simulation-linear.jl"))

makeplots(result, config; ci = [true, false, false], methodnames = ["tmle"], varsymb = :σ2net)

