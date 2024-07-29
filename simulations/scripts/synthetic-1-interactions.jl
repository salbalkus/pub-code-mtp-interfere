using DrWatson
@quickactivate :networkMTPsim

include(scriptsdir("auxiliary", "1-setup.jl"))

# BA Graph
getgraph(n) = barabasi_albert(n, 1)
name = "synthetic-1-interactions.jl"
netname = "ba"

include(scriptsdir("auxiliary", "2-run-simulation.jl"))

savetable(result, config; varsymb = :σ2net)
savetruth(config)

# ER Graph
getgraph(n) = erdos_renyi(n, 4/n)
name = "synthetic-1-interactions.jl"
netname = "er"

include(scriptsdir("auxiliary", "2-run-simulation.jl"))

savetable(result, config; varsymb = :σ2net)
savetruth(config)

# WS Graph
getgraph(n) = watts_strogatz(n, 4, 0.5)
name = "synthetic-1-interactions.jl"
netname = "ws"

include(scriptsdir("auxiliary", "2-run-simulation.jl"))

savetable(result, config; varsymb = :σ2net)
savetruth(config)