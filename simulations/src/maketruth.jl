
function simulate_truth(config::Dict)
    Random.seed!(config["seed"])
    scm = config["scm"]
    intervention = config["intervention"]

    # Compute ground truth
    # need to recompile via Base.invokelatest due to dgp being loaded later
    dat = Base.invokelatest(rand, scm, config["ntruth"]) 
    println("Computing $(intervention)")
    ψ, eff_bound = Base.invokelatest(compute_true_MTP, scm, dat, intervention)

    # Save the ground truth as a Julia object into data/truth
    truth = Dict(
        "ψ" => ψ,
        "eff_bound" => eff_bound,
        "name" => config["name"],
        "seed" => config["seed"],
        "ntruth" => config["ntruth"]
    )

    return truth
end

"""
    maketruth(config::Dict)

Create or load simulated truth data based on the given configuration.

# Arguments
- `config::Dict`: A dictionary containing the configuration parameters. Must contain "name", "seed", "n", "dgp", and "intervention". Note that "name" refers to the name of the DGP, which is used to for storing simulated data.

# Returns
- The simulated true causal effect and the efficiency bound, as well as the DGP, intervention, and other parameters used to generate them.

"""
function maketruth(config::Dict; tag = true)
    #params = Dict("name" => config["name"], "seed" => config["seed"], "ntruth" => config["ntruth"], "checksum" => script_checksum(config["name"]))
    #output, _ = produce_or_load(simulate_truth, config; filename = datadir("truth", savename(params)), tag = tag, suffix = "bson")
    output = simulate_truth(config)
    output["scm"] = config["scm"]
    output["intervention"] = config["intervention"]
    return output
end

