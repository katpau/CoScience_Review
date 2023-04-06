Determine_Significance = function(input = NULL, choice = NULL) {
  StepName = "Determine_Significance"
  Choices = c("Holm", "Bonferroni", "None")
  Order = 13
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by: Cassie (CAS) 4/23

  # Handles all Choices listed above 
  # Runs the statistical Test, corrects for multiple comparisons and 
  # Prepares Output Table
  
  # (1) Get Names and Formulas of variable Predictors
  # (2) Initiate Functions for Hypothesis Testing
  # (3) Prepare Averages across Condition1s and Correlations
  # (4-7) Test  Hypotheses
  # (8) Correct for Multiple Comparisons and Combine all Estimates
  # (9) Export as CSV file
  
  
  
  #########################################################
  # (1) Get Names and Formulas of variable Predictors
  #########################################################
  # Names are used to select relevant columns
  # Formula (parts) are used to be put together and parsed to the lm() function,
  # thats why they have to be added by a * or +
  
  # Get column Names for Personality Data (to to be used in the model formula)
  Personality_collumns = names(output)[names(output) %like% "Personality_"]

  Personality_Name_BAS = paste0("Personality_", unlist(input$stephistory["Personality_Variable"]))
  Personality_Name_BIS = paste0("Personality_", unlist(input$stephistory["Personality_Variable_BIS"]))
  Personality_Formula_BAS = paste("* ", Personality_Name_BAS)
  Personality_Formula_BIS = paste("* ", Personality_Name_BIS)
  

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
                                   collumns_to_keep, SaveUseModel, ModelProvided) {
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
    Subset = Data[, names(Data) %in% c("ID", "Epochs", "SME", "EEG_Signal", "Lab", collumns_to_keep)]
    
    # Run Test
    ModelResult = test_Hypothesis( Name_Test,lm_formula, Subset, Effect_of_Interest, SaveUseModel, ModelProvided)
    
    # Test Direction
    if (!SaveUseModel == "exportModel") {
      ModelResult = test_DirectionEffect(DirectionEffect, Subset, ModelResult) 
    }
    
    return(ModelResult)
  }
  
  
  
  #########################################################
  # (3) Test Hypothesis 1 
  #########################################################
  # The positive association between greater left than right frontal activity at rest (greater right than left
  # frontal EEG alpha) recorded at the beginning of the EEG session and trait BAS will be stronger for participants
  # who are hosted by opposite-sex experimenters
  # The interaction in 1.1. is strongest in participants who rate their opposite-sex experimenters as most
  # attractive
  print("Test Effect of Experimenter Sex and attractiveness for BAS")
  lm_formula =   paste( "EEG_Signal ~ ((Experimenter_Sex * Behav_Attractiveness * Participant_Sex )", 
                        Personality_Formula_BAS, additional_Factor_Formula, ")", Covariate_Formula)
 # is it correct that we're not including the main effects in the model, only the interaction term? (For experimenter sex, attractiveness, participant sex?)
 # I don't see trait-BAS included within the interaction term.
  collumns_to_keep = c("Experimenter_Sex", "Behav_Attractiveness",  "Participant_Sex", Personality_Name_BAS, Covariate_Name, additional_Factors_Name) 
  H1_Model = wrap_test_Hypothesis("",lm_formula, output, "", "", 
                                    collumns_to_keep, 
                                    "exportModel")
  
  Effect_of_Interest = c("Experimenter_Sex",  Personality_Name_BAS)
  Name_Test = c("BAS_ExperimenterSex")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Experimenter_Sex", "Opposite"),
                         "Smaller" = c("Experimenter_Sex", "Same"),
                         "Personality" = Personality_Name_BAS)
  
  H1_1 = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                DirectionEffect, collumns_to_keep,
                                "previousModel", H1_Model)
  
  
  Effect_of_Interest = c(Personality_Name_BAS, "Behav_Attractiveness")
  Name_Test = c("BAS_AttractivenesssRating")
  DirectionEffect = list("Effect" = "correlation",
                         "Personality" = Personality_Name_BAS)
  
  
  H1_12b = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                              DirectionEffect, collumns_to_keep,
                              "previousModel", H1_Model)
  
  Effect_of_Interest = c("Experimenter_Sex",  Personality_Name_BAS, "Behav_Attractiveness")
  Name_Test = c("BAS_AttractivenesssRating_ExperimenterSex")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Experimenter_Sex", "Opposite"),
                         "Smaller" = c("Experimenter_Sex", "Same"),
                         "Personality" = Personality_Name_BAS)
  
  
  H1_2 = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                              DirectionEffect, collumns_to_keep,
                              "previousModel", H1_Model)
  

  #########################################################
  # (4) Test Hypothesis 2 
  #########################################################
  #  It is predicted that specificity of the effect to trait BAS versus other personality traits will be supported
  print("Test Specificity")
  lm_formula =   paste( "EEG_Signal ~ ((Experimenter_Sex * Behav_Attractiveness * Participant_Sex )", 
                        "* (",  Personality_Name_BAS, "+ Personality_BFI_OpenMindedness + Personality_BFI_Conscientiousness + Personality_BFI_Agreeableness)",
                        additional_Factor_Formula, ")", Covariate_Formula)
  collumns_to_keep = c("Experimenter_Sex", "Behav_Attractiveness",  "Participant_Sex", Personality_Name_BAS, Covariate_Name, 
                       "Personality_BFI_OpenMindedness","Personality_BFI_Conscientiousness","Personality_BFI_Agreeableness",   
                       additional_Factors_Name) 
  H1_Model_3otherBFI = wrap_test_Hypothesis("",lm_formula, output, "", "", 
                                  collumns_to_keep, 
                                  "exportModel")
  
  
  lm_formula =   paste( "EEG_Signal ~ ((Experimenter_Sex * Behav_Attractiveness * Participant_Sex )", 
                        "* (",  Personality_Name_BAS, "+ Personality_BFI_OpenMindedness + Personality_BFI_Conscientiousness + Personality_BFI_Agreeableness + Personality_BFI_NegativeEmotionality)",
                        additional_Factor_Formula, ")", Covariate_Formula)
  collumns_to_keep = c("Experimenter_Sex", "Behav_Attractiveness",  "Participant_Sex", Personality_Name_BAS, Covariate_Name, 
                       "Personality_BFI_OpenMindedness","Personality_BFI_Conscientiousness","Personality_BFI_Agreeableness", "Personality_BFI_NegativeEmotionality",  
                       additional_Factors_Name) 
  H1_Model_4otherBFI = wrap_test_Hypothesis("",lm_formula, output, "", "", 
                                           collumns_to_keep, 
                                           "exportModel")
  
  
  Effect_of_Interest = c("Experimenter_Sex",  Personality_Name_BAS)
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Experimenter_Sex", "Opposite"),
                         "Smaller" = c("Experimenter_Sex", "Same"),
                         "Personality" = Personality_Name_BAS)
  
  Name_Test = c("BAS_ExperimenterSex_3OtherBFI")
  H2_1A = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                              DirectionEffect, collumns_to_keep,
                              "previousModel", H1_Model_3otherBFI)
  
  Name_Test = c("BAS_ExperimenterSex_4OtherBFI")
  H2_1B = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                               DirectionEffect, collumns_to_keep,
                               "previousModel", H1_Model_4otherBFI)
  
  
  
  
  Effect_of_Interest = c("Experimenter_Sex",  Personality_Name_BAS, "Behav_Attractiveness")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Experimenter_Sex", "Opposite"),
                         "Smaller" = c("Experimenter_Sex", "Same"),
                         "Interaction" = c("Participant_Sex", "Female", "Male"),
                         "Personality" = Personality_Name_BAS)
  Name_Test = c("BAS_ExperimenterSex_AttractivenesssRating_3OtherBFI")
  H2_2A = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                               DirectionEffect, collumns_to_keep,
                               "previousModel", H1_Model_3otherBFI)
  
  Name_Test = c("BAS_ExperimenterSex_AttractivenesssRating_4OtherBFI")
  H2_2B = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                               DirectionEffect, collumns_to_keep,
                               "previousModel", H1_Model_4otherBFI)

  
  
  
  #########################################################
  # (5) Test Hypothesis 3
  #########################################################
  print("Test Effect of Experimenter Sex and attractiveness for BIS")
  lm_formula =   paste( "EEG_Signal ~ ((Experimenter_Sex * Behav_Attractiveness * Participant_Sex )", 
                        Personality_Formula_BIS, additional_Factor_Formula, ")", Covariate_Formula)
  collumns_to_keep = c("Experimenter_Sex", "Behav_Attractiveness",  "Participant_Sex", Personality_Name_BIS, Covariate_Name, additional_Factors_Name) 
  H3_Model = wrap_test_Hypothesis("",lm_formula, output, "", "", 
                                  collumns_to_keep, 
                                  "exportModel")
  
  Effect_of_Interest = c("Experimenter_Sex",  Personality_Name_BIS)
  Name_Test = c("BIS_ExperimenterSex")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Experimenter_Sex", "Opposite"),
                         "Smaller" = c("Experimenter_Sex", "Same"),
                         "Personality" = Personality_Name_BIS)
  
  H3_1 = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                              DirectionEffect, collumns_to_keep,
                              "previousModel", H3_Model)
  
  
  Effect_of_Interest = c("Experimenter_Sex",  Personality_Name_BIS, "Behav_Attractiveness")
  Name_Test = c("BIS_ExperimenterSex_Attractiveness")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Experimenter_Sex", "Opposite"),
                         "Smaller" = c("Experimenter_Sex", "Same"),
                         "Interaction" = c("Participant_Sex", "Female", "Male"),
                         "Personality" = Personality_Name_BIS)
  
  
  H3_2 = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                              DirectionEffect, collumns_to_keep,
                              "previousModel", H3_Model)
  
  
  
  #########################################################
  # (6) Test Hypothesis 2 
  ######################################################### 
  #  It is predicted that specificity of the effect to trait BIS versus other personality traits will be supported
  print("Test Specificity")
  lm_formula =   paste( "EEG_Signal ~ ((Experimenter_Sex * Behav_Attractiveness * Participant_Sex )", 
                        "* (",  Personality_Name_BIS, "+ Personality_BFI_OpenMindedness + Personality_BFI_Conscientiousness + Personality_BFI_Agreeableness)",
                        additional_Factor_Formula, ")", Covariate_Formula)
  collumns_to_keep = c("Experimenter_Sex", "Behav_Attractiveness",  "Participant_Sex", Personality_Name_BIS, Covariate_Name, 
                       "Personality_BFI_OpenMindedness","Personality_BFI_Conscientiousness","Personality_BFI_Agreeableness",   
                       additional_Factors_Name) 
  H1_Model_3otherBFI = wrap_test_Hypothesis("",lm_formula, output, "", "", 
                                            collumns_to_keep, 
                                            "exportModel")
  
  
  lm_formula =   paste( "EEG_Signal ~ ((Experimenter_Sex * Behav_Attractiveness * Participant_Sex )", 
                        "* (",  Personality_Name_BIS, "+ Personality_BFI_OpenMindedness + Personality_BFI_Conscientiousness + Personality_BFI_Agreeableness + Personality_BFI_Extraversion)",
                        additional_Factor_Formula, ")", Covariate_Formula)
  collumns_to_keep = c("Experimenter_Sex", "Behav_Attractiveness",  "Participant_Sex", Personality_Name_BIS, Covariate_Name, 
                       "Personality_BFI_OpenMindedness","Personality_BFI_Conscientiousness","Personality_BFI_Agreeableness", "Personality_BFI_Extraversion",  
                       additional_Factors_Name) 
  H1_Model_4otherBFI = wrap_test_Hypothesis("",lm_formula, output, "", "", 
                                            collumns_to_keep, 
                                            "exportModel")
  
  
  Effect_of_Interest = c("Experimenter_Sex",  Personality_Name_BIS)
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Experimenter_Sex", "Opposite"),
                         "Smaller" = c("Experimenter_Sex", "Same"),
                         "Personality" = Personality_Name_BIS)
  
  Name_Test = c("BIS_ExperimenterSex_3OtherBFI")
  H4_1A = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                               DirectionEffect, collumns_to_keep,
                               "previousModel", H1_Model_3otherBFI)
  
  Name_Test = c("BIS_ExperimenterSex_4OtherBFI")
  H4_1B = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                               DirectionEffect, collumns_to_keep,
                               "previousModel", H1_Model_4otherBFI)
  
  
  
  
  Effect_of_Interest = c("Experimenter_Sex",  Personality_Name_BIS, "Behav_Attractiveness")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Experimenter_Sex", "Opposite"),
                         "Smaller" = c("Experimenter_Sex", "Same"),
                         "Interaction" = c("Participant_Sex", "Female", "Male"),
                         "Personality" = Personality_Name_BIS)
  Name_Test = c("BIS_ExperimenterSex_AttractivenesssRating_3OtherBFI")
  H4_2A = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                               DirectionEffect, collumns_to_keep,
                               "previousModel", H1_Model_3otherBFI)
  
  Name_Test = c("BIS_ExperimenterSex_AttractivenesssRating_4OtherBFI")
  H4_2B = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                               DirectionEffect, collumns_to_keep,
                               "previousModel", H1_Model_4otherBFI)
  
  
  #########################################################
  # (7) Test Hypothesis 5 
  ######################################################### 
  #  It is further predicted that participants' mood will be more positive after an encounter with a more
  # attractive rather than a less attractive experimenter of the opposite sex. Exploratory analyses will probe
  # whether experimenters' and participants' sex moderate this effect. If an effect of experimenter attractiveness
  # (and/or participant/experimenter sex) on mood is observed, we will further explore whether this mediates the
  # moderating effects listed under (1) and (3).
  # During peer-review of the introduction section, we agreed not to test hypothesis 5
  
  # Better to look at Main Effect and then decide which effect should be explored?
  lm_formula =    "Behav_Mood ~ ((Experimenter_Sex * Median_Attractiveness)"
  collumns_to_keep = c("Behav_Mood", "Experimenter_Sex",  "Median_Attractiveness") 
  
  # To Be Added
 
  
  #########################################################
  # (8) Correct for Multiple Comparisons for Hypothesis 1
  #########################################################
  
  Estimates_to_Correct = as.data.frame(rbind(H1_1, H1_2, H1_12b, H3_1, H3_2)) # add other estimates here
  comparisons = sum(!is.na(Estimates_to_Correct$p_Value))
  
  if (choice == "Holm"){
    Estimates_to_Correct$p_Value = p.adjust(Estimates_to_Correct$p_Value, method = "holm", n = comparisons)
  }  else if (choice == "Bonferroni"){
    Estimates_to_Correct$p_Value = p.adjust(Estimates_to_Correct$p_Value, method = "bonferroni", n = comparisons)
  }
  
  Estimates = rbind(Estimates_to_Correct,
                    H2_1A, H2_1B,H2_2A, H2_2B, 
                    H4_1A, H4_1B,H4_2A, H4_2B ) # Add other estimates here
  
  # We also preregistered false discovery rate
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
