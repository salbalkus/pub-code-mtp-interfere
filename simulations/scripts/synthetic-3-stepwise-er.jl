using DrWatson
@quickactivate :networkMTPsim

include(scriptsdir("auxiliary", "1-setup.jl"))

getgraph(n) = erdos_renyi(n, 4/n)
name = "synthetic-3-stepwise.jl"
config_name = "er"


include(scriptsdir("auxiliary", "2-run-simulation.jl"))