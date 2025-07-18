

"""
    simulate(config::Dict; tag = false, print_every = 50)

This function performs a simulation based on the given configuration dictionary.

"""
function simulate(config::Dict; tag = false, print_every = 50)

    println("Threads: $(Threads.nthreads())")

    # 1. Set up parameters over which to simulate
    configs = dict_list(config)

    # 2. Error Handling
    # Make sure the only parameters with more than one configuration are `samples`
    if length(configs) > length(config["samples"])
        error("Cannot simulate multiple parameters over the same number of samples. Please test different MTPs across multiple scripts.")
    end

    # 3. Set up output file
    # Get (and if necessary, create) the output file
    outputname = "name=$(config["name"])_netname=$(config["netname"]).csv"
    path = datadir("estimates", outputname)
    if !isfile(path)
        CSV.write(path, DataFrame(estimate = [], value = [], method = [], samples = [], i = []))
    end
    
    # 4. Set up tracking variables to determine which simulations have already been run
    cur_output = CSV.read(path, DataFrame; types = Dict("value" => Union{Float64, Missing}), missingstring=["NA"])
    if nrow(cur_output) > 0
        i_vec = unique(cur_output[!, :i])
        samples_vec = unique(cur_output[!, :samples])
    else
        i_vec = []
        samples_vec = []
    end
    
    # 5. Run the simulation
    # Set up fixed-size output to avoid data-race condition
    output = Vector{DataFrame}(undef, length(configs) * config["nreps"])
    for (k, c) in enumerate(configs)
        println("experiment $(k) of $(length(configs))")

        @Threads.threads for i in 1:c["nreps"]
            # either simulate the data, or load saved data
            fn = config["name"] * "-" * config["netname"]
            #ct, _ = produce_or_load(simulate_data, c; filename = datadir("draws", "$(fn)", "i=$(i)_samples=$(c["samples"])"), tag = tag)
            ct = simulate_data(c)
            # skip fitting MTP on data for which it has already been fit and store dummy
            if i in i_vec && c["samples"] in samples_vec
                i % print_every == 1 && println("Skipping $(i) of $(c["nreps"]) in thread $(Threads.threadid())")
                output[i + (k-1)*config["nreps"]] = DataFrame()
            # simulate and store the MTP fit
            else
                i % print_every == 0 && println("Computing $(i) of $(c["nreps"]) in thread $(Threads.threadid())")
                params = Dict("data" => ct["data"], "mtp" => config["mtp"], "mtp_iid" => config["mtp_iid"], "intervention" => config["intervention"], "samples" => c["samples"], "i" => i,
                                "bootstrap" => config["bootstrap"], "bootstrap_samples" => config["bootstrap_samples"])
                try 
                    net_mtp = simulate_mtp_fit(params)
                    iid_mtp = simulate_mtp_fit(params, true)
                    ols = simulate_ols_fit(params)
                    output[i + (k-1)*config["nreps"]] = vcat(net_mtp, iid_mtp, ols)
                catch e
                    println("Error in simulation $(i) of $(c["nreps"]) in thread $(Threads.threadid())")
                    println(e)
                    println("Trying again...")
                    net_mtp = simulate_mtp_fit(params)
                    iid_mtp = simulate_mtp_fit(params, true)
                    ols = simulate_ols_fit(params)
                    
                    output[i + (k-1)*config["nreps"]] = vcat(net_mtp, iid_mtp, ols)
                end
            end
        end
    end

    # 6. Merge previously generated data with new data
    if length(output) > 0
        output_appended = vcat(output...)
        # Write new output to the file
        CSV.write(path, output_appended; append = true, transform = (col, val) -> something(val, missing))
        return vcat(cur_output, output_appended)
    else
        return cur_output
    end
end

"""
    simulate_data(config::Dict)

Simulates data by drawing from the data-generating process in `config`.
"""
function simulate_data(config::Dict)
    data = rand(config["scm"], config["samples"])
    return Dict("data" => data)
end

