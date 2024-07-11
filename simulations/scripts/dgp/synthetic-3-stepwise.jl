scm = StructuralCausalModel(
    @dgp(
        L1 ~ Bernoulli(0.4),
        L2 ~ Bernoulli(0.6),
        L3 ~ Beta(3,2),
        L4 ~ Beta(2,3),
        L5 ~ Poisson(10),
        L6 ~ Poisson(100),
        L7 ~ Gamma(2, 2),
        L8 ~ Gamma(2, 4),
        n = length(L1),
        G = adjacency_matrix(getgraph(n)),
        reg = (@. L1 + L2 + L3 + L4 + 
        2 * (L1 * L3 + L2 * L4) +
        0.1 * L5 * 0.01 * L6 +
        0.25 * L7 + 0.125 * L8 +
        0.125 * L7 * L8 - 10.96),
        A ~ Normal.(0.2 * reg, 1),
        As $ Sum(:A, :G),
        Y ~ (@. Normal(0.02 * ((A > -2) + 2 * (A > -1) + 3 * (A > -0.5) + 4 * (A > 0) + 5 * (A > 0.5) + 6 * (A > 1) + 7 * (A > 2)) + 
                        0.1 * ((As > -8) + 2 * (As > -4) + 4 * (As > -2) + 6 * (As > 0) + 8* (As > 2) + 10 * (As > 4) + 12 * (As > 8)) + 
                        0.02 * reg + 10, 0.1))
    ),
    treatment = :A,
    response = :Y,
    confounders = [:L1, :L2, :L3, :L4, :L5, :L6, :L7, :L8]
)
intervention = AdditiveShift(0.2)

