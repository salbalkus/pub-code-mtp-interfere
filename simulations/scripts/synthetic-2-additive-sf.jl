using DrWatson
@quickactivate :networkMTPsim

include(scriptsdir("auxiliary", "1-setup.jl"))

getgraph(n) = static_scale_free(n, 2 * n, 4)
name = "synthetic-2-additive.jl"
netname = "sf"

include(scriptsdir("auxiliary", "2-run-simulation.jl"))

savetable(result, config; varsymb = :σ2net)
savetruth(config)
