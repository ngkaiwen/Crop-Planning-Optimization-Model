module stochastic
using JuMP, Cbc, StatsBase
export obtainCropCat

  function obtainCropCat()
    inputfile = "stochastic.csv"
    # Read from data file
    csvdata = readcsv(inputfile, header=true)
    data = csvdata[1][:,2:5]
    cropCategory = csvdata[2][:,2:5]  # obtain crop categories
    N = length(cropCategory)    # Number of crop categories
    T = size(data)[1]   # Number of months

    alpha = 0.10   # % CVaR
    Budget = 760600;    # Total Budget
    expReward = 0.013 * Budget;    # Expected reward

    # Extract data to variables
    RetTable = map(Float64,data)   # Colletively storage return of each crop category in a table

    RetMean,RetCov = mean_and_cov(RetTable) # Compute the mean of each crop category and their covariance

    # Declare Model
    m = Model(solver = CbcSolver());  # Select Solver.

    # Declaring variables
    @variable(m, x[1:N] >= 0)   # Budget allocation to each crop category
    @variable(m, y[1:T] >= 0)   # Dual 1
    @variable(m, z)   # Dual 2

    # Defining constraints
    @constraint(m, sum(x) <= Budget)  # Budget constraint
    @constraint(m, sum(RetMean[i]*x[i] for i = 1:N) >= expReward) # expected reward of porfolio is above expReward
    for i=1:T
      @constraint(m, z + y[i] >= -1/(alpha*T)*sum(RetTable[i,j]*x[j] for j=1:N)) # Dual constraint
    end

    # Setting the objective: minimize the 10%-CVaR
    @objective(m, Min, alpha*T*z + sum(y[i] for i=1:T))

    println("Calculating the optimal budget distribution...")

    # Solving the optimization problem
    solve(m)

    # Get recommended budget allocation to each crop category
    for i in 1:N
        println("Budget allocation to Crop $(cropCategory[i]) = $(getvalue(x[i]))")
    end

    println("Amount of budget used: ", sum(getvalue(x)))

    # Return an array containing the amount of resources catered to each category
    return getvalue(x)

  end
end
