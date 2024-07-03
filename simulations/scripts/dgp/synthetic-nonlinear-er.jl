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
        G = adjacency_matrix(erdos_renyi(n, 4/n)),
        reg = (@. L1 + L2 + L3 + L4 + 
        2 * (L1 * L3 + L2 * L4) +
        0.1 * L5 * 0.01 * L6 +
        0.25 * L7 + 0.125 * L8 +
        0.125 * L7 * L8 - 10.96),
        A ~ Normal.(reg, 0.5),
        As $ Sum(:A, :G),
        As2 = A .+ As,
        treat = (@. 0.1 * As2 + 2 * sin(0.4 * As2) + 0.1 * As2 * (L1 + L2)),
        nonlin = (@. 10 * (L1 + L2) + 2 * (L1 * L3 + L2 * L4) + log(L5 + 0.1 * L6) + sqrt(L7 + L8)),
        Y ~ (@. Normal(treat + nonlin, 1))
    ),
    treatment = :A,
    response = :Y,
    confounders = [:L1, :L2, :L3, :L4, :L5, :L6, :L7, :L8]
)
intervention = AdditiveShift(0.25)

