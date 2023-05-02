########### Functions for Forking ################

## Write separate Function Files for Steps
write_Step_Function = function(design, design_dir) {
  if (dir.exists(design_dir) == FALSE) {
    dir.create(design_dir)
  }
  
  iorder = 0
  for (StepName in names(design)) {
    file_name = paste0(design_dir, StepName, ".R")
    iorder = iorder + 1
    if (file.exists(file_name) == FALSE) {
      Text_toWrite <- ""
      Text_toWrite[1] = paste0(StepName, " = function(input = NULL, choice = NULL) {")
      Text_toWrite[length(Text_toWrite) + 1] = sprintf('StepName = "%s"', StepName)
      Text_toWrite[length(Text_toWrite) + 1] = paste0("Choices = ", design[StepName])
      Text_toWrite[length(Text_toWrite) + 1] = paste0("Order = ", iorder)
      Text_toWrite[length(Text_toWrite) + 1] = ""
      Text_toWrite[length(Text_toWrite) + 1] = "#Adjust here below: make sure the script handles all choices (/choice/) defined above. Data is accessible via input$data"
      Text_toWrite[length(Text_toWrite) + 1] = "output = input$data"
      Text_toWrite[length(Text_toWrite) + 1] = ""
      Text_toWrite[length(Text_toWrite) + 1] = ""
      Text_toWrite[length(Text_toWrite) + 1] = "#No change needed below here - just for bookkeeping"
      Text_toWrite[length(Text_toWrite) + 1] = "stephistory = input$stephistory"
      Text_toWrite[length(Text_toWrite) + 1] = "stephistory[StepName] = choice"
      Text_toWrite[length(Text_toWrite) + 1] = "  return(list("
      Text_toWrite[length(Text_toWrite) + 1] = "    data = output,"
      Text_toWrite[length(Text_toWrite) + 1] = "    stephistory = stephistory"
      Text_toWrite[length(Text_toWrite) + 1] = "  ))"
      Text_toWrite[length(Text_toWrite) + 1] = "}"
      
      
      file.create(file_name)
      con <- file(file_name, "w")
      writeLines(Text_toWrite, con)
      close(con)
    }
    else {
      print(paste0(
        "Function ",
        StepName,
        " already exists. Function is not overwritten"
      ))
    }
    save(design, file = paste0(design_dir, "DESIGN.RData"))
  }
}

## Source Design from Inputs
source_Design = function (ListOfStepFunctionFolders) {
  FunctionNames = NULL
  FunctionOrder = NULL
  for (iFolder in ListOfStepFunctionFolders) {
    StepFunctions = list.files(iFolder, pattern = ".R", full.names=TRUE)
    StepFunctions_Short = list.files(iFolder, pattern = ".R", full.names=FALSE)
    for (ifile in 1:length(StepFunctions)) {
      imported =  readLines(StepFunctions[ifile])
      eval(parse(text = imported[grep("Order = ", imported)]))
      eval(parse(text = imported[grep("Choices = ", imported)]))
      FunctionName = gsub("\\.R", "", StepFunctions_Short[ifile])
      FunctionOrder = c(FunctionOrder, Order)
      eval(parse(text = paste0(FunctionName, "= Choices")))
      FunctionNames = c(FunctionNames, FunctionName)
    }
  }
  FunctionNames = FunctionNames[order(ordered(FunctionOrder))]
  
  
  design = vector(mode = "list", length = length(FunctionNames))
  for (i in 1:length(FunctionNames)) {
    design[[i]] = eval(parse(text = FunctionNames[i]))
  }
  names(design) = FunctionNames
  return(design)
}



## Combine the Forks
combine_Choices = function(design, PreviousStep) {
  # This can easily result in sizes extending the available RAM
  # One Solution is to Fork everything till Outliers, clean up, then merge with Rest
  
  highest_outlier = max(which(grepl("Outliers_", names(design))))
  
  Forking_List1 = do.call(expand.grid, design[1:highest_outlier])
  
  
  # Drop outlier combinations that cannot be
  # Get Indexes of Nones
  outlier_collumns = names(design)[grepl("Outliers_", names(design))]
  outlier_collumns = outlier_collumns[!grepl("Personality", outlier_collumns)]
  Idx_None = Forking_List1[outlier_collumns] == "None"
  All_None = apply(Idx_None, 1, all)
  
  # If all selected to None, then Threshold and Treatment must be none
  Idx_To_Drop = c(which(Forking_List1$Outliers_Threshold != "None" & All_None),
                  which(Forking_List1$Treat_Outliers != "None" & All_None))
  
  # If Threshold/Treatment are None, all others must be None 
  Idx_To_Drop = c(Idx_To_Drop,
                  which(Forking_List1$Outliers_Threshold == "None" & !All_None),
                  which(Forking_List1$Treat_Outliers == "None" & !All_None))
  
  
  # If Threshold is None, Treatment must be none and vice versa
  Idx_To_Drop = c(Idx_To_Drop,
                  which(Forking_List1$Outliers_Threshold == "None" & !Forking_List1$Treat_Outliers == "None"),
                  which(!Forking_List1$Outliers_Threshold == "None" & Forking_List1$Treat_Outliers == "None"))
  
  Idx_To_Drop = c(Idx_To_Drop,
                  which(Forking_List1$Outliers_EEG == "None" & Forking_List1$Treat_Outliers == "Replace"))
  
  
  Idx_To_Drop = unique(Idx_To_Drop)
  
  # Drop these from combination
  Forking_List1 = Forking_List1[-Idx_To_Drop,]
  
  
  
  # Fork second part and merge
  Forking_List2 = do.call(expand.grid, design[(highest_outlier+1):length(design)])
  Forking_List = tidyr::crossing(Forking_List1, Forking_List2)
  

  # Change Structure
  fac_cols = sapply(Forking_List, is.factor)
  Forking_List[fac_cols] <-
    lapply(Forking_List[fac_cols], as.character)
  Combination_Name = apply(Forking_List, 2, function(col)
    as.numeric(format(
      factor(
        col,
        levels = unique(col),
        labels = 1:length(unique(col))
      )
    )))
  
  # Create Output Numbering
  Combination_Number = ""
  for (i_Step in 1:ncol(Combination_Name)) {
    Combination_Number = paste0(Combination_Number,
                                "_",
                                i_Step + PreviousStep,
                                ".",
                                Combination_Name[, i_Step])
  }
  CombinedForks = list(Forks_Table = Forking_List, Forks_Nr = Combination_Number)
  return(CombinedForks)
}



