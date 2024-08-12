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
seed = 1
ntruth = 10^6

samples = [400, 900, 1600, 2500]
nreps = 200
bootstrap = BasicSampler()
bootstrap_samples = 0
