Determine_Significance = function(input = NULL, choice = NULL) {
  StepName = "Determine_Significance"
  Choices = c("Holm", "Bonferroni", "None")
  Order = 13
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:
  
  # Handles all Choices listed above 
  # Runs the statistical Test, corrects for multiple comparisons and 
  # Prepares Output Table
  
  # (1) Get Names and Formulas of variable Predictors
  # (2) Initiate Functions for Hypothesis Testing
  # (3) Main Effects of Accuracy for different Tasks
  # (4) Interaction with Perfectionism
  # (5) Correct for Multiple Comparisons
  # (6) Export as CSV file
  
  
  
  
  #########################################################
  # (1) Get Names and Formulas of variable Predictors
  #########################################################
  # Names are used to select relevant columns
  # Formula (parts) are used to be put together and parsed to the lm() function,
  # thats why they have to be added by a * or +
  
  
  # Get column Names and Formula for Covariates
  if (input$stephistory["Covariate"] == "None") { 
    Covariate_Formula = ""
    Covariate_Name = vector()
  } else if (input$stephistory["Covariate"] == "Gender_MF") { 
    Covariate_Formula = "+ Covariate_Gender"
    Covariate_Name = "Covariate_Gender"
  } else if (input$stephistory["Covariate"] == "Age_MF") { 
    Covariate_Formula = "+ Covariate_Age"
    Covariate_Name = "Covariate_Age"
  } else { 
    Covariate_Name = names(output)[names(output) %like% "Covariate_"]
    if (length(Covariate_Name)  > 1) {
      Covariate_Formula = paste("*(", paste(Covariate_Name, collapse = " + "), ")")
    } else {
      Covariate_Formula = paste( "*", Covariate_Name)
    }
  }
  
  
  # merge GMA and Component collumn
  output$Component = as.character(output$GMA_Measure)
  #########################################################
  # (2) Initiate Functions for Hypothesis Testing
  #########################################################
  wrap_test_Hypothesis = function (Name_Test,lm_formula,  Data, Component, Task, columns_to_keep) {
    # wrapping function to parse specific Information to the test_Hypothesis Function
    # Does three things: (1) Select Subset depending on Conditions and Tasks ans Analysis Phase
    # (2) Test the Hypothesis/Calculate Model and 
    # (3) Checks the direction of the effects
    # Inputs:
    # Name_Test is the Name that will be added as first collumn, to identify tests across forks, str (next to the actual interaction term)
    # lm_formula contains the formula that should be given to the lm, str
    # Data contains data (that will be filtered), df
    # GMA_Measure selects relevant Data
    # Task selects relevant Data
    # columns_to_keep lists all collumns that should be checked for completeness, array of str
    
    # Create Subset
    Subset = Data[Data$Component == Component &
                    Data$Task == Task,
                  names(Data) %in% c("ID", "Lab", "Epochs", "SME", "Component", columns_to_keep)]
    
    # Run Model
    #ModelResult = test_Hypothesis( Name_Test,lm_formula, Subset, Effect_of_Interest, "exportModel", '', FALSE) # Add false to not include Lab predictor
    ModelResult = test_Hypothesis( Name_Test,lm_formula, Subset, Effect_of_Interest, "exportModel") # Add false to not include Lab predictor
    
    # extract all Effects
    if (any(grepl("Personality", columns_to_keep))) {
    Estimates = rbind(
      # Main Condition
      test_Hypothesis( "Main_Condition",lm_formula, Subset, "Condition", "previousModel", ModelResult),
      
      # Main PersonalStandards
      test_Hypothesis( "Main_Standards",lm_formula, Subset, "Personality_MPS_PersonalStandards", "previousModel", ModelResult),
      
      # Main ConcernOverMistakes
      test_Hypothesis( "Main_Concerns",lm_formula, Subset, "Personality_MPS_ConcernOverMistakes", "previousModel", ModelResult),
      
      #  Condition * PersonalStandards
      test_Hypothesis( "ConditionxStandards",lm_formula, Subset, c("Condition", "Personality_MPS_PersonalStandards"), "previousModel", ModelResult),
      
      #  Condition * ConcernOverMistakes
      test_Hypothesis( "ConditionxConcerns",lm_formula, Subset, c("Condition", "Personality_MPS_ConcernOverMistakes"), "previousModel", ModelResult),
      
      #  PersonalStandards * ConcernOverMistakes
      test_Hypothesis( "StandardsxConcerns",lm_formula, Subset, c("Personality_MPS_PersonalStandards", "Personality_MPS_ConcernOverMistakes"), "previousModel", ModelResult),
      
      #  Condition *PersonalStandards * ConcernOverMistakes 
      test_Hypothesis( "StandardsxConcernsxCondition",lm_formula, Subset, c("Condition", "Personality_MPS_ConcernOverMistakes", "Personality_MPS_PersonalStandards"), "previousModel", ModelResult))
    
    } else { # only Main Effect of Condition
      Estimates = test_Hypothesis( "Main_Condition_NoPersonality_",lm_formula, Subset, "Condition", "previousModel", ModelResult)
    }
    
    
    # Adjust Direction to estimates
    Estimates$value_EffectSize[which(Estimates$Estimate_summary<0)] = Estimates$value_EffectSize[which(Estimates$Estimate_summary<0)]*-1
    
    # Add Info for Label
    Estimates$Effect_of_Interest = paste0(Name_Test, "_", Estimates$Effect_of_Interest)
    return(Estimates)
  }
  
  
  
  # General GMA and electrode related
  allElectrodes <- unique(input$data$Electrode)
  allElectrodes <- allElectrodes[!is.na(allElectrodes)]
  
  # Keep track of p adjustment group (family)
  # NOTE: (KLUDGE) While increasing the group ID in the model-test construction loops works, it is a bit complicated in
  # nested loops.
  testGroup <- 0L
  Estimates <- data.frame()
  #########################################################
  # (2)  Main Effects for each GMA Measure
  #########################################################
  # GMA: All complete cases (i.e., without any missing value caused by a failed GMA or with a missing EEG peak value)
  GmaSet <- output %>%
    filter(GMA_Measure %in% GMA_colnames) %>%
    group_by(ID, Task, Electrode) %>%
    filter(!any(is.na(EEG_Signal))) %>%
    ungroup()
  
  
  # Even though it may seem redundant, the GMA main effects are tested separately, since
  # a) we want to keep the groups sizes independent of the presence of personality measures, and
  # b) we want to correct the p-values for the whole group of parameters — as opposed to the correction per model.
  Names_GMA = c("rate",   "excess" ,"shape"  ,"skewness"  , "inflection1", "scaling", "inflection2")
  GMA_colnames = c("rate",   "excess" ,"shape"  ,"skew"  , "ip1_ms", "yscale", "ip2_ms")
  columns_to_keep = c("Condition", Covariate_Name,   "GMA_Measure", "EEG_Signal")
  lm_formula =   paste( "EEG_Signal ~  (Condition ) ", Covariate_Formula)
  
  
  

    for (i_task in c("GoNoGo", "Flanker")) {
      for (ch in allElectrodes) {
        testGroup = testGroup+1
        for (i_GMA in 1:length(Names_GMA)) {

        print(paste("Test ", i_task, Names_GMA[i_GMA], ch))
        Name_Test = paste0(Names_GMA[i_GMA], "_", i_task, "_", ch)
        
        
        Estimates = rbind(Estimates,  
                          wrap_test_Hypothesis(Name_Test,
                                               lm_formula, GmaSet %>% filter(Electrode == ch), 
                                               GMA_colnames[i_GMA], i_task,
                                               columns_to_keep) %>%
                            mutate(t_group = testGroup) )

    }}}
  
  
  #########################################################
  # (3) Personality Effect: GMA (Exploration)
  #########################################################
  columns_to_keep = c("Condition", Covariate_Name,   "GMA_Measure", "EEG_Signal",
                      "Personality_MPS_PersonalStandards", "Personality_MPS_ConcernOverMistakes")
  lm_formula =   paste( "EEG_Signal ~  (Condition * Personality_MPS_PersonalStandards * Personality_MPS_ConcernOverMistakes) ", Covariate_Formula)
  
  
  
  for (i_GMA in 1:length(Names_GMA)) {
    for (i_task in c("GoNoGo", "Flanker")) {
      for (ch in allElectrodes) {
        testGroup = testGroup+1
        print(paste("Test ", i_task, Names_GMA[i_GMA], ch))
        Name_Test = paste0(Names_GMA[i_GMA], "_", i_task, "_", ch)
        
        
        Estimates = rbind(Estimates,  
                          wrap_test_Hypothesis(Name_Test,
                                               lm_formula, GmaSet %>% filter(Electrode == ch), 
                                               GMA_colnames[i_GMA], i_task,
                                               columns_to_keep) %>%
                            mutate(t_group = testGroup) )
        
        
        
      }}}
  
  
  
  
  #########################################################
  # (6) Correct for Multiple Comparisons for Hypothesis 1
  #########################################################
  allGroups <- unique(Estimates$t_group)
  allGroups <- allGroups[!is.na(allGroups)]
  
  for (i_group in allGroups) {
    idx <- !is.na(Estimates$t_group) & Estimates$t_group == i_group
    nrTests <- sum(idx, na.rm = TRUE)
    Estimates$p_adj[idx] <- p.adjust(Estimates$p_Value[idx], method = tolower(choice), n = nrTests)
  }
  
  #########################################################
  # (6) Export as CSV file
  #########################################################
  FileName= input$stephistory[["Final_File_Name"]]
  write.csv(Estimates,FileName, row.names = FALSE)
  
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = Estimates,
    stephistory = stephistory
  ))
}
