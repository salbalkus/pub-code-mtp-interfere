dgp = @dgp(
        X1 ~ (@. Normal(1, 1)),
        X2 ~ (@. Normal(1, 1)),
        Y ~ (@. Normal(X1 + X2, 1)),
    )

scm = StructuralCausalModel(
    dgp;
    treatment = :X,
    response = :Y
)

ct = rand(scm, 1000000)
ctd2 = replace(ct; data = (X = ct.data.X ./ 1.05, Y = ct.data.Y))

rt2 = propensity(scm, ctd2, :X) ./ propensity(scm, ct, :X)

mean(ct.data.X .* (propensity(scm, ctd2, :X) ./ propensity(scm, ct, :X)) / 1.05)

mean((ct.data.X .- mean(ct.data.X)).^2 .* (propensity(scm, ctd2, :X) ./ propensity(scm, ct, :X)) / 1.05)

##

n = 100000
k = 10
X = [Normal(1,1) for _ in 1:k]
Y = NoncentralChisq(k, sum(mean.(X).^2))
x = rand.(X, n) 
y = vec(sum(reduce(hcat, x).^2, dims = 2))

δ = 1.05
r1 = prod(reduce(hcat, [pdf.(X[i], x[i] ./ δ) for i in 1:k]), dims=2) ./ prod(reduce(hcat, [pdf.(X[i], x[i]) for i in 1:k]), dims=2)
h1 = 1 ./ δ^k
mean(y .* r1 .* h1)

r2 = pdf(Y, y ./ δ.^2) ./ pdf(Y, y)

D = (2 .* reduce(hcat, x))
Dδ = (2 .* reduce(hcat, x) ./ δ.^2)
h2 = sqrt.([Dδ[i] * Dδ[i]' for i in 1:n] ./ [D[i] * D[i]' for i in 1:n])

mean((y .* r2 .* h2))

##

n = 100000
k = 3
X = [Normal(1,1) for _ in 1:k]
Y = NoncentralChisq(k, sum(mean.(X).^2))
x = rand.(X, n) 
y = vec(sum(reduce(hcat, x).^2, dims = 2))

δ = rand(Uniform(0.9, 1.2), n)

r1 = prod(reduce(hcat, [pdf.(X[i], x[i] .* δ) for i in 1:k]), dims=2) ./ prod(reduce(hcat, [pdf.(X[i], x[i]) for i in 1:k]), dims=2)
h1 = δ.^k
mean(y .* r1 .* h1)

r2 = pdf(Y, y .* δ.^2) ./ pdf(Y, y)

D = (2 .* reduce(hcat, x))
Dδ = (2 .* reduce(hcat, x).* δ.^2)
h2 = sqrt.([Dδ[i] * Dδ[i]' for i in 1:n] ./ [D[i] * D[i]' for i in 1:n])

mean(y .* r2 .* h2)

##

n = 1000000
k = 3
X = [Normal(20,1) for _ in 1:k]
Y = NoncentralChisq(k, sum(mean.(X).^2))
x = rand.(X, n) 
y = vec(sum(reduce(hcat, x).^2, dims = 2))

δ = 1.015

r1 = prod(reduce(hcat, [pdf.(X[i], x[i].^δ) for i in 1:k]), dims=2) ./ prod(reduce(hcat, [pdf.(X[i], x[i]) for i in 1:k]), dims=2)
h1 = prod(reduce(hcat, [(x[i].^(δ .- 1)) .* δ for i in 1:k]), dims=2)
mean(y .* r1 .* h1)
yδ = sum(reduce(hcat, [x[i].^(2*δ) for i in 1:k]), dims=2)
r2 = pdf(Y, yδ) ./ pdf(Y, y)



D = reduce(hcat, [2 .* x[i] for i in 1:k])
Dδ = reduce(hcat, [2 * δ .* x[i].^(2*δ - 1) for i in 1:k])
h2 = sqrt.([Dδ[i] * Dδ[i]' for i in 1:n] ./ [D[i] * D[i]' for i in 1:n])

mean(y .* r2 .* h2)


