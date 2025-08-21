using DrWatson
@quickactivate :networkMTPsim

using CausalTables, Condensity, ModifiedTreatment
using Graphs
using Plots
using MLJ
using DensityRatioEstimation
using Distributions
using LinearAlgebra
using DataFrames
using Distributed
using CSV

# Disable logs
using Logging
disable_logging(Logging.Info)
disable_logging(Logging.Warn)

seed = 126
replicates = 10000
samples = [100, 400, 900, 1600]
include(scriptsdir("dgp", "synthetic-3-stepwise-trunc.jl"))

# Set up function to simulate the true variance of a given graph
function bestvar(scm, intervention, nsamples, i)
    println("$nsamples Samples, iteration $(i)")
    dat = summarize(rand(scm, nsamples))
    truth = compute_true_MTP(scm, dat, intervention)
    return truth.eff_bound
end

df = DataFrame(samples = samples)

# Run ER graph
gname = "er"
getgraph(n) = erdos_renyi(n, 3/n)
draws = reduce(hcat, [pmap(i -> bestvar(scm, intervention, nsamples, i), 1:replicates) for nsamples in samples])
vars = vec(mean(draws, dims=1))
df[!, gname] = vars

# Run WS graph
gname = "ws"
getgraph(n) = watts_strogatz(n, 6, 0.5)
draws = reduce(hcat, [pmap(i -> bestvar(scm, intervention, nsamples, i), 1:replicates) for nsamples in samples])
vars = vec(mean(draws, dims=1))
df[!, gname] = vars

# Run SF graph
gname = "sf"
getgraph(n) = static_scale_free(n, 2 * n, 3.5)
draws = reduce(hcat, [pmap(i -> bestvar(scm, intervention, nsamples, i), 1:replicates) for nsamples in samples])
vars = vec(mean(draws, dims=1))
df[!, gname] = vars

# Write results to file
filename = "graph_variances2500.csv"
filepath = projectdir("..", "data", filename)
CSV.write(filepath, df)
