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
        A ~ Normal.(0.1 * reg, 1),
        As $ Sum(:A, :G),
        nonlin = (@. 5 * (L1 + L2) + (L1 * L3 + L2 * L4) + log(L5 + 0.1 * L6) + 0.5 * sqrt(L7 + L8)),
        Y ~ (@. Normal(0.05 * A + 0.1 * As + 0.05*0.6*As*L1 - 0.05*0.4*As*L2 + 0.05 * nonlin + 3, 0.1))
    ),
    treatment = :A,
    response = :Y,
    confounders = [:L1, :L2, :L3, :L4, :L5, :L6, :L7, :L8]
)
intervention = AdditiveShift(0.2)

