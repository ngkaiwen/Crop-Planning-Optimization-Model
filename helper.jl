module helpers
export getProfile

  function getProfile(BudgetDistribution)

    chosen_cat = [] # stores the crop categories chosen by the stochastic model
    for i=1:length(BudgetDistribution)
      if BudgetDistribution[i] > 0
        push!(chosen_cat, i)
      end
    end

    # Read from crop input file
    cropInputFile = "InputFile.csv"
    data0 = readcsv(cropInputFile, header=true)
    data = data0[1]
    header = data0[2]
    CropCat = map(Int64, data[:,21]) # obtain the stochastic category of every crop

    max_variety = 0 # stores the maximum crop variety that can be chosen by the farmer
    for i=1:length(CropCat)
      if CropCat[i] in chosen_cat
        max_variety += 1
      end
    end

    println("How many months do you want to farm?")
    howLong = parse(Int, readline(STDIN))
    if howLong < 0
      throw(ArgumentError("Number must be non negative"))
    end

    println("Which month do you want to start? (Please specify 1-12)")
    start = parse(Int, readline(STDIN))
    if start <=0 || start > 12
      throw(ArgumentError("Please specify a number from 1-12"))
    end

    println("What is your farm size? (measured in Mu)")
    LandSpace = parse(Int, readline(STDIN))
    if LandSpace < 0
      throw(ArgumentError("Number must be non negative"))
    end

    println("What is your minimum number of crop variety?")
    minCropVariety = parse(Int, readline(STDIN))
    if minCropVariety <= 0
      throw(ArgumentError("Number must be non-negative"))
    elseif minCropVariety > max_variety
      throw(ArgumentError("Cannot plant more than number of crops in allocated categories"))
    end

    println("What type of labour do you have?")
    println("1: Regular: Constant Labour")
    println("2: Seasonal: Varies over Time")
    labourType = parse(Int, readline(STDIN))
    if labourType != 1 && labourType != 2
      throw(ArgumentError("Choose from only 1 or 2"))
    end
    LabourAvailable = Array{Int64}(howLong)
    if labourType == 1
      println("How many manhours can be allocated per month?")
      labourHour = parse(Int, readline(STDIN))
      for i in 1:howLong
        LabourAvailable[i] = Int(labourHour)
      end
    else
      for i in 1:howLong
        println("How many manhours can be allocated in Month $i")
        LabourAvailable[i] = parse(Int, readline(STDIN))
      end
    end
    return [howLong, start, LandSpace, minCropVariety ,LabourAvailable]
  end
end
