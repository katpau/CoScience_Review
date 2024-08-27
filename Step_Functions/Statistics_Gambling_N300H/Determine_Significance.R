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
  # (3) Prepare Model
  # (4) Test  Hypothesis 1-3 
  # (5) Correct for Multiple Comparisons for Hypothesis 1 and Combine all Estimates
  # (6) Export as CSV file
  
  
  
  
  #########################################################
  # (1) Get Names and Formulas of variable Predictors
  #########################################################
  # Names are used to select relevant columns
  # Formula (parts) are used to be put together and parsed to the lm() function,
  # thats why they have to be added by a * or +
  
  # Get column Names for Personality Data (to to be used in the model formula)
  Anxiety = paste0("Personality_", unlist(input$stephistory["Personality_Variable"]))

  
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
  # if e.g. no difference scores were calculated, then hemisphere should be added.
  # these have been determined at earlier step (Covariate) when determining the grouping variables)
  additional_Factors_Name = input$stephistory[["additional_Factors_Name"]]
  additional_Factor_Formula = input$stephistory[["additional_Factor_Formula"]]
  
  
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
    # SaveUseModel, can be added or left out, options are 
    #           "default" (Model is calculated), 
    #           "exportModel", then model (not estimates) are returned (and Effect of interest and Name_Test are not used)
    #           "previousModel", then model is not recalculated but the provided one is used
    
    # ModelProvided only needed if SaveUseModel is set to "previousModel", output of lm()
    if(missing(SaveUseModel)) { SaveUseModel = "default"  }
    if(missing(ModelProvided)) { ModelProvided = "none"  }
    
    
    # Create Subset
    Subset = Data[,
                  names(Data) %in% c("ID", "Epochs", "SME", "EEG_Signal", "Lab", collumns_to_keep)]
    
    # Run Test
    ModelResult = test_Hypothesis( Name_Test,lm_formula, Subset, Effect_of_Interest, SaveUseModel, ModelProvided)

   
    # Test Direction
    if (!SaveUseModel == "exportModel") {
      if (!is.na(ModelResult$value_EffectSize)) { 
      ModelResult = test_DirectionEffect(DirectionEffect, Subset, ModelResult) 
    }}
    
    return(ModelResult)
  }
  
  
  
  #########################################################
  # (3) Prepare Model
  #########################################################
  print("Create Model")
  lm_formula =   paste( "EEG_Signal ~ (( Condition *", Anxiety,  ")", 
                      additional_Factor_Formula, ")", Covariate_Formula)
  collumns_to_keep = c(Anxiety, "Condition", Covariate_Name, additional_Factors_Name)
  
  HX_Model =  wrap_test_Hypothesis("",lm_formula, output, "",
                                    "", collumns_to_keep, 
                                    "exportModel")
    

  #########################################################
  # (4) Test Hypothesis 1-3 
  #########################################################
  # Test Anxiety 
  DirectionEffect = list("Effect" = "correlation",
                         "Personality" = Anxiety)
  Effect_of_Interest = c( Anxiety)
  Name_Test = "Anxiety"
  Estimates = wrap_test_Hypothesis(Name_Test,lm_formula, output,
                                   Effect_of_Interest,  DirectionEffect, 
                                   collumns_to_keep,  
                                   "previousModel", HX_Model)
  
  # Test Anxiety * FB
  DirectionEffect = list("Effect" = "interaction_correlation",
                          "Larger" = c("Condition", "loss"),  # Should only be loss and win?
                          "Smaller" = c("Condition", "win"),
                          "Personality" = Anxiety)
  Effect_of_Interest = c( Anxiety, "Condition")
  Name_Test = "Anxiety_Condition"
  Estimates = rbind(Estimates, 
                    wrap_test_Hypothesis(Name_Test,lm_formula, output,
                                   Effect_of_Interest,  DirectionEffect, 
                                   collumns_to_keep,  
                                   "previousModel", HX_Model))
  
  
  # Test Intercept?
  if (is.character(HX_Model)) {
  Intercept =  cbind("Confirmation_N300H", "Intercept", "NA", "NA", "NA", "NA", 
                       "NA", Estimates[1,8:12],
                       "NA", "NA", "NA", "Intercept", "NA", "NA", "NA", "NA", "NA") 
  } else {
  Intercept = summary(HX_Model)$"coefficients"[1,]
  Intercept =  cbind("Confirmation_N300H", "Intercept", "NA", "NA", "NA", "NA", 
                     "NA", Estimates[1,8:12],
                     "NA", "NA", "NA", "Intercept", t(Intercept))  
  
  }
  colnames(Intercept) = colnames(Estimates)
  Estimates = rbind(Estimates, 
                    Intercept)
  
  # no Hypothesis but important to report
  # Test Anxiety * FB
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Condition", "loss"),  
                         "Smaller" = c("Condition", "win"))
  Effect_of_Interest = c("Condition")
  Name_Test = "Condition"
  Estimates = rbind(Estimates, 
                    wrap_test_Hypothesis(Name_Test,lm_formula, output,
                                         Effect_of_Interest,  DirectionEffect, 
                                         collumns_to_keep,  
                                         "previousModel", HX_Model))
  

  #########################################################
  # (5) Correct for Multiple Comparisons for Hypothesis 1
  #########################################################

  # No Correction
  
  
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
