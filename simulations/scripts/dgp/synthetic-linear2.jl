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
        linear_confounders = (@. L1 + L2 + L3 + L4 + 0.1 * L5 + 0.01 * L6 + 0.25 * (L7) + 0.125 * L8),
        F = Friends(:G),
        L1s = Sum(:L1, :G),
        L2s = Sum(:L2, :G),
        L3s = Sum(:L3, :G),
        L4s = Sum(:L4, :G),
        L5s = Sum(:L5, :G),
        L6s = Sum(:L6, :G),
        L7s = Sum(:L7, :G),
        L8s = Sum(:L8, :G),
        A ~ (@. Normal(0.1 * linear_confounders, 1.0)),
        As $ Sum(:A, :G),
        Y ~ (@. Normal(0.1 * A + 0.1 * As + 0.1 * linear_confounders, 0.1))
    ),
    treatment = :A,
    response = :Y,
    confounders = [:L1, :L2, :L3, :L4, :L5, :L6, :L7, :L8, :F, :L1s, :L2s, :L3s, :L4s, :L5s, :L6s, :L7s, :L8s]
)
intervention = AdditiveShift(0.1)