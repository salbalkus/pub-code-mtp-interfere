# A very simple simulation to check if the code is working on the network data

scm = StructuralCausalModel(
    @dgp(
        L ~ Bernoulli(0.3),
        A ~ (@. Normal(L - 0.3, 1)),
        n = length(L),
        G = Graphs.adjacency_matrix(Graphs.erdos_renyi(n, 4 / n)),
        As $ Sum(:A, :G),
        Y ~ (@. Normal(L + A + As + 50, 1))
    ),
    treatment = [:A, :As],
    response = :Y
)
intervention = AdditiveShift(0.2)