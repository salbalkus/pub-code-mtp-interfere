using DrWatson
@quickactivate :networkMTPsim

include(scriptsdir("auxiliary", "1-setup.jl"))

include(scriptsdir("dgp", "$(name)")) # load `dgp` and `intervention`
config = maketruth(@strdict name seed ntruth scm intervention)

getgraph(n) = erdos_renyi(n, 4/n)
name = "synthetic-3-stepwise-trunc.jl"
netname = "er-super-fast"

include(scriptsdir("auxiliary", "2-run-simulation.jl"))

makeplots(result, config; ci = [true, false, false],  methodnames = ["tmle", "tmle_iid", "ols"], varsymb = :σ2net)
savetable(result, config; varsymb = :σ2net)
savetruth(config)