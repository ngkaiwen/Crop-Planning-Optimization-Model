module model
using JuMP, Cbc
export solveMod
  function solveMod(howLong, start, LandSpace, minCropVariety, LabourAvailable, BudgetDistribution)

    # DATA PREPARATION
    # Read from crop input file
    cropInputFile = "InputFile.csv"
    data0 = readcsv(cropInputFile, header=true)
    data = data0[1]
    header = data0[2]

    VegID = map(Int64, data[:,1])
    VegName = data[:,2]
    YieldPerMu = map(Float64, data[:,3])
    RevPerTon = map(Float64, data[:,4])
    GrowthDuration = map(Int64, data[:,5])
    PlantLabour = map(Int64, data[:,6])
    HarvestLabour = map(Int64, data[:,7])
    PlantingSeasons = data[:, 8:19]
    NumMonths = howLong
    NumVeg = length(VegName)
    CropCostPerMu = map(Float64, data[:,20])
    CropCat = map(Int64, data[:,21])
    NumCropCat =  4   # the number of crop categories (categorized by fluctations in returns over the past 36 months - refer to "stochastic.jl" and "stochastic.csv")

    # Preparing an optimization model
    mod = Model(solver=CbcSolver())

    # Decision variables
    @variable(mod, x[1:NumVeg, 1:NumMonths] >= 0, Int) # amount of crop i to plant in month j
    @variable(mod, y[1:NumMonths] >= 0, Int) # amount of land available for planting in month j
    @variable(mod, z[1:NumVeg, 1:NumMonths] >= 0, Int) # amount of crop i to harvest in month j
    @variable(mod, VegGrown[1:NumVeg], Bin) # select crop i for planting

    # Objective function (maximise revenue, minimize cost)
    @objective(mod, Max, sum(RevPerTon[i]*YieldPerMu[i]*z[i,j] for j=1:NumMonths for i=1:NumVeg) - sum(x[i,j]*CropCostPerMu[i] for j=1:NumMonths for i=1:NumVeg))

    # Planting season constraint
    for i=1:NumVeg
      for j=0:NumMonths-1
        k = ((start-1 + j)%12) + 1 # takes into account the month that the farmer wishes to begin planting
        if PlantingSeasons[i,k] == ""
          @constraint(mod, x[i,j+1] == 0) # cannot plant crop i in month j+1 if that month is not within planting season
        end
      end
    end

    # Land constraints
    for j=1:NumMonths
      @constraint(mod, sum(x[i,j] for i=1:NumVeg) <= y[j]) # amount planted in month i must be less than amount of land available in month i
    end
    @constraint(mod, LandSpace == y[1])
    for j=1:NumMonths - 1
      @constraint(mod, y[j+1] == y[j] - sum(x[i,j] for i=1:NumVeg) + sum(z[i,j] for i=1:NumVeg)) # the land you have next month will equal to (1) the excess land you have this month, (2) minus the amount of land you used for planting this month, (3) plus the amount of land you gained from harvesting this month
    end

    # Maximum crop quantity constraint
    for j=1:NumMonths
      for i=1:NumVeg
      @constraint(mod,x[i,j] <= (1/sqrt(minCropVariety))* sum(x[k,j] for k=1:NumVeg)) # constraint that limits the maximum amount of crop i that can be planted in month j
      end
    end

    # Minimum crop variety constraint
    @constraint(mod, sum(VegGrown[i] for i=1:NumVeg) >= minCropVariety) # number of crops chosen to be planted must be at least "minCropVariety"
    for i=1:NumVeg
     @constraint(mod, VegGrown[i]*9^9^2 >= sum(x[i,j] for j=1:NumMonths))
     @constraint(mod, VegGrown[i] <= sum(x[i,j] for j=1:NumMonths)) # when crop i is chosen to be planted, then VegGrown[i] will be set to 1
    end

    # No early harvest constraint
    for i=1:NumVeg
      for j=1:GrowthDuration[i]-1
        @constraint(mod, z[i,j] == 0) # cannot harvest when it is still growing
      end
    end

    # Labour constraint
    for j=1:NumMonths
      @constraint(mod, sum(PlantLabour[i]*x[i,j] + HarvestLabour[i]*z[i,j] for i=1:NumVeg) <= LabourAvailable[j])
    end

    # Specify the crop(s) to harvest for each month
    for i=1:NumVeg
      for j= 1:NumMonths
        HarvestTime = j + GrowthDuration[i] - 1
        if HarvestTime <= NumMonths
          @constraint(mod, z[i, HarvestTime] == x[i, j]) # the amount of crop i that you harvest in month "HarvestTime" is the amount you planted "GrowthDuration" ago.
        end
      end
    end

    # Specify the budget distribution to each crop category
    for k=1:NumCropCat
      @constraint(mod, sum(x[i,j]*CropCostPerMu[i] for i=1:NumVeg for j=1:NumMonths if CropCat[i] == k) <= BudgetDistribution[k])
    end

    println("Calculating optimal planting and harvesting schedule...")
    status = solve(mod)
    println("Solution is ", status)

    println("PLANTING PLAN:")
    for i=1:NumVeg
      if sum(getvalue(x)[i,:]) > 0
        println(VegName[i], " ", getvalue(x)[i,:])
      end
    end
    print("\n")

    println("HARVESTING PLAN:")
    for i=1:NumVeg
      if sum(getvalue(x)[i,:]) > 0
        println(VegName[i], " ", getvalue(z)[i,:])
      end
    end
    print("\n")

    println("Labour Hours used:") # amount of labour (planting and harvesting) used per month
    println([sum(PlantLabour[i]*getvalue(x[i,j]) + HarvestLabour[i]*getvalue(z[i,j]) for i=1:NumVeg) for j=1:NumMonths])
    print("\n")

    println("Cost:") # amount of cost per month. note: the total cost (seed cost, planting labour cost, harvesting labour cost, storage cost, etc.) is allocated at the time when the farmer decides to plant
    println([sum(getvalue(x[i,j])*CropCostPerMu[i] for i=1:NumVeg) for j=1:NumMonths])
    print("\n")

    print("Maximised Profit: ")
    println(getobjectivevalue(mod))

  end
end
