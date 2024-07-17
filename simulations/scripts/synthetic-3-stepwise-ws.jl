using DrWatson
@quickactivate :networkMTPsim

include(scriptsdir("auxiliary", "1-setup.jl"))

getgraph(n) = watts_strogatz(n, 4, 0.5)
name = "synthetic-3-stepwise.jl"
netname = "ws"

include(scriptsdir("auxiliary", "2-run-simulation.jl"))
makeplots(result, config; ci = [false, false, false], methodnames = ["tmle", "tmle_iid", "ols"], varsymb = :σ2net)
opchars(result, config; methodnames = ["tmle", "tmle_iid", "ols"], varsymb = :σ2net)

savetable(result, config; varsymb = :σ2net)
savetruth(config)


