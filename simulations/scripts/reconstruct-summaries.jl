using DrWatson
@quickactivate :networkMTPsim
using DataFrames, CSV

using SimpleWeightedGraphs
using Random, GLM

include(scriptsdir("auxiliary", "1-setup.jl"))

name = "semisynthetic-trunc.jl"
include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
ntruth = n
samples = [n]
add_shift = intervention.δb(nothing)

for α in [0.0, -5.0, 5.0]
    netname = "α=$(α)"
    scm = semisynthetic_scm(α, 1.0)
    config = @strdict name ntruth scm intervention
    config["ψ"] = mean(((reg .+ α) .+ add_shift) .* (1.0 .+ vec(sum(neighbors, dims=1))) .+ reg .+ reg2 .- 150)
    config["eff_bound"] = NaN
    include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
    config = maketruth(@strdict name seed ntruth scm intervention)

    result = CSV.read(joinpath(projectdir(), "data", "estimates", "name=semisynthetic-trunc.jl_netname=α=$(α).csv"), DataFrame; types = [String, Float64, String, Int, Int])
    tbl = opchars(result, config; varsymb = :σ2net, methodnames = ["tmle", "tmle_iid", "ols"])
    tbl2 = DataFrames.select(tbl, [:method, :bias, :pct_bias, :variance, :coverage, :ci_width])


    result_super = CSV.read(joinpath(projectdir(), "data", "estimates", "name=semisynthetic-trunc.jl_netname=α=$(α);super.csv"), DataFrame; types = [String, Float64, String, Int, Int])
    tbl_super = opchars(result_super, config; varsymb = :σ2net, methodnames = ["tmle", "tmle_iid", "ols"])

    tbl2_super = DataFrames.select(tbl_super, [:method, :bias, :pct_bias, :variance, :coverage, :ci_width])

    tbl2_super[!, "method"] = tbl2_super[!, "method"] .* "_super"
    tbl_final = vcat(tbl2, tbl2_super[1:2, :])
    output_path = joinpath(projectdir(), "..", "data", "semisynthetic-summary-α=$(α).csv")
    CSV.write(output_path, tbl_final)
end