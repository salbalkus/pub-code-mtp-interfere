using DrWatson
@quickactivate :networkMTPsim

include(scriptsdir("auxiliary", "1-setup.jl"))

name = "quicksimnet.jl"
netname = "er"

include(scriptsdir("auxiliary", "2-run-simulation-linear.jl"))

makeplots(result, config; ci = [true, false, false], methodnames = ["tmle"], varsymb = :σ2net)

