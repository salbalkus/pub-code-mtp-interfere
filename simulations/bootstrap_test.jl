using SparseArrays
using LinearAlgebra
using Graphs
using Distributions


n = 3000
G1 = adjacency_matrix(watts_strogatz(n, 10, 0.5))
G2 = adjacency_matrix(watts_strogatz(n, 10, 0.5))
G = G1 .+ G2

gamma = 10
#G = adjacency_matrix(static_scale_free(n, 2 * n, 3.5))
S = Matrix(G .+ (gamma .* sparse(I,n,n)))
T = Matrix(0.5 .* G .+ 8 .* sparse(I,n,n))

X = rand(MvNormal(10 .* ones(n), T), 1000000)
m = mean(X, dims = 1)
mean(m)
# true (approximate) variance of the mean)
var(m)

# mean value of empirical variance
# it's wrong because some units are correlated
mean(var(X, dims = 1))/ n
# example
k = 100
Xs = X[:, 1:k]
# bootstrap
eps = rand(MvNormal(S), 1000)
D = ((transpose(Xs) .- m[1:k]) * eps / n)
v = transpose(var(Xs, dims = 1) ./ n)
var(D, dims = 2)
var(D, dims = 2)
full_var =  var(D, dims = 2)
covar = full_var .- gamma .* v
mean(v .+ covar)

mean(transpose(Xs[:, i] .- mean(Xs[:, i])) * (G .+ sparse(I, n,n)) * (Xs[:, i] .- mean(Xs[:, i])) / n^2 for i in 1:k)
