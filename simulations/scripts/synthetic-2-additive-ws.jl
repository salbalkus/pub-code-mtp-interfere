using DrWatson
@quickactivate :networkMTPsim

include(scriptsdir("auxiliary", "1-setup.jl"))

getgraph(n) = watts_strogatz(n, 4, 0.5)
name = "synthetic-2-additive.jl"
netname = "ws"

include(scriptsdir("auxiliary", "2-run-simulation.jl"))

savetable(result, config; varsymb = :σ2net)
savetruth(config)


