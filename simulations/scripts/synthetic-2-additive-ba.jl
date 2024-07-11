using DrWatson
@quickactivate :networkMTPsim

include(scriptsdir("auxiliary", "1-setup.jl"))

getgraph(n) = barabasi_albert(n, 1)
name = "synthetic-2-additive.jl"
config_name = "ba"


include(scriptsdir("auxiliary", "2-run-simulation.jl"))