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
  
  
  # Get possible additional factors to be included in the GLM (depends on the forking
  # these have been determined at earlier step (Covariate) when determining the grouping variables)
  #additional_Factors_Name = input$stephistory[["additional_Factors_Name"]]
  #additional_Factor_Formula = input$stephistory[["additional_Factor_Formula"]]
  # not sure but always three electrodes?
  additional_Factors_Name = "Electrode"
  additional_Factor_Formula = "+ Electrode"
  
  # merge GMA and Component collumn
  output$Component[output$Component == "Ne/c"] = as.character(output$GMA_Measure[output$Component == "Ne/c"])
  #########################################################
  # (2) Initiate Functions for Hypothesis Testing
  #########################################################
  wrap_test_Hypothesis = function (Name_Test,lm_formula,  Data, Component, Task, Effect_of_Interest, DirectionEffect,
                                   columns_to_keep,   SaveUseModel, ModelProvided) {
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
    # Effect_of_Interest is used to identify which estimate should be exported, array of str.
    #             the effect is extended by any potential additional factors (hemisphere, electrode...)
    # DirectionEffect is a list with the following named elements:
    #               Effect - char to determine what kind of test, either main, interaction, correlation, interaction_correlation, interaction2_correlation
    #               Personality - char name of personality collumn
    #               Larger - array of 2 chars: first name of collumn coding condition, second name of factor with larger effect
    #               Smaller - array of 2 chars: first name of collumn coding condition, second name of factor with smaller effect
    #               Interaction - array of 3 chars: first name of collumn coding condition additional to Larger/Smaller, second name of factor with smaller effect, third with larger effect
    # columns_to_keep lists all collumns that should be checked for completeness, array of str
    # Task lists the tasks included in this test, array of str
    # SaveUseModel, can be added or left out, options are 
    #           "default" (Model is calculated), 
    #           "exportModel", then model (not estimates) are returned (and Effect of interest and Name_Test are not used)
    #           "previousModel", then model is not recalculated but the provided one is used
    
    # ModelProvided only needed if SaveUseModel is set to "previousModel", output of lm()
    if(missing(SaveUseModel)) { SaveUseModel = "default"  }
    if(missing(ModelProvided)) { ModelProvided = "none"  }
    
    
    # Create Subset
    Subset = Data[Data$Component == Component &
                    Data$Task == Task,
                  names(Data) %in% c("ID", "Lab", "Epochs", "SME", "Component", columns_to_keep)]
    
    # Run Test
    ModelResult = test_Hypothesis( Name_Test,lm_formula, Subset, Effect_of_Interest, SaveUseModel, ModelProvided)
    
    # Test Direction
    if (!SaveUseModel == "exportModel") {
      ModelResult = test_DirectionEffect(DirectionEffect, Subset, ModelResult) 
    }
    
    return(ModelResult)
  }
  
  
  Estimates = data.frame()
  #########################################################
  # (3) Main Effects of Accuracy for different Tasks
  #########################################################
  Names_GMA = c("rate",   "excess" ,"shape"  ,"skewness"  , "inflection1", "scaling", "inflection2")
  GMA_colnames = c("rate",   "excess" ,"shape"  ,"skew"  , "ip1_ms", "yscale", "ip2_ms")
  columns_to_keep = c("Condition", Covariate_Name, additional_Factors_Name,  "GMA_Measure", "EEG_Signal")
  Effect_of_Interest = "Condition"
  lm_formula =   paste( "EEG_Signal ~  Condition ", Covariate_Formula, additional_Factor_Formula)
  # Electrode Fix or possible?
  DirectionEffect_larger = list("Effect" = "main",
                         "Larger" = c("Condition", "error"),
                         "Smaller" = c("Condition", "correct"))
  DirectionEffect_smaller= list("Effect" = "main",
                                "Larger" = c("Condition", "correct"),
                                "Smaller" = c("Condition", "error"))
  
  for (i_GMA in 1:length(Names_GMA)) {
    for (i_task in c("GoNoGo", "Flanker")) {
    print(paste("Test ", i_task, Names_GMA[i_GMA]))
    Name_Test = paste0("Accuracy_", Names_GMA[i_GMA], "_", i_task)
    if (Names_GMA[i_GMA] %in% c("shape", "rate", "inflection1")) {
      DirectionEffect = DirectionEffect_larger
    } else {
      DirectionEffect = DirectionEffect_smaller
    }
    
   Estimates = rbind(Estimates,  
                     wrap_test_Hypothesis(Name_Test,lm_formula, output, GMA_colnames[i_GMA], i_task,
                         Effect_of_Interest,
                         DirectionEffect, columns_to_keep))
    
  }}
  

  

  #########################################################
  # (4) Personality Effect
  #########################################################
  
  for (i_Personality in c("Personality_MPS_PersonalStandards","Personality_MPS_ConcernOverMistakes")) {
    columns_to_keep = c("Condition", Covariate_Name, i_Personality, additional_Factors_Name, "EEG_Signal")
    
    DirectionEffect_Main = list("Effect" = "correlation",
                              "Personality" = i_Personality)
    
    DirectionEffect_IA = list("Effect" = "interaction_correlation",
                                "Larger" = c("Condition", "error"),
                                "Smaller" = c("Condition", "correct"),
                                "Personality" = i_Personality)
    
    lm_formula =   paste( "EEG_Signal ~  Condition * ", i_Personality,  Covariate_Formula, additional_Factor_Formula)
    
   for (i_GMA in 1:length(Names_GMA)) {
     
    for (i_task in c("GoNoGo", "Flanker")) {

      print(paste("Test ", i_Personality, i_task, Names_GMA[i_GMA]))
      Name_Test = paste0(i_Personality, "_", Names_GMA[i_GMA], "_", i_task)

      
      Model = wrap_test_Hypothesis("",lm_formula, output, GMA_colnames[i_GMA], i_task,
                                             "","", columns_to_keep,
                                             "exportModel")
      
      # Test main Effect   
      Estimates = rbind(Estimates, wrap_test_Hypothesis(paste0("Main_", Name_Test),
                                                        lm_formula, output, GMA_colnames[i_GMA], i_task,
                                                        i_Personality,
                                                        DirectionEffect_Main, columns_to_keep, 
                                                        "previousModel", Model))
      
      # Test main Effect of CEI  
      Estimates = rbind(Estimates, wrap_test_Hypothesis(paste0("Interaction_", Name_Test),
                                                        lm_formula, output, GMA_colnames[i_GMA], i_task,
                                                        c("Condition", i_Personality),
                                                        DirectionEffect_IA, columns_to_keep, 
                                                        "previousModel", Model))
      
    }}
}
  
  
  #########################################################
  # (5) Personality Effect on Behaviour
  #########################################################
  Estimates_behav = data.frame()
  for (i_Personality in c("Personality_MPS_PersonalStandards","Personality_MPS_ConcernOverMistakes")) {
    columns_to_keep = c("Condition", Covariate_Name, i_Personality,  "Behav")
    
    DirectionEffect_Main = list("Effect" = "correlation",
                                "Personality" = i_Personality,
                                "DV" = "Behav")
    
    lm_formula =   paste( "Behav ~  Condition * ", i_Personality,  Covariate_Formula)
    
    for (i_Behav in c("RTDiff", "post_ACC")) {
      for (i_task in c("GoNoGo", "Flanker")) {
        
        print(paste("Test ", i_Personality, i_task, i_Behav))
        Name_Test = paste0(i_Personality, "_", i_Behav, "_", i_task)
        
        
        Estimates_behav = rbind(Estimates_behav,
                          wrap_test_Hypothesis(paste0("Main_", Name_Test),
                                     lm_formula, output, i_Behav, i_task,
                                     i_Personality,
                                     DirectionEffect_Main, columns_to_keep))
  
      }}
  }
  
  
  
  
  #########################################################
  # (6) Correct for Multiple Comparisons for Hypothesis 1
  #########################################################
  for (i_task in c("GoNoGo", "Flanker")) {
    for (i_Test in c("Accuracy", "Main|Interaction")) {
      if (i_Test == "Accuracy") {nrTests = 7} else {nrTests = 28} # Two tests and two Personalities?
      Idx = grepl(i_Test, Estimates$Effect_of_Interest) &
        grepl(i_task, Estimates$Effect_of_Interest)
      Estimates$p_Value[Idx] = p.adjust(Estimates$p_Value[Idx],
                                       method = tolower(choice), n = nrTests)
      
    }
  }
  # Add behavioural ones without correction?
  Estimates = rbind(Estimates, Estimates_behav)
  
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
