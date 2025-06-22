using TableTransforms
path = joinpath(projectdir(), "..", "data")

# Prepare the data
df_raw = CSV.read(joinpath(path, "NO2_ZEV_ZCTAs.csv"), DataFrame)
df = DataFrames.select(sort(df_raw, :ZCTA), Not([:ZCTA, :n2_2019, :ZEV_2019_pct, :ZEV_2013_pct, :no2]))
df[!, "pop"] = float.(df_raw[!, "pop"]);
df = df |> TableTransforms.MinMax()#TableTransforms.Center()

# Prepare the network
net_raw = CSV.read(joinpath(path, "ZEV_commuters_2019.csv"), DataFrame)
net = filter(row -> row.h_zcta ∈ df_raw.ZCTA && row.w_zcta ∈ df_raw.ZCTA, net_raw)
zctas = sort(union(unique(net.w_zcta), unique(net.h_zcta)))
zctas_dict = Dict(zctas .=> 1:length(zctas))
net.w_zcta = map(x -> zctas_dict[x], net.w_zcta)
net.h_zcta = map(x -> zctas_dict[x], net.h_zcta)

# Construct graph and extract weight matrix
g = SimpleWeightedDiGraph(net.w_zcta, net.h_zcta, net.weight)
neighbors = (g.weights .> 0.025) # trims nodes with very few commuters, since we sum directly
n = nv(g)
L = Tables.matrix(df)[:, 1:16]  # Select the first 16 columns as confounders for the model

# Define the linear model
#β = [0.0001, 0.1, 1.0, 0.1, 0.1, 0.0001, 0.1, 0.1, 0.00001, 0.1, 0.1, 1.0, 1.0, 0.1, 0.1, 0.1]
#reg = L * β
#reg2 = neighbors * L * β   # Adjust reg2 to account for neighbors
reg = vec(sum(L, dims=2))  # Use the sum of confounders as the regression term
reg2 = vec(sum(neighbors * L, dims=2))

function semisynthetic_scm(α, σ)

    many_distributions = DataGeneratingProcess(
        [Symbol("L", i) for i in 1:size(L, 2)],
        [O -> Dirac.(L[:,i]) for i in 1:size(L, 2)]
    )

    many_summaries = DataGeneratingProcess(
        vcat([:G], [Symbol("L", i, "s") for i in 1:size(L, 2)]),
        vcat([O -> neighbors], [O -> Sum(Symbol("L", i), :G) for i in 1:size(L, 2)])
    )

    many_variables = merge(many_distributions, many_summaries)

    final_output = @dgp(
        F $ Friends(:G),
        A ~ (@. Normal(reg .+ α, (reg + 1))),
        As $ Sum(:A, :G),
        Y ~ (@. truncated(Normal(A + As + reg + reg2 - 50, σ), A + As + reg + reg2 - 50 - (6*σ), A + As + reg + reg2 - 50 + (6*σ)))
    )

    confoundersymbs = vcat([Symbol("L$(i)s") for i in 1:16], [Symbol("L$(i)") for i in 1:16], [:F])
    scm = StructuralCausalModel(
        CausalTables.merge(many_variables, final_output),
        treatment=[:A, :As],
        response= :Y,
        causes = (A = confoundersymbs, As = confoundersymbs, Y = vcat([:A, :As], confoundersymbs)),
    )

    return scm
end

intervention = AdditiveShift(0.5)
