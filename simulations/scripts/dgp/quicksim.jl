# A very simple simulation to check if the code is working

scm = StructuralCausalModel(
    @dgp(
        L ~ Bernoulli(0.3),
        A ~ (@. Normal(L, 1)),
        Y ~ (@. Normal(L + A + 10, 1))
    ),
    treatment = :A,
    response = :Y,
    confounders = [:L]
)
intervention = AdditiveShift(0.1)