
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

        L1step = (@. -(L1 > 0.2) - (L1 > 0.4) + 2*(L1 > 0.6) + (L1 > 0.8)),
        L2step = (@. -(L2 > 85) - (L2 > 95) + 2*(L2 > 105) + (L2 > 115)),
        L3step = (@. -(L3 > 2) - (L3 > 4) + 2*(L3 > 8) + (L3 > 16)),

        nonlin = (@. (L4 + L4 * L1step + L1step + L2step + L3step)),
        A ~ Normal.(nonlin .+ 4, 1.0),
        As $ Sum(:A, :G),
        Y ~ (@. truncated(Normal(
                        0.2 * nonlin + (-0.2 * (A > 1) - 0.2 * (A > 2) - 0.1 * (A > 3) - 0.1 * (A > 4) + 0.4 * (A > 5) + 
                        2 * (As > 0) + 6 * (As > 10) + 6 * (As > 15) + 2 * (As > 20) + 4 * (As > 25)) + 10, σ), 
                        0.2 * nonlin + (-0.2 * (A > 1) - 0.2 * (A > 2) - 0.1 * (A > 3) - 0.1 * (A > 4) + 0.4 * (A > 5) + 
                        2 * (As > 0) + 6 * (As > 10) + 6 * (As > 15) + 2 * (As > 20) + 4 * (As > 25)) + 10 - (6*σ), 
                        0.2 * nonlin + (-0.2 * (A > 1) - 0.2 * (A > 2) - 0.1 * (A > 3) - 0.1 * (A > 4) + 0.4 * (A > 5) + 
                        2 * (As > 0) + 6 * (As > 10) + 6 * (As > 15) + 2 * (As > 20) + 4 * (As > 25)) + 10 + (6*σ)))
    ),  
    treatment = [:A],
    response = :Y
)
intervention = AdditiveShift(0.2)

