
σ = 1.0
scm = StructuralCausalModel(
    @dgp(
        L1 ~ Beta(3,2),
        L2 ~ Poisson(100),
        L3 ~ Gamma(2, 4),
        L4 ~ Bernoulli(0.6),
        n = length(L1),
        G ≈ Graphs.adjacency_matrix(getgraph(n)),
        F $ Friends(:G),
        L1o $ AllOrderStatistics(:L1, :G),
        L2o $ AllOrderStatistics(:L2, :G),
        L3o $ AllOrderStatistics(:L3, :G),
        L4o $ AllOrderStatistics(:L4, :G),

        L1step = (@. -2*(L1 > 0.3) - (L1 > 0.5) + 2*(L1 > 0.7)),
        L2step = (@. -2*(L2 > 90) - (L2 > 100) + 2*(L2 > 110)),
        L3step = (@. -2*(L3 > 5) - (L3 > 10) + 2*(L3 > 15)),

        nonlin = (@. (1 + L4) * L1step + L2step + L3step + 12),
        A ~ Normal.(nonlin .- 4, σ),
        As $ Sum(:A, :G),
        Y ~ (@. truncated(Normal(
                        nonlin + (1 + L4) * (0.2 * (-2*(A > -2) - (A > 1) + 3*(A > 3)) + (As > 0) + 2*(As > 6) + 3*(As > 12)) + 5, σ), 
                        nonlin + (1 + L4) * (0.2 * (-2*(A > -2) - (A > 1) + 3*(A > 3)) + (As > 0) + 2*(As > 6) + 3*(As > 12)) + 5 - (6*σ), 
                        nonlin + (1 + L4) * (0.2 * (-2*(A > -2) - (A > 1) + 3*(A > 3)) + (As > 0) + 2*(As > 6) + 3*(As > 12)) + 5 + (6*σ)))
    ),  
    treatment = [:A],
    response = :Y
)
intervention = AdditiveShift(σ/2)


