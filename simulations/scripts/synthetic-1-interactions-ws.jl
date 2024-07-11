using DrWatson
@quickactivate :networkMTPsim

include(scriptsdir("auxiliary", "1-setup.jl"))

getgraph(n) = watts_strogatz(n, 4, 1/sqrt(n))
name = "synthetic-1-interactions.jl"
config_name = "ws"


include(scriptsdir("auxiliary", "2-run-simulation.jl"))