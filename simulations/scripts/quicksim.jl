using DrWatson
@quickactivate :networkMTPsim

include(scriptsdir("auxiliary", "1-setup.jl"))

name = "quicksim.jl"
config_name = "iid"

include(scriptsdir("auxiliary", "2-run-simulation-linear.jl"))