## Create List for MainPath
create_ForkingLists_MainPath = function(CombinedForks,
                                        MainPath)  {
  Path_To_Merged_Files = paste0(MainPath,"Group_Data/" )
  Path_To_Export = paste0(MainPath,"Stats_Results/" )
  
  
  Combinations = list.files(Path_To_Merged_Files,
                            pattern = ".txt")
  
  OUTPUT = cbind(Combinations[1],
                 CombinedForks$Forks_Nr[1],
                 CombinedForks$Forks_Table[1, ])
  
  names(OUTPUT)[1:2] = c("InputNumber", "CombinationNumber")
  filename = paste0(Path_To_Export, "/OUTPUT_", as.character(iSubset), ".txt")
  write.table(
    OUTPUT,
    filename,
    sep = ";",
    row.names = FALSE,
    col.names = TRUE
  )
  
}


## Create List of Packages (dependent on length of Files)
create_ForkingLists = function(CombinedForks,
                               RootPath,
                               sizeSubsets)  {
  # Set up Paths
  Path_To_Merged_Files = paste0(RootPath,"Group_Data/" )
  Path_To_Export = paste0(RootPath,"Stats_Forks/" )
  dir.create(Path_To_Export)
  
  # Get all Preprocessing Combinations from the FileNames of the Merged Files
  Combinations_Preproc = list.files(Path_To_Merged_Files, pattern = ".txt")
  NrCombinations_PreProc = length(Combinations_Preproc)
  
  # Check how many more Statistic Combinations there are (compared to the Preprocessing)
  Multiply = NrCombinations_PreProc %/% nrow(CombinedForks$Forks_Table)
  Remainder = NrCombinations_PreProc %% nrow(CombinedForks$Forks_Table)
  
  set.seed(872436)
  # Create a List (Index) of a subsample (or a multiple) from the Statistics that 
  # should be used to fork statistics
  TotalCombinationsIndex = c(rep(1:nrow(CombinedForks$Forks_Table), Multiply),
                             sample(1:nrow(CombinedForks$Forks_Table), Remainder))
  
  # Shuffle again (in case it was multiplied this is important)
  TotalCombinationsIndex = sample(TotalCombinationsIndex)
  
  # How many Files will be created
  nr_Files = ceiling(NrCombinations_PreProc / sizeSubsets)
  
  for (iSubset in 1:nr_Files) {
    # Get Index of Subset that should be used from the Random Index
    IndexSubset = ((iSubset - 1) * sizeSubsets + 1):(iSubset * sizeSubsets)
    Subset = TotalCombinationsIndex[IndexSubset]
    
    # If the last Subset, it might be incomplete. Use only Combinations
    # That are present
    if (iSubset == nr_Files) {
      IndexSubset = IndexSubset[!is.na(Subset)]
      Subset = Subset[!is.na(Subset)]
    }
    
    OUTPUT = cbind(Combinations_Preproc[IndexSubset],
                   CombinedForks$Forks_Nr[Subset],
                   CombinedForks$Forks_Table[Subset, ])
    names(OUTPUT)[1:2] = c("InputNumber", "CombinationNumber")
    filename = paste0(Path_To_Export, "/OUTPUT_", as.character(iSubset), ".txt")
    write.table(
      OUTPUT,
      filename,
      sep = ";",
      row.names = FALSE,
      col.names = TRUE
    )
  }
}






