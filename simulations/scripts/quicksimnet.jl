using DrWatson
@quickactivate :networkMTPsim

include(scriptsdir("auxiliary", "1-setup.jl"))

name = "quicksimnet.jl"
config_name = "er"

include(scriptsdir("auxiliary", "2-run-simulation-linear"))