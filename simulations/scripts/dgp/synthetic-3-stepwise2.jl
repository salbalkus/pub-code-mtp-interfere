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
        F = Friends(:G),
        L1s = Sum(:L1, :G),
        L2s = Sum(:L2, :G),
        L3s = Sum(:L3, :G),
        L4s = Sum(:L4, :G),
        L5s = Sum(:L5, :G),
        L6s = Sum(:L6, :G),
        L7s = Sum(:L7, :G),
        L8s = Sum(:L8, :G),

        L3step = (@. (L3 > 0.4) + (L3 > 0.6) + (L3 + 0.8)),
        L4step = (@. (L4 > 0.4) + (L4 > 0.6) + (L4 + 0.8)),
        L5step = (@. (L5 > 5) + (L5 > 10)  + (L5 > 20)),
        L6step = (@. (L5 > 50) + (L5 > 100)  + (L5 > 200)),
        L7step = (@. (L7 > 0.1) + (L7 > 0.5) + (L7 > 1) + (L7 > 4)),
        L8step = (@. (L7 > 0.1) + (L7 > 0.5) + (L7 > 1) + (L7 > 4) + (L7 > 10)),

        nonlin = (@. (L1 + L2) + (L1 * L3step + L2 * L4step) + L5step + L6step + L7step + L8step),
        A ~ Normal.(0.1 * nonlin, 1.0),
        As $ Sum(:A, :G),
        Y ~ (@. Normal(0.2 * ((A > 0) + (A > 0.1) + 2 * (A > 0.2) + 3 * (A > 0.4) + 4 * (A > 0.8) + 5 * (A > 2)) + 
                        1.0 * ((As > 1) + (As > 0.5) + 2 * (As > 1) + 3 * (As > 2) + 4 * (As > 4) + 5 * (As > 8)) + 
                        0.2 * nonlin, 0.1))
    ),
    treatment = :A,
    response = :Y,
    confounders = [:L1, :L2, :L3, :L4, :L5, :L6, :L7, :L8, :F, :L1s, :L2s, :L3s, :L4s, :L5s, :L6s, :L7s, :L8s]
)
intervention = AdditiveShift(0.1)

