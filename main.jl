using JuMP, StatsBase, Cbc

include("stochastic.jl")
include("helper.jl")
include("model.jl")

import model
import helpers
import stochastic

# Provides the optimal distribution of budget among different crop categories so that the farmer minimizes his 10% CVaR
BudgetDistribution = stochastic.obtainCropCat()

# Obtain farm description from the farmer
farmDescription = helpers.getProfile(BudgetDistribution)
howLong = farmDescription[1]    # entire farming duration
start = farmDescription[2]    # starting month
LandSpace = farmDescription[3]    # amount of land in farm
minCropVariety = farmDescription[4]   # minimum number of crop varieties
LabourAvailable = farmDescription[5]   # amount of labour for each month

# Obtain optimal planting & harvesting schedule
model.solveMod(howLong, start, LandSpace, minCropVariety, LabourAvailable, BudgetDistribution)
