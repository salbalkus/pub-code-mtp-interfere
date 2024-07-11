scm = StructuralCausalModel(
    @dgp(
        L ~ Bernoulli(0.3),
        A ~ (@. Normal(L - 0.3, 1)),
        n = length(L),
        G = Graphs.adjacency_matrix(Graphs.erdos_renyi(n, 4 / n)),
        As $ Sum(:A, :G),
        Y ~ (@. Normal(L + A + As + 50, 1))
    ),
    treatment = :A,
    response = :Y,
    confounders = [:L]
)
intervention = AdditiveShift(0.2)