## Run Steps
run_Steps = function( OUTPUT_File,
                      RootPath, 
                      ListOfStepFunctionFolders,
                      collumnNamesEEGData,
                      LogFile, Root) {
  
  
  Path_to_Merged_Files = paste0(RootPath,"Group_Data/" )
  Path_to_Export = paste0(RootPath,"Stats_Results/" )
  
  if (!dir.exists(Path_to_Export)) {dir.create(Path_to_Export)}
  
  OUTPUT = read.table(OUTPUT_File,  sep = ";", header = TRUE)
  
  # Initiate for summary
  # Create Function to run in Parallel
  run_Steps_parallel = function (i_Fork, OUTPUT, Path_to_Merged_Files, Path_to_Export, Root){

    
    # Paste Filenames to check if already existing
    filename_input = paste0(Path_to_Merged_Files, "/", OUTPUT[i_Fork, 1])
    filename_output = paste0(Path_to_Export,
                             gsub(".txt", "", OUTPUT[i_Fork, 1]),
                             OUTPUT[i_Fork, 2],
                             ".txt")
    
    # Only Run if not already Run before
    if (file.exists(filename_output)) {
      return("Previously Completed") # added to Protocol, ParList, Logging 
    } else {
      # Initiate Data to be parsed to function
      input <- vector(mode = "list", length = 0)
      Step_Names = colnames(OUTPUT)[3:ncol(OUTPUT)]
      input$stephistory <- sapply(Step_Names, function(x) NULL)
      input$stephistory["Inputfile"] = filename_input
      input$stephistory["Final_File_Name"] = filename_output
      input$data = read.table(filename_input,  sep = ",", header = FALSE)
      input$Root_Behavior = paste0(RootPath, "/BehaviouralData/")
      input$Root_Personality =  paste0(RootPath, "/QuestionnaireData/")
      colnames(input$data) = collumnNamesEEGData 
      
      # Run in Try Catch to parse Error Messages to Parloop
      Error_Subjects = tryCatch({
        
        for (iStep in Step_Names) {
          input = do.call(iStep, list(input, OUTPUT[i_Fork, iStep]))
        }
        
        # Save completion status to ParList = Protocol
        return("Newly Completed")
        
      },  # if error occurs, save error to Parlist = Protocol
      error = function(e) {
        
        return(paste("Error with Step:", iStep, "and Choice:", OUTPUT[i_Fork, iStep], ". The error message was: ", e))
          })
      
    } 
  }  
  # Loop Through list in parallel way
  Protocol = NA
  start_time <- Sys.time() 
  Protocol = invisible(foreach(i_Fork = 1:nrow(OUTPUT),
                    .errorhandling = 'pass',
                    .combine = 'c') %dopar% run_Steps_parallel(i_Fork, OUTPUT, Path_to_Merged_Files,  Path_to_Export, RootPath))
  # just for Troubleshooting
  # for (i_Fork in 1:nrow(OUTPUT)) {
  #  Ex =  run_Steps_parallel(i_Fork, OUTPUT, Path_to_Merged_Files,  Path_to_Export)
  #  Protocol = rbind(Protocol, Ex)
  # }
  end_time <- Sys.time()  
  time_needed_forParallel <- end_time - start_time 
  
  # Save Protocol to SLURM
  Text_toWrite <- ""
  # Get Input
  Text_toWrite[1] = "Inputs to Run Forks on Statistic"
  Text_toWrite[length(Text_toWrite) + 1] = sprintf('RootPath: %s', RootPath)
  Text_toWrite[length(Text_toWrite) + 1] = sprintf('Forking File: %s', OUTPUT_File)
  Text_toWrite[length(Text_toWrite) + 1] = sprintf('RootPath: %s', RootPath)
  Text_toWrite[length(Text_toWrite) + 1] = sprintf('Calculation took : %s ', time_needed_forParallel)
  Text_toWrite[length(Text_toWrite) + 1] = ""
  
  # Summary
  Text_toWrite[length(Text_toWrite) + 1] = "Summary Achievements"
  Text_toWrite[length(Text_toWrite) + 1] = sprintf('Number of Combinations to Run: %d', nrow(OUTPUT))
  Text_toWrite[length(Text_toWrite) + 1] = sprintf('Newly Completed : %d', sum(grepl("Newly Completed", Protocol)))
  Text_toWrite[length(Text_toWrite) + 1] = sprintf('Previously Completed: %d', sum(grepl("Previously Completed", Protocol)))
  Text_toWrite[length(Text_toWrite) + 1] = sprintf('Encountered Errors: %d',sum(grepl("Error", Protocol)))
  Text_toWrite[length(Text_toWrite) + 1] = ""
  Text_toWrite[length(Text_toWrite) + 1] = ""
  Text_toWrite[length(Text_toWrite) + 1] = ""
  
  
  # Then individual Errors
  Text_toWrite[length(Text_toWrite) + 1] = "List of Errors encountered"
  for (iError in 1:length(Protocol)) {
    if (grepl("Error", Protocol[iError]) ) {
      Text_toWrite[length(Text_toWrite) + 1] = sprintf("Path %d. Combination %s%s", iError,  gsub(".txt", "", OUTPUT[iError, 1]),  OUTPUT[iError, 2])
      Text_toWrite[length(Text_toWrite) + 1] = Protocol[iError]
    }}
  
  print(Text_toWrite, row.names = FALSE)
}
