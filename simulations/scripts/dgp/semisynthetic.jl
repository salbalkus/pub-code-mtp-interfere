using TableTransforms
path = joinpath(projectdir(), "..", "data")

# Prepare the data
df_raw = CSV.read(joinpath(path,"NO2_ZEV_ZCTAs.csv"), DataFrame)
df = select(sort(df_raw, :ZCTA), Not([:ZCTA, :n2_2019, :ZEV_2019_pct, :ZEV_2013_pct, :no2]))
df[!, "pop"] = float.(df_raw[!, "pop"]);
df = df |> TableTransforms.Center()

# Prepare the network
net_raw = CSV.read(joinpath(path, "ZEV_commuters_2019.csv"), DataFrame)
net = filter(row -> row.h_zcta ∈ df_raw.ZCTA && row.w_zcta ∈ df_raw.ZCTA, net_raw)
zctas = sort(union(unique(net.w_zcta), unique(net.h_zcta)))
zctas_dict = Dict(zctas .=> 1:length(zctas))
net.w_zcta = map(x -> zctas_dict[x], net.w_zcta)
net.h_zcta = map(x -> zctas_dict[x], net.h_zcta)

# Construct graph and extract weight matrix
g = SimpleWeightedDiGraph(net.w_zcta, net.h_zcta, net.weight)
neighbors = (g.weights .> 0.05)
n = nv(g)
L = Tables.matrix(df)

scm = StructuralCausalModel(
    @dgp(
        L1 ~ Normal.(L[:,1], 0),
        L2 ~ Normal.(L[:,2], 0),
        L3 ~ Normal.(L[:,3], 0),
        L4 ~ Normal.(L[:,4], 0),
        L5 ~ Normal.(L[:,5], 0),
        L6 ~ Normal.(L[:,6], 0),
        L7 ~ Normal.(L[:,7], 0),
        L8 ~ Normal.(L[:,8], 0),
        L9 ~ Normal.(L[:,9], 0),
        L10 ~ Normal.(L[:,10], 0),
        L11 ~ Normal.(L[:,11], 0),
        L12 ~ Normal.(L[:,12], 0),
        L13 ~ Normal.(L[:,13], 0),
        L14 ~ Normal.(L[:,14], 0),
        L15 ~ Normal.(L[:,15], 0),
        L16 ~ Normal.(L[:,16], 0),
        reg = (@. 0.0001 * L1 + 0.1 * L2 + 1.0 * L3 + 0.1 * L4 + 0.1 * L5 + 0.0001 * L6 + 0.1 * L7 + 0.1 * L8 + 
                  0.00001 * L9 + 0.1 * L10 + 0.1 * L11 + 1.0 * L12 + 1.0 * L13 + 0.1 * L14 + 0.1 * L15 + 0.1 * L16),
        G = neighbors,
        F = Friends(:G),
        A ~ (@. Normal(0.01 * reg, 1.0)),
        As $ Sum(:A, :G),
        Y ~ (@. Normal(A + As + 0.1 * reg, 1.0))
    ),
    treatment = :A,
    response = :Y,
    confounders = [:F, :L1, :L2, :L3, :L4, :L5, :L6, :L7, :L8, :L9, :L10, :L11, :L12, :L13, :L14, :L15, :L16]
)

intervention = AdditiveShift(0.1)