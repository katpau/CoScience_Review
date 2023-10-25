Determine_Significance = function(input = NULL, choice = NULL) {
  StepName = "Determine_Significance"
  Choices = c( "None")
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
  # (4) Test State Hypothesis (H1)
  # (5) Test Interaction with Personality in preparation for H2
  # (6) Prepare which Data should be compared to Resting (could be either AV across all Condition1s or Condition1 with strongest correlation)
  # (7) Compare Association to Personality for different Phases and Tasks
  # (8) Correct for Multiple Comparisons for Hypothesis 1 and Combine all Estimates
  # (9) Export as CSV file
  
  
  
  
  #########################################################
  # (1) Get Names and Formulas of variable Predictors
  #########################################################
  # Names are used to select relevant columns
  # Formula (parts) are used to be put together and parsed to the lm() function,
  # thats why they have to be added by a * or +
  
  # Get column Names for Personality Data (to to be used in the model formula)
  Depression = paste0("Personality_", unlist(input$stephistory["Depression"]))
  RewardSensitivity = paste0("Personality_", unlist(input$stephistory["RewardSensitivity"]))
  Anhedonia = "Personality_PDI5_Anhedonia"
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
                                   collumns_to_keep,  Component, SaveUseModel, ModelProvided) {
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
    # AnalysisPhase lists the analysis phase included in this test, array of str
    # SaveUseModel, can be added or left out, options are 
    #           "default" (Model is calculated), 
    #           "exportModel", then model (not estimates) are returned (and Effect of interest and Name_Test are not used)
    #           "previousModel", then model is not recalculated but the provided one is used
    
    # ModelProvided only needed if SaveUseModel is set to "previousModel", output of lm()
    if(missing(SaveUseModel)) { SaveUseModel = "default"  }
    if(missing(ModelProvided)) { ModelProvided = "none"  }
    
    
    # Create Subset
    Subset = Data[Data$Component %in% Component ,
                  names(Data) %in% c("ID", "Epochs", "SME", "EEG_Signal", "Lab", collumns_to_keep)]
    
    # Run Test
    ModelResult = test_Hypothesis_V2( Name_Test,lm_formula, Subset, Effect_of_Interest, SaveUseModel, ModelProvided)
    
    # Test Direction
    if (!SaveUseModel == "exportModel") {
      ModelResult = test_DirectionEffect(DirectionEffect, Subset, ModelResult) 
    }
    
    return(ModelResult)
  }
  
  
  Estimates = data.frame()
  DirectionEffectMain = list("Effect" = "interaction_correlation",
                         "Larger" = c("FB", "Loss"),
                         "Smaller" = c("FB", "Win"))
  DirectionEffectIA = list("Effect" = "interaction2_correlation",
                         "Larger" = c("FB", "Loss"),
                         "Smaller" = c("FB", "Win"),
                         "Interaction" = c("Magnitude", "P0", "P50"))
  collumns_to_keep = c("FB", "Magnitude", Depression, Covariate_Name, additional_Factors_Name, Anhedonia, RewardSensitivity) 
  
  
  
  
  
  
  # Loop Through components
      
  for (Component in c("RewP", "P3")) {
  #########################################################
  # (4) Test Hypothesis 1/3 on RewP / P3
  #########################################################
    print(paste("Test Effect of Depression on ", Component))
    
    DirectionEffectIA$Personality = Depression
    DirectionEffectMain$Personality = Depression
  
  lm_formula =   paste( "EEG_Signal ~ (( FB * Magnitude *", Depression,  ")", 
                        additional_Factor_Formula, ")", Covariate_Formula)
  
  
  HX1_Model =  wrap_test_Hypothesis("",lm_formula, output, "",
                                   "", collumns_to_keep, Component,
                                   "exportModel")

  # Main Effect of FB
  Effect_of_Interest = c("FB", Depression)
  Name_Test = paste0(Component, "_FB_Depression")
  Estimates = rbind(Estimates,
                    wrap_test_Hypothesis(Name_Test,lm_formula, output,
                              Effect_of_Interest,  DirectionEffectMain, 
                              collumns_to_keep,  Component,
                              "previousModel", HX1_Model))
  
  # IA FB and Magnitude
  Effect_of_Interest = c("FB", "Magnitude", Depression)
  Name_Test = paste0(Component, "_FB_Magnitude_Depression")

  Estimates = rbind(Estimates, 
                    wrap_test_Hypothesis(Name_Test,lm_formula, output,
                              Effect_of_Interest,  DirectionEffectIA, 
                              collumns_to_keep,  Component,
                              "previousModel", HX1_Model))
  
  #########################################################
  # (4) Test Hypothesis 2/4  on RewP / P3
  #########################################################
  print(paste("Test Effect of Anhedonia/RewardSenssitivity on ", Component))
  
  lm_formula =   paste( "EEG_Signal ~ (( FB * Magnitude ", "*", Depression, ") +", 
                        " ( FB * Magnitude *", Anhedonia, ") +",
                        " ( FB * Magnitude *", RewardSensitivity, ")", 
                        additional_Factor_Formula, ")", Covariate_Formula)
  collumns_to_keep = c("FB", "Magnitude", Depression, Anhedonia, RewardSensitivity,
                       Covariate_Name, additional_Factors_Name) 
  
  HX2_Model =  wrap_test_Hypothesis("",lm_formula, output, "",
                                    "", collumns_to_keep, Component,
                                    "exportModel")
  
  # Effect of Anhedonia - Main
  DirectionEffectIA$Personality = Anhedonia
  DirectionEffectMain$Personality = Anhedonia
  
  Effect_of_Interest = c("FB", Anhedonia)
  Name_Test = paste0(Component, "_FB_Anhedonia")
  Estimates = rbind(Estimates,
                    wrap_test_Hypothesis(Name_Test,lm_formula, output,
                                         Effect_of_Interest,  DirectionEffectMain, 
                                         collumns_to_keep,  Component,
                                         "previousModel", HX2_Model))
  
  # Effect of Anhedonia - IA
  Effect_of_Interest = c("FB", "Magnitude", Depression)
  Name_Test = paste0(Component, "_FB_Magnitude_Anhedonia")
  Estimates = rbind(Estimates, 
                    wrap_test_Hypothesis(Name_Test,lm_formula, output,
                                         Effect_of_Interest,  DirectionEffectIA, 
                                         collumns_to_keep,  Component,
                                         "previousModel", HX2_Model))
  
  # Effect of RewardSensitivity  - Main
  DirectionEffectIA$Personality = RewardSensitivity
  DirectionEffectMain$Personality = RewardSensitivity
  
  Effect_of_Interest = c("FB", RewardSensitivity)
  Name_Test = paste0(Component, "_FB_RewardSensitivity")
  Estimates = rbind(Estimates,
                    wrap_test_Hypothesis(Name_Test,lm_formula, output,
                                         Effect_of_Interest,  DirectionEffectMain, 
                                         collumns_to_keep,  Component,
                                         "previousModel", HX2_Model))
  
  # Effect of RewardSensitivity - IA
  Effect_of_Interest = c("FB", "Magnitude", RewardSensitivity)
  Name_Test = paste0(Component, "_FB_Magnitude_RewardSensitivity")
  Estimates = rbind(Estimates, 
                    wrap_test_Hypothesis(Name_Test,lm_formula, output,
                                         Effect_of_Interest,  DirectionEffectIA, 
                                         collumns_to_keep,  Component,
                                         "previousModel", HX2_Model))
  
  

  }
  
  #### For Exploratory Hypothesis Add Behav_StateSadness - Problem when interaction with Covariate
  # so it cannot be added to loop above... Drop Covariate and/or figure out problem
  # To be added, similar as above 
  
  print(paste("Test Effect of State Sadness on ", Component))
  DirectionEffectIA$Personality = Depression
  DirectionEffectMain$Personality = Depression
  collumns_to_keep = c(collumns_to_keep, "Behav_StateSadness")
  lm_formula =   paste( "EEG_Signal ~ (( FB * Magnitude *", Depression,  "* Behav_StateSadness)", 
                        additional_Factor_Formula, ")" ) # what about covariate???
  
  
  HX1_Model =  wrap_test_Hypothesis("",lm_formula, output, "",
                                    "", collumns_to_keep, Component,
                                    "exportModel")
  
  # Main Effect of FB
  Effect_of_Interest = c("FB", Depression, "Behav_StateSadness")
  Name_Test = paste0(Component, "_FB_Depression_StateSadness")
  Estimates = rbind(Estimates,
                    wrap_test_Hypothesis(Name_Test,lm_formula, output,
                                         Effect_of_Interest,  DirectionEffectMain, 
                                         collumns_to_keep,  Component,
                                         "previousModel", HX1_Model))
  
  #########################################################
  # (8) Correct for Multiple Comparisons for Hypothesis 1
  #########################################################

  # No Correction
  
  
  #########################################################
  # (9) Export as CSV file
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
