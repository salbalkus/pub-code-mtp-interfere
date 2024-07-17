using DrWatson
@quickactivate :networkMTPsim

include(scriptsdir("auxiliary", "1-setup.jl"))

getgraph(n) = barabasi_albert(n, 1)
name = "synthetic-3-stepwise.jl"
netname = "ba"

include(scriptsdir("auxiliary", "2-run-simulation.jl"))

makeplots(result, config; ci = [false, false, false], methodnames = ["tmle", "tmle_iid", "ols"], varsymb = :σ2net)


savetable(result, config; varsymb = :σ2net)
savetruth(config)



