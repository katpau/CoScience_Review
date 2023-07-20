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
  # (3) Test Hypothesis 1.1 + 2.1, effects on Acceptance Rate
  # (4) Test Hypothesis 1.2 + 2.2, effects on FRN
  # (5) Test Hypothesis 3, effects on RT
  # (6) No control for multiple comparisons
  # (7) Export as CSV file
  
  
  
  
  #########################################################
  # (1) Get Names and Formulas of variable Predictors
  #########################################################
  # Names are used to select relevant columns
  # Formula (parts) are used to be put together and parsed to the lm() function,
  # thats why they have to be added by a * or +
  # rename Age
  colnames(output)[colnames(output) == "Covariate_Age"] = "Personality_Age"
  
  # Get column Names and Formula for Covariates
  if (input$stephistory["Covariate"] == "None") { 
    Covariate_Formula = ""
    Covariate_Name = vector()
  } else if (input$stephistory["Covariate"] == "Gender_MF") { 
    Covariate_Formula = "+ Covariate_Gender"
    Covariate_Name = "Covariate_Gender"
  } else { 
    Covariate_Name = names(output)[names(output) %like% "Covariate_"]
    # Drop Age!
    Covariate_Name  = Covariate_Name[!grepl("Age", Covariate_Name)]
    if (length(Covariate_Name)  > 1) {
      Covariate_Formula = paste("*(", paste(Covariate_Name, collapse = " + "), ")")
    } else {
      Covariate_Formula = paste( "*", Covariate_Name)
    }
  }
  
  #### Adjust Covariate Formula for the different traits!
  # Covarite Anxiety
  Covariate_Formula_Anxiety = gsub("\\* Covariate_BFI_NegativeEmotionality|\\+ Covariate_BFI_NegativeEmotionality", "", Covariate_Formula)
  # Covarite Anger
  Covariate_Formula_Anger = gsub("\\* Covariate_BFI_NegativeEmotionality|\\+ Covariate_BFI_NegativeEmotionality", "", Covariate_Formula)
  # Covarite Altrusim
  Covariate_Formula_Altruism = gsub("\\* Covariate_BFI_Agreeableness|\\+ Covariate_BFI_Agreeableness", "", Covariate_Formula)
  # Covarite NFC
  Covariate_Formula_NFC = gsub("\\* Covariate_Openness|\\+ Covariate_BFI_Agreeableness", "", Covariate_Formula)
  
  # Get Name of Anxiety Variable
  Anxiety_Variable = paste0("Personality_", input$stephistory["Personality_Variable"])
  
  # Get possible additional factors to be included in the GLM (depends on the forking
  # if e.g. no difference scores were calculated, then hemisphere should be added.
  # these have been determined at earlier step (Covariate) when determining the grouping variables)
  additional_Factors_Name = input$stephistory[["additional_Factors_Name"]]
  additional_Factor_Formula = input$stephistory[["additional_Factor_Formula"]]
  
  
  #########################################################
  # (2) Initiate Functions for Hypothesis Testing
  #########################################################
  wrap_test_Hypothesis = function (Name_Test,lm_formula,  Data, Effect_of_Interest, DirectionEffect,
                                   collumns_to_keep, Component,  SaveUseModel, ModelProvided) {
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
    # Component lists the Component included in this test, array of str
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
    ModelResult = test_Hypothesis( Name_Test,lm_formula, Subset, Effect_of_Interest, SaveUseModel, ModelProvided)
    
    # Test Direction
    if (!SaveUseModel == "exportModel") {
      ModelResult = test_DirectionEffect(DirectionEffect, Subset, ModelResult) 
    }
    
    return(ModelResult)
  }
  
  
  
  #########################################################
  # (3) Test Hypothesis 1.1 + 2.1, effects on Acceptance Rate
  #########################################################
  # Set up for Behav Data
  print("Test Effect on Acceptance Rate")
  Name_Test = "AcceptanceRate_Offer"
  lm_formula =   paste( "Behav_AcceptanceRate ~ ((Offer) ) ", Covariate_Formula)
  collumns_to_keep = c("Offer", Covariate_Name, "Behav_AcceptanceRate") 
  Effect_of_Interest = c("Offer")
  DirectionEffect= list("Effect" = "main",
                            "Larger" = c("Offer", "Offer5"),
                            "Smaller" = c("Offer", "Offer1"),
                            "DV" = "Behav_AcceptanceRate")
  
  Estimates = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                              DirectionEffect, collumns_to_keep, "AcceptanceRate")

  # Test all four Personality Moderators
  Moderators = c("NFC", "Anger", "Altruism" ,"Age", "Anxiety")
  Variables = c(paste0("Personality_", c("NFC_NeedForCognition", "AGG_Anger",  "PTM_Altruism", "Age")), Anxiety_Variable)
  Covariates = c(Covariate_Formula_Anger, Covariate_Formula_NFC, Covariate_Formula_Altruism, Covariate_Formula,  Covariate_Formula_Anxiety)
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Offer", "Offer5"),
                         "Smaller" = c("Offer", "Offer1"),
                         "DV" = "Behav_AcceptanceRate")
  
  for (iTest in 1:length(Moderators)) {
  Name_Test = paste0("AcceptanceRate_Offer_", Moderators[iTest])
  lm_formula =   paste( "Behav_AcceptanceRate ~ ((Offer)" , "*", Variables[iTest],") ", Covariates[iTest])
  collumns_to_keep = c("Offer", Covariate_Name, "Behav_AcceptanceRate", Variables[iTest]) 
  Effect_of_Interest = c("Offer", Variables[iTest] )
  DirectionEffect$Personality = Variables[iTest]
  # For Anxiety other prediction direction
  if (Moderators[iTest] == "Anxiety") {
    DirectionEffect$Larger =  c("Offer", "Offer1")
     DirectionEffect$Smaller =  c("Offer", "Offer5")
  }
  Estimates = rbind(Estimates,
                    wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                              DirectionEffect, collumns_to_keep, "AcceptanceRate"))
  }
  
  
  

  #########################################################
  # (4) Test Hypothesis 1.2 + 2.2, effects on FRN
  #########################################################
  print("Test Effect on FRN")
  Name_Test = "FRN_Offer"
  lm_formula =   paste( "EEG_Signal ~ ((Offer)", additional_Factor_Formula, " ) ", Covariate_Formula)
  collumns_to_keep = c("Offer", Covariate_Name, additional_Factors_Name) 
  Effect_of_Interest = c("Offer")
  DirectionEffect= list("Effect" = "main",
                        "Larger" = c("Offer", "Offer5"),
                        "Smaller" = c("Offer", "Offer1"))
  
  Estimates = rbind(Estimates,
                    wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                              DirectionEffect, collumns_to_keep, "FRN"))
  
  
  # Test all four Personality Moderators
  Moderators = c("NFC", "Anger", "Altruism" ,"Age", "Anxiety")
  Variables = c(paste0("Personality_", c("NFC_NeedForCognition", "AGG_Anger",  "PTM_Altruism", "Age")), Anxiety_Variable)
  Covariates = c(Covariate_Formula_Anger, Covariate_Formula_NFC, Covariate_Formula_Altruism, Covariate_Formula,  Covariate_Formula_Anxiety)
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Offer", "Offer1"),
                         "Smaller" = c("Offer", "Offer5"))
  
  for (iTest in 1:length(Moderators)) {
    Name_Test = paste0("FRN_Offer_", Moderators[iTest])
    lm_formula =   paste( "EEG_Signal ~ ((Offer" , "*", Variables[iTest],") ", additional_Factor_Formula, ")", Covariates[iTest])
    collumns_to_keep = c("Offer", Covariate_Name, "EEG_Signal", additional_Factors_Name, Variables[iTest]) 
    Effect_of_Interest = c("Offer", Variables[iTest] )
    DirectionEffect$Personality = Variables[iTest]
    Estimates = rbind(Estimates,
                      wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                                   DirectionEffect, collumns_to_keep, "FRN"))
  }
  
  
  #########################################################
  # (5) Test Hypothesis 3, effects on RT
  #########################################################
  print("Test Effect of Choice on RT")
  lm_formula =   paste( "Behav_RT ~ ((Offer * Response) ) ", Covariate_Formula)
  collumns_to_keep = c("Offer","Response", Covariate_Name, "Behav_RT") 
  H3_Model =  wrap_test_Hypothesis("",lm_formula, output, "",
                                   "", collumns_to_keep, "RT",
                                   "exportModel")
  
  # Test Main Effect
  Effect_of_Interest = c("Response")
  Name_Test = "RT_Choice"
  DirectionEffect= list("Effect" = "main",
                        "Larger" = c("Response", "Reject"),
                        "Smaller" = c("Response", "Accept"),
                        "DV" = "Behav_RT")
  Estimates = rbind(Estimates,
                    wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                              DirectionEffect, collumns_to_keep, "RT",
                              "previousModel", H3_Model))
  
  # Test Interaction Effect
  Effect_of_Interest = c("Response", "Offer")
  Name_Test = "RT_Choice_Offer"
  DirectionEffect= list("Effect" = "interaction",
                        "Larger" = c("Response", "Reject"),
                        "Smaller" = c("Response", "Accept"),
                        "Interaction" = c("Offer", "Offer1", "Offer3"),
                        "DV" = "Behav_RT")
  Estimates = rbind(Estimates,
                    wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                              DirectionEffect, collumns_to_keep, "RT",
                              "previousModel", H3_Model))
  
  
  #########################################################
  # (6) No control for multiple comparisons
  #########################################################

  
  #########################################################
  # (7) Export as CSV file
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
