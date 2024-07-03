
using DrWatson
@quickactivate :networkMTPsim
using CSV
using DataFrames
using CausalTables
using ModifiedTreatment
using Graphs
using DataFramesMeta
using Statistics

# Plotting libraries
using Plots
using StatsPlots
using LaTeXStrings

vars = ["er2", "ba2", "cg2"]
ps = Vector{Plots.Plot}(undef, length(vars) * 2)

for (i, var) in enumerate(vars)

    # Load and clean data
    path = datadir("external", "name=poster_$(var).jl_mtpname=CV-SuperLearner.csv")
    df = CSV.read(path, DataFrame)
    df = df[df[!, "estimate"] .!= "stabilized",:]
    df[!, "value"] = coalesce.(parse.(Float64, df[!, "value"]), missing)
    df[!, "value"] = abs.(df[!, "value"])
    df = df[.!(isnan.(df[!, "value"])),:]

    # Ground Truth Parameters
    seed = 2
    ntruth =  10^6
    name = "poster_$(var).jl"

    # Generate ground truth
    include(scriptsdir("dgp", "$(name)"))
    config = maketruth(@strdict name seed ntruth dgp intervention)

    # Compute operating characteristics
    r = opchars(df, config; varsymb = :σ2net, methodnames = ["onestep", "tmle"])
    r[!, "graph"] .= var

    # Set up error bars
    errsymbs = Vector{Union{Nothing, Vector}}(nothing, 3)
    errsymbs[1] = r.ci_bias
    errsymbs[2] = r.ci_scaled_bias
    errsymbs[3] = r.ci_scaled_mse

    # Define cross-plot attributes
    xlab = "Sample Size"
    markershape = :auto
    markerstrokecolor = :auto

    # Define plots
    p1 = bias_plot = @df r plot(:samples, :bias, group = :method,
            yerror = errsymbs[1],
            #xlabel = xlab, 
            ylabel= i == 1 ? L"\psi - \hat{\psi}_n" : "",
            markershape = markershape,
            title = "",
            #ylims = [-0.2, 0.2],
            yaxis = i == 1,
            xaxis = false,
            legend = false,
            left_margin= i == 1 ? 6Plots.mm : 0Plots.mm,
            right_margin= i == 3 ? 6Plots.mm : 0Plots.mm,
            markerstrokecolor = markerstrokecolor
        ) 
    hline!([0], label = "")
    ps[i] = p1

    p2 = coverage_plot = @df r plot(:samples, :coverage, group = :method,
        ylims = [0.7, 1],
        #xlabel = xlab, 
        ylabel= i == 1 ? "Coverage" : "",
        yaxis = i == 1,
        markershape = markershape,
        title = "",
        left_margin= i == 1 ? 6Plots.mm : 0Plots.mm,
        right_margin= i == 3 ? 6Plots.mm : 0Plots.mm,
        legend = false
    ) 
    hline!([0.95], label = "Size")

    ps[i + 3] = p2
end

using Plots.PlotMeasures
p = plot(ps..., layout=(2,3), link = :all)
p = plot(p, size = (800, 300), margin= 0Plots.mm)
savefig(p, "poster_plots.png")
ps[6]

