scm = StructuralCausalModel(
    @dgp(
        L ~ Bernoulli(0.3),
        A ~ (@. Normal(L - 0.3, 1)),
        G = Graphs.adjacency_matrix(Graphs.random_regular_graph(length(A), 2)),
        As $ Sum(:A, :G),
        Y ~ (@. Normal(L + A + As + 50, 1))
    ),
    treatment = :A,
    response = :Y,
    confounders = [:L]
)
intervention = AdditiveShift(0.1)