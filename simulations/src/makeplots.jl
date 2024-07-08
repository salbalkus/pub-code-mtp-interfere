function opchars(r::DataFrame, config::Dict; varsymb = :σ2, methodnames = ["plugin", "ipw", "sipw", "onestep", "tmle"])
    z = quantile(Normal(), 0.975)
    @chain r begin
        unstack([:i, :method, :samples], :estimate, :value)
        @rsubset(:method ∈ methodnames)
        @transform(:bias = (:ψ .- config["ψ"]) ./ :ψ)
        @transform(:scaled_bias = sqrt.(:samples) .* :bias)
        @transform(:ci = z .* sqrt.($(varsymb)))
        @transform(:upper = :ψ + :ci, :lower = :ψ - :ci)
        @transform(:coverage = map((u, l) -> !ismissing(l) ? config["ψ"] .≤ u .&& config["ψ"] .≥ l : missing, :upper, :lower))
        groupby([:samples, :method])
        @combine(:bias = mean(:bias),
                 :variance = mean($(varsymb)),
                 :scaled_bias = mean(:scaled_bias),
                 :ci_bias = z .* std(:bias), 
                 :ci_scaled_bias = z .* std(:scaled_bias),
                 :coverage = mean(:coverage))
        @transform(:scaled_mse = :samples .* (:bias .^ 2 .+ :variance))
        @transform(:ci_scaled_mse = map(x -> ismissing(x) ? 0 : x, z .* sqrt.(:scaled_mse)))
    end
end

function makeplots(result::DataFrame, config::Dict; varsymb = :σ2, ci = [true, true, false], methodnames = ["plugin", "ipw", "sipw", "onestep", "tmle"])
    
    # Compute the operating characteristics
    r = opchars(result, config; varsymb = varsymb, methodnames = methodnames)

    # Determine which plots will have error bars displayed
    errsymbs = Vector{Union{Nothing, Vector}}(nothing, 3)
    ci[1] && (errsymbs[1] = r.ci_bias)
    ci[2] && (errsymbs[2] = r.ci_scaled_bias)
    ci[3] && (errsymbs[3] = r.ci_scaled_mse)

    # Define cross-plot attributes
    xlab = "Sample Size"
    markershape = :auto
    markerstrokecolor = :auto

    p1 = @df r plot(:samples, :bias, group = :method,
            yerror = errsymbs[1],
            xlabel = xlab, 
            ylabel=L"\psi - \hat{\psi}_n",
            markershape = markershape,
            title = "Bias",
            markerstrokecolor = markerstrokecolor
        ) 
    hline!([0], label = "")

    p2 = @df r plot(:samples, :scaled_bias, group = :method,
        yerror = errsymbs[2],
        xlabel = xlab, 
        ylabel=L"\sqrt{n} \times (\psi - \hat{\psi}_n)",
        markershape = markershape,
        title = "Scaled Bias",
        markerstrokecolor = markerstrokecolor
    ) 
    hline!([0], label = "")

    p3 = @df r plot(:samples, :scaled_mse, group = :method,
        yerror = errsymbs[3],
        xlabel = xlab, 
        ylabel=L"n \times ((\psi - \hat{\psi}_n)^2 + \hat{\sigma_n^2})",
        markershape = markershape,
        title = "Scaled MSE",
        markerstrokecolor = markerstrokecolor,
        legend=:topright
    ) 
    hline!([config["eff_bound"]], label = "Efficiency Bound")

    p4 = @df r plot(:samples, :coverage, group = :method,
        ylims = [0.6, 1],
        xlabel = xlab, 
        ylabel="Coverage",
        markershape = markershape,
        title = "CI Coverage"
    ) 
    hline!([0.95], label = "Size")

    return plot(p1, p2, p3, p4, layout = (2,2), size = (800, 600), plot_title = "$(config["mtpname"]), $(config["nreps"]) replicates")
end