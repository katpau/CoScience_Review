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
  # (3) Test RT Effect
  # (4) Compare LRP/MVPA
  # (5) Test Intercept 
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
  

   
  
  #########################################################
  # (2) Initiate Functions for Hypothesis Testing
  #########################################################
  wrap_test_Hypothesis = function (Name_Test,lm_formula,  Data, Effect_of_Interest, DirectionEffect,
                                   collumns_to_keep,   SaveUseModel, ModelProvided) {
    # wrapping function to parse specific Information to the test_Hypothesis Function
    # Does three things: (1) Select Subset depending on Conditions and Tasks ans Analysis Phase
    # (2) Test the Hypothesis/Calculate Model and 
    # (3) Checks the direction of the effects
    # Inputs:
    # Name_Test is the Name that will be added as first collumn, to identify tests across forks, str (next to the actual interaction term)
    # lm_formula contains the formula that should be given to the lm, str
    # Data contains data (that will be filtered), df
    # Effect_of_Interest is used to identify which estimate should be exported, array of str.
    #             the effect is extended by any potential additional factors (hemisphere, electrode...)
    # DirectionEffect is a list with the following named elements:
    #               Effect - char to determine what kind of test, either main, interaction, correlation, interaction_correlation, interaction2_correlation
    #               Personality - char name of personality collumn
    #               Larger - array of 2 chars: first name of collumn coding condition, second name of factor with larger effect
    #               Smaller - array of 2 chars: first name of collumn coding condition, second name of factor with smaller effect
    #               Interaction - array of 3 chars: first name of collumn coding condition additional to Larger/Smaller, second name of factor with smaller effect, third with larger effect
    # collumns_to_keep lists all collumns that should be checked for completeness, array of str
    # Task lists the tasks included in this test, array of str
    # SaveUseModel, can be added or left out, options are 
    #           "default" (Model is calculated), 
    #           "exportModel", then model (not estimates) are returned (and Effect of interest and Name_Test are not used)
    #           "previousModel", then model is not recalculated but the provided one is used
    
    # ModelProvided only needed if SaveUseModel is set to "previousModel", output of lm()
    if(missing(SaveUseModel)) { SaveUseModel = "default"  }
    if(missing(ModelProvided)) { ModelProvided = "none"  }
    
    
    # Create Subset
    Subset = Data[,
                  names(Data) %in% c("ID", "Epochs", "SME", "EEG_Signal", collumns_to_keep)]
    
    # Run Test
    ModelResult = test_Hypothesis( Name_Test,lm_formula, Subset, Effect_of_Interest, SaveUseModel, ModelProvided)
    
    # Test Direction
    if (!SaveUseModel == "exportModel") {
      ModelResult = test_DirectionEffect(DirectionEffect, Subset, ModelResult) 
    }
    
    return(ModelResult)
  }
  
  
  
  #########################################################
  # (3) Test RT Effect
  #########################################################
  print("Test RT")
  Name_Test = "RT_Condition"
  lm_formula =   paste( "Behav_RT ~  Condition ", Covariate_Formula)
  collumns_to_keep = c("Condition", "Behav_RT", Covariate_Name)
  Effect_of_Interest = "Condition"
  DirectionEffect = list("Effect" = "main",
                            "Larger" = c("Condition", "Error"),
                            "Smaller" = c("Condition", "Correct"),
                            "DV" = "Behav_RT")
  
  
  H1F =   wrap_test_Hypothesis(Name_Test,lm_formula, output[output$Component == "RTs" &
                                                             output$Task == "Flanker" ,], 
                              Effect_of_Interest,
                              DirectionEffect, collumns_to_keep)
  
  H1G =   wrap_test_Hypothesis(Name_Test,lm_formula, output[output$Component == "RTs" &
                                                             output$Task == "GoNoGo" ,], 
                              Effect_of_Interest,
                              DirectionEffect, collumns_to_keep)
  
  

  #########################################################
  # (4) Compare LRP/MVPA
  #########################################################
  print("Test RT")
  Name_Test = "Onset_Component"
  lm_formula =   paste( "EEG_Signal ~  (Condition * Component)", Covariate_Formula)
  collumns_to_keep = c("Condition", "Component", Covariate_Name)
  Effect_of_Interest = "Component"
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Component", "LRP"),
                         "Smaller" = c("Component", "MVPA"))
  
  
  H2F =   wrap_test_Hypothesis(Name_Test,lm_formula, output[!(output$Component %in% "RTs") &
                                                              output$Task == "Flanker" ,], 
                               Effect_of_Interest,
                               DirectionEffect, collumns_to_keep)
  
  H2G =   wrap_test_Hypothesis(Name_Test,lm_formula, output[!(output$Component %in% "RTs") &
                                                              output$Task == "GoNoGo" ,], 
                               Effect_of_Interest,
                               DirectionEffect, collumns_to_keep)
  
  
  
  
  
  #########################################################
  # (5) Get Intercept to test if MVPA different than 0
  #########################################################
  
  
  
  #########################################################
  # (5) Correct for Multiple Comparisons for Hypothesis 1
  #########################################################
  
  # No Correction
  Estimates = rbind(H1F, H1G, H2F, H2G)
  
  
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
