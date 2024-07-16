module networkMTPsim

    using DrWatson
    using Random
    using CausalTables
    using ModifiedTreatment
    using MLJBase
    using Graphs
    using CRC32
    using LinearAlgebra
    using SparseArrays
    using GLM

    include("utilities.jl")
    export cluster_graph

    include("maketruth.jl")
    export maketruth, simulate_truth

    using CSV
    using DataFrames
    using NamedTupleTools
    include("simulate.jl")
    export simulate
    export simulate_mtp_fit, simulate_ols_fit
    export simulate_data

    using DataFramesMeta
    using StatsBase
    using StatsPlots
    using Distributions
    using LaTeXStrings
    include("makeplots.jl")
    export opchars
    export makeplots
    export savetable, savetruth
end