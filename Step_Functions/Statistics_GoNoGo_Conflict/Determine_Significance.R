Determine_Significance = function(input = NULL, choice = NULL) {
  StepName = "Determine_Significance"
  Choices = c("Holm", "Bonferroni", "FDR", "None")
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
  # (3) Prepare Averages across Condition1s and Correlations
  # (4) Test Hypothesis 1 
  # (5) Test State Effects
  # (6) Manipulation Checks
  # (7) Correct for Multiple Comparisons for Hypothesis 1 and Combine all Estimates
  # (8) Export as CSV file
  
  
  
  
  #########################################################
  # (1) Get Names and Formulas of variable Predictors
  #########################################################
  # Names are used to select relevant columns
  # Formula (parts) are used to be put together and parsed to the lm() function,
  # thats why they have to be added by a * or +
  
  # Get column Names for Personality Data (to to be used in the model formula)
  Personality_collumns = names(output)[names(output) %like% "Personality_"]
  Personality_Name = Personality_collumns[Personality_collumns %in% Personality_collumns]
  Personality_Name = Personality_Name[!grepl("Personality_RSTPQ_Flight",Personality_Name)] # keep Anxious Apprehension seperate
  Personality_Formula = paste("* ", Personality_Name)
  
  # Get column Names for Behavioural Data
  Behavior_Name = names(output)[names(output) %like% "Behav_"]
  # Behavior Formula is built later
  
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
                                   collumns_to_keep, Condition_Type, Component, SaveUseModel, ModelProvided) {
    # wrapping function to parse specific Information to the test_Hypothesis Function
    # Does three things: (1) Select Subset 
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
    # Component lists the Component included in this test, array of str
    # AnalysisPhase lists the analysis phase included in this test, array of str
    # SaveUseModel, can be added or left out, options are 
    #           "default" (Model is calculated), 
    #           "exportModel", then model (not estimates) are returned (and Effect of interest and Name_Test are not used)
    #           "previousModel", then model is not recalculated but the provided one is used
    
    # ModelProvided only needed if SaveUseModel is set to "previousModel", output of lm()
    if(missing(SaveUseModel)) { SaveUseModel = "default"  }
    if(missing(ModelProvided)) { ModelProvided = "none"  }
    
    
    # Create Subset
    Subset = Data[Data$Condition_Type %in% Condition_Type &
                    Data$Component %in% Component ,
                  names(Data) %in% c("ID", "Epochs", "SME", "EEG_Signal", "Lab", collumns_to_keep)]
    
    # Run Test
    ModelResult = test_Hypothesis( Name_Test,lm_formula, Subset, Effect_of_Interest, SaveUseModel, ModelProvided)
    
    # Test Direction
    if (!SaveUseModel == "exportModel") {
      ModelResult = test_DirectionEffect(DirectionEffect, Subset, ModelResult) 
    }
    
    return(ModelResult)
  }
  
  
  
  #########################################################
  # (4) Test Hypothesis 1 
  #########################################################
  print("Test Effect of Anxiety and Instruction on N2")
  lm_formula =   paste( "EEG_Signal ~ (( Condition_Instruction ", 
                        Personality_Formula, ")", additional_Factor_Formula, ")", Covariate_Formula)
  collumns_to_keep = c("Condition_Instruction", Personality_Name, Covariate_Name, additional_Factors_Name) 
  Condition_Type = c("Diff")
  Component = "N2"
  
  Effect_of_Interest = c("Condition_Instruction",  Personality_Name)
  Name_Test = c("N2_Apprehension")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Condition_Instruction", "Relaxed"),
                         "Smaller" = c("Condition_Instruction", "Speed"),
                         "Personality" = Personality_Name)
  
  
  H1_1 = wrap_test_Hypothesis(Name_Test,lm_formula, output,
                              Effect_of_Interest,  DirectionEffect, 
                              collumns_to_keep, Condition_Type, Component)
  
  
  #########################################################
  # (5) Test State Effects
  #########################################################
  print("Test Effect of Anxiety and Instruction on N2 controlling for Arousal")
  Name_Test = c("N2_Apprehension_controllingArousal")
  lm_formula =   paste( "EEG_Signal ~ (( Condition_Instruction  ", 
                        Personality_Formula, "* StateAnxiety)", additional_Factor_Formula, ")", Covariate_Formula)
  collumns_to_keep = c("Condition_Instruction", Personality_Name, "StateAnxiety", Covariate_Name, additional_Factors_Name) 
  Component = "N2"
  
  
  
  H1_2 = wrap_test_Hypothesis(Name_Test,lm_formula, output,
                              Effect_of_Interest,  DirectionEffect, 
                              collumns_to_keep, Condition_Type, Component)
  
  
  #########################################################
  # (5) Test Hypothesis 2
  #########################################################
  
  print("Test Effect of Anxiety and Instruction on Worry")
  Name_Test = c("Worry_Instruction_Anxiety")
  lm_formula =   paste( "StateAnxiety ~ ( Condition_Instruction  * ", Personality_Name, ")", Covariate_Formula)
  collumns_to_keep = c("Condition_Instruction", Personality_Name, "StateAnxiety", Covariate_Name, additional_Factors_Name) 
  Component = "N2"
  Condition_Type = c("Diff")
  Effect_of_Interest = c("Condition_Instruction",  Personality_Name)
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Condition_Instruction", "Relaxed"),
                         "Smaller" = c("Condition_Instruction", "Speed"),
                         "Personality" = Personality_Name,
                         "DV" = "StateAnxiety")
  
  H2_1 = wrap_test_Hypothesis(Name_Test,lm_formula, output,
                              Effect_of_Interest,  DirectionEffect, 
                              collumns_to_keep, Condition_Type, Component)
  
  
  
  # To be added Worry ~ Instruction  * only NoGo N2   (? or t-tests?)
  print("Test Effect of N2 and Instruction on Worry")
  Name_Test = c("Worry_Instruction_N2")
  lm_formula =   paste( "StateAnxiety ~ ( Condition_Instruction  * EEG_Signal)", Covariate_Formula)
  collumns_to_keep = c("Condition_Instruction", "EEG_Signal", "StateAnxiety", Covariate_Name, additional_Factors_Name) 
  Component = "N2"
  Condition_Type = c("Diff")
  Effect_of_Interest = c("Condition_Instruction",  "EEG_Signal")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Condition_Instruction", "Relaxed"),
                         "Smaller" = c("Condition_Instruction", "Speed"),
                         "Personality" = "EEG_Signal",
                         "DV" = "StateAnxiety")
  
  H2_2 = wrap_test_Hypothesis(Name_Test,lm_formula, output,
                              Effect_of_Interest,  DirectionEffect, 
                              collumns_to_keep, Condition_Type, Component)
  

  
  #########################################################
  # (6) Manipulation Checks
  #########################################################
  print("Test Effect Manipulation Checks N2")
  Condition_Type = c("Go", "NoGo")
  Effect_of_Interest = c("Condition_Type")
  Name_Test = c("N2_GoCondition")
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Condition_Type", "Go"),
                         "Smaller" = c("Condition_Type", "NoGo")) # Larger means more positive!
  collumns_to_keep = c("Condition_Instruction", "Condition_Type", Personality_Name, "StateAnxiety", Covariate_Name, additional_Factors_Name) 
  Component = "N2"
  lm_formula =   paste( "EEG_Signal ~ (( Condition_Type * Condition_Instruction))", Covariate_Formula)
  H3_1 = wrap_test_Hypothesis(Name_Test,lm_formula, output,
                              Effect_of_Interest,  DirectionEffect, 
                              collumns_to_keep, Condition_Type, Component)
  
  ###############################################
  print("Test Effect Manipulation Checks RT")
  collumns_to_keep = c("Condition_Instruction", Personality_Name, "StateAnxiety", Covariate_Name, additional_Factors_Name) 
  Condition_Type = c("Go")
  Effect_of_Interest = c("Condition_Instruction")
  Name_Test = c("RT_Instructions")
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Condition_Instruction", "Relaxed"),
                         "Smaller" = c("Condition_Instruction", "Speed"),
                         "DV" = "Behav_RT")
  
  lm_formula =   paste( "Behav_RT ~ (( Condition_Instruction))", Covariate_Formula)
  collumns_to_keep = c("Condition_Instruction", "Behav_RT", Covariate_Name, additional_Factors_Name) 
  Component = "RT"
  H3_3 = wrap_test_Hypothesis(Name_Test,lm_formula, output,
                              Effect_of_Interest,  DirectionEffect, 
                              collumns_to_keep, Condition_Type, Component)
  
  ###############################################
  print("Test Effect Manipulation Checks N2")
  Name_Test = c("NoGoDiff_Instructions")
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Condition_Instruction", "Speed"),
                         "Smaller" = c("Condition_Instruction", "Relaxed"))
  Component = "N2"
  Condition_Type = "Diff"
  lm_formula =   paste( "EEG_Signal ~ (( Condition_Instruction)", additional_Factor_Formula, ")", Covariate_Formula)
  collumns_to_keep = c("Condition_Instruction",  Covariate_Name, additional_Factors_Name) 
  H3_4 = wrap_test_Hypothesis(Name_Test,lm_formula, output,
                              Effect_of_Interest,  DirectionEffect, 
                              collumns_to_keep, Condition_Type, Component)
  
  ###############################################
  print("Test Effect Manipulation Checks Worry")
  Name_Test = c("Worry_Instructions")
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Condition_Instruction", "Speed"),
                         "Smaller" = c("Condition_Instruction", "Relaxed"),
                         "DV" = "StateAnxiety")
  Component = "N2"
  Condition_Type = "Diff"
  lm_formula =   paste( "StateAnxiety ~  (Condition_Instruction)", Covariate_Formula)
  collumns_to_keep = c("Condition_Instruction",  Covariate_Name, "StateAnxiety") 
  H3_2 = wrap_test_Hypothesis(Name_Test,lm_formula, output,
                              Effect_of_Interest,  DirectionEffect, 
                              collumns_to_keep, Condition_Type, Component)    
  
  #########################################################
  # (7) Correct for Multiple Comparisons for Hypothesis 1
  #########################################################
  
  Estimates_to_Correct = as.data.frame(rbind(H3_2, H3_3, H3_4)) # add estimates from manipulation check
  comparisons = sum(!is.na(Estimates_to_Correct$p_Value))
  
  if (choice == "Holm"){
    Estimates_to_Correct$p_Value = p.adjust(Estimates_to_Correct$p_Value, method = "holm", n = comparisons)
  }  else if (choice == "Bonferroni"){
    Estimates_to_Correct$p_Value = p.adjust(Estimates_to_Correct$p_Value, method = "bonferroni", n = comparisons)
  } else if (choice == "FDR"){
    Estimates_to_Correct$p_Value = p.adjust(Estimates_to_Correct$p_Value, method = "fdr", n = comparisons)
  }
  
  
  Estimates = rbind(Estimates_to_Correct,
                    H1_1 , H2_1, H2_2 ) # Add other estimates here
  
  
  #########################################################
  # (8) Export as CSV file
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
