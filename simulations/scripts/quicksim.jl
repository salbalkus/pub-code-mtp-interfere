using DrWatson
@quickactivate :networkMTPsim

include(scriptsdir("auxiliary", "1-setup.jl"))

name = "quicksim.jl"
netname = "iid"

include(scriptsdir("auxiliary", "2-run-simulation-linear.jl"))