"""
    simulate_mtp_fit(config::Dict)

Fits an MTP to the data in `config` and computes causal estimates.
"""
function simulate_mtp_fit(config, iid = false)
    # Fit MTP
    summary_vars = keys(config["data"].summaries)
    no_summaries = Tuple(setdiff(keys(config["data"].causes), keys(config["data"].summaries)))
    new_causes = NamedTupleTools.select(config["data"].causes, no_summaries)
    new_causes = NamedTuple{no_summaries}(map(x -> setdiff(x, summary_vars), new_causes))
    new_treatment = intersect(config["data"].treatment, no_summaries)
    
    dat = iid ? CausalTables.replace(config["data"]; treatment = new_treatment, summaries = (;), arrays = (;), causes = new_causes) : config["data"]
   
    if iid 
        mtpmach = machine(config["mtp_iid"], dat, config["intervention"]) |> fit!
    else
        mtpmach = machine(config["mtp"], dat, config["intervention"]) |> fit!
    end
    
    # Compute causal estimates
    result = ModifiedTreatment.estimate(mtpmach, config["intervention"])
    ModifiedTreatment.bootstrap!(config["bootstrap"], result, config["bootstrap_samples"])
    est = getestimate(result)
    df = convert_to_df(config["samples"], config["i"], est, iid ? "_iid" : "")

    # subtract off the "natural" mean value
    #μ0 = mean(Tables.getcolumn(data, data.response[1]))
    #df[!, "value"] = @. ifelse(df.estimate == "ψ", df.value - μ0, df.value)

    return df
end

function simulate_ols_fit(config, iid = true)
    # Only consider the effect of the first treatment
    summary_vars = keys(config["data"].summaries)
    no_summaries = Tuple(setdiff(keys(config["data"].causes), keys(config["data"].summaries)))
    new_causes = NamedTupleTools.select(config["data"].causes, no_summaries)
    new_causes = NamedTuple{no_summaries}(map(x -> setdiff(x, summary_vars), new_causes))
    new_treatment = intersect(config["data"].treatment, no_summaries)
    
    dat = iid ? CausalTables.replace(config["data"]; treatment = new_treatment, summaries = (;), arrays = (;), causes = new_causes) : config["data"]
    dat = CausalTables.responseparents(dat)
    iid_treatment = intersect(dat.treatment, setdiff(keys(dat.causes), keys(dat.summaries)))[1]

    # Find the treatment index, and add 1 to account for intercept in OLS model
    treatment_index = findlast(x -> x == iid_treatment, Tables.columnnames(dat))

    X = Tables.matrix(CausalTables.responseparents(config["data"]))
    y = vec(Tables.matrix(CausalTables.response(config["data"])))

    ols = lm(X, y)
    ψ = coef(ols)[treatment_index] * config["intervention"].δb(nothing) + mean(y)
    σ2 = var(y)/size(X, 1) + (stderror(ols)[treatment_index] * config["intervention"].δb(nothing))^2

    DataFrame(
            estimate = ["ψ", "σ2", "σ2net"],
            value = [ψ, σ2, σ2],
            method = ["ols", "ols", "ols"],
            samples = fill(config["samples"], 3),
            i = fill(config["i"], 3)
        )

end


"""
    convert_to_df(sample::Int, i::Int, ests)

Converts an MTPResult outcome into a dataframe, to be concatenated in `makesimulation`.

"""
function convert_to_df(sample::Int, i::Int, ests, appendage = "")
    output_vec = Vector{DataFrame}(undef, length(ests))
    j = 1

    # Iterate through the estimates
    for (key, value) in pairs(ests)
        nt = NamedTupleTools.ntfromstruct(value)

        # Organize each estimate into to dataframe
        output_vec[j] = DataFrame(
            estimate = String.(collect(keys(nt))),
            value = collect(values(nt)),
            method = string.(fill(key, length(nt)), appendage)
        )
        j+=1
    end 

    # Concatenate the dataframes and label with sample/index
    output = vcat(output_vec...)
    output[!, :samples] .= sample
    output[!, :i] .= i

    return output
end












