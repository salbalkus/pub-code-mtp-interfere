using DrWatson
@quickactivate :networkMTPsim

include(scriptsdir("auxiliary", "1-setup.jl"))

getgraph(n) = erdos_renyi(n, 3/n)
name = "synthetic-3-stepwise-trunc.jl"
netname = "er-super-fast"

include(scriptsdir("auxiliary", "2-run-simulation.jl"))

makeplots(result, config; ci = [false, false, false],  methodnames = ["tmle", "tmle_iid", "ols"], varsymb = :σ2net)

result = CSV.read(datadir("estimates", "name=synthetic-3-stepwise-trunc.jl_netname=er-super-fast.csv"), DataFrame,
            types = [String, Float64, String, Int, Int])
#config = Dict("ψ" => 0.5399928400257927, "name" => name, "netname" => netname )
opchars(result, config; varsymb = :σ2net)

savetable(result, config; varsymb = :σ2net)
savetruth(config)