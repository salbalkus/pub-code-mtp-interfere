scm = StructuralCausalModel(
    @dgp(
        L1 ~ Beta(3,2),
        L2 ~ Poisson(100),
        L3 ~ Gamma(2, 4),
        L4 ~ Bernoulli(0.6),
        n = length(L1),
        G = Graphs.adjacency_matrix(getgraph(n)),
        F $ Friends(:G),
        L1o $ AllOrderStatistics(:L1, :G),
        L2o $ AllOrderStatistics(:L2, :G),
        L3o $ AllOrderStatistics(:L3, :G),
        L4o $ AllOrderStatistics(:L4, :G),

        L1step = (@. (L1 > 0.4) + (L1 > 0.6) + (L1 + 0.8)),
        L2step = (@. (L2 > 50) + (L2 > 100)  + (L2 > 200)),
        L3step = (@. (L3 > 0.1) + (L3 > 0.5) + (L3 > 1) + (L3 > 4) + (L3 > 10)),

        nonlin = (@. L4 + L4 * L1step + L2step + L3step),
        A ~ Normal.(0.1 * nonlin, 1.0),
        As $ Sum(:A, :G),
        Y ~ (@. Cosine(0.2 * ((A > 0) + (A > 0.5) + 2 * (A > 0.75) + 3 * (A > 1) + 4 * (A > 1.25) + 5 * (A > 2)) + 
                        1.0 * ((As > 0) + (As > 1) + 2 * (As > 2) + 3 * (As > 3) + 4 * (As > 4) + 5 * (As > 5)) + 
                        0.2 * nonlin, 0.25))
    ),  
    treatment = [:A, :As],
    response = :Y,
    causes = (
        A = [:L1, :L2, :L3, :L4, :F],
        As = [:L1, :L2, :L3, :L4, :F],
        Y = [:A, :As, :L1, :L2, :L3, :L4, :F]
    )
)
intervention = AdditiveShift(0.2)

