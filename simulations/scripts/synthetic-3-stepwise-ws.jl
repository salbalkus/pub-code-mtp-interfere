using DrWatson
@quickactivate :networkMTPsim

include(scriptsdir("auxiliary", "1-setup.jl"))

getgraph(n) = watts_strogatz(n, 6, 0.5)
name = "synthetic-3-stepwise-trunc.jl"
netname = "ws-super-fast"

include(scriptsdir("auxiliary", "2-run-simulation.jl"))
    
makeplots(result, config; ci = [false, false, false], methodnames = ["tmle", "tmle_iid", "ols"], varsymb = :σ2net)

savetable(result, config; varsymb = :σ2net)
savetruth(config)