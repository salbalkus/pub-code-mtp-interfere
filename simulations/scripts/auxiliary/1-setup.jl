using CausalTables, Condensity, ModifiedTreatment
using Graphs
using Plots
using MLJ
using DensityRatioEstimation
using Distributions
using LinearAlgebra

# Disable logs
using Logging
disable_logging(Logging.Info)
disable_logging(Logging.Warn)

# Set ground truth parameters
seed = 126
ntruth = 10^6
samples = [100, 400, 900, 1600]
nreps = 20
bootstrap = BasicSampler()
bootstrap_samples = 0
