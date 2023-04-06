Covariate = function(input = NULL, choice = NULL) {
  StepName = "Covariate"
  Choices = c("None", "Age_MF", "Age", "AGG_Anger","BDI_Depression","BFI_OpenMindedness","BFI_Conscientiousness","BFI_Agreeableness", "Participant_attractiveness", "Participant_likeability", "Experimenter_likeability", "All_ParticipantExperimenter_Ratings")
  Order = 4.3
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by: Cassie (CAS) 4/23

  # Handles all Choices listed above as well as choices from previous Steps 
  # (Attention Checks Personality, Outliers_Personality, Personality_Variable)
  # (1) Preparations: Get Choices from previous Steps
  # (2) Load File
  # (3) Then only the relevant Scores are kept (for IV and DV)
  # (4) Get the correct Covariates from the Ratings
  # (5) Prepare Output: Merge Personality Data with Personality Data & Rename Conditions
  # (6) Get Grouping Variables for later steps
  
  
  #########################################################
  # (1) Preparations 
  #########################################################
  # Collect all Choices
  
  
  Attention_Checks_Personality_choice = unlist(input$stephistory["Attention_Checks_Personality"])
  Outliers_Personality_choice = unlist(input$stephistory["Outliers_Personality"])
  Personality_Variable_choice = unlist(input$stephistory["Personality_Variable"])
  Personality_Variable_BIS_choice = unlist(input$stephistory["Personality_Variable_BIS"])
  Covariate_choice = choice
  
  
  #########################################################
  # (2) Load File
  #########################################################
  # Depending on these choices the correct Personality Scoring File is loaded (have been prepared separately)
  
  QuestFolder = input$stephistory["Root_Personality"]
  if (Attention_Checks_Personality_choice == "Applied") {
    if (Outliers_Personality_choice == "None") {
      QuestionnaireFile = "Personality-Scores-filtered_outliers-notremoved.csv"
    } else {
      QuestionnaireFile = "Personality-Scores-filtered_outliers-removed.csv"
    }
    
  } else {
    if (Outliers_Personality_choice == "None") {
      QuestionnaireFile = "Personality-Scores-unfiltered_outliers-notremoved.csv"
    } else {
      QuestionnaireFile = "Personality-Scores-unfiltered_outliers-removed.csv"
    }
    
  }
  ScoreData = read.csv(paste0(input$stephistory["Root_Personality"], QuestionnaireFile), header = TRUE)
  
  
  #########################################################
  # (3) run Choice Relevant Personality Score 
  #########################################################
  # select only relevant personality score (and all covariates)
  # Also get Participant_Sex
  PersonalityData = ScoreData[, c("ID",  paste0("Personality_", c(Personality_Variable_choice,Personality_Variable_BIS_choice)), "Covariate_Gender")]
  names(PersonalityData)[4] = "Participant_Sex"
  
  # Also add Variables for Hypothesis 2
  AddPersonality = ScoreData[, c( "Covariate_BFI_Extraversion","Covariate_BFI_OpenMindedness","Covariate_BFI_Conscientiousness","Covariate_BFI_Agreeableness",  "Covariate_BFI_NegativeEmotionality")]
  colnames(AddPersonality) = gsub("Covariate_", "Personality_", colnames(AddPersonality))
  PersonalityData = cbind(PersonalityData, AddPersonality)
  
  # Recode Sex to be more intuitive
  PersonalityData$Participant_Sex[PersonalityData$Participant_Sex == 1] = "Female"
  PersonalityData$Participant_Sex[PersonalityData$Participant_Sex == 2] = "Male"
  
  
 
  #########################################################
  # (4) run Choice Relevant Covariate
  #########################################################
  # Select only Relevant Covariate from Personality Data
  if (Covariate_choice != "None") {
    # Some Covariate is included
    
    if (!grepl("Participant|Experimenter", Covariate_choice) ) {
    # Covariate is based on questionnaires
    if (Covariate_choice == "Age_MF") {
      Covariate_Variable = "Age"
    } else {
      Covariate_Variable = Covariate_choice
    }
      # Get Data 
    CovariateData = ScoreData[, c("ID", paste0("Covariate_", Covariate_Variable))]
     # Prepare Note for merging later
    AddCovariate = 1
    AddBehavCovariate = 0


  } else if (grepl("Participant|Experimenter", Covariate_choice)) {
    # Covariate is based on ratings
    BehavFile = paste0(input$stephistory["Root_Behavior"], "task_Ratings_beh.csv")
    BehavData = read.csv(BehavFile, header = TRUE, sep = ";")
    ParticipantData = BehavData[BehavData$Rated_Person == "Participant",]
    ExperimenterData = BehavData[BehavData$Rated_Person == "Experimenter",]
    
    if (Covariate_choice == "Participant_attractiveness") {
      BehavData = ParticipantData[,c("ID", "attractiveness")]
      colnames(BehavData) = c("ID", "Covariate_PartAttractive")
      
    } else if (Covariate_choice == "Participant_likeability") {
      BehavData = ParticipantData[,c("ID", "sympathy")]
      colnames(BehavData) = c("ID", "Covariate_PartLike")
      
    } else if (Covariate_choice == "Experimenter_likeability") {
      BehavData = ExperimenterData[,c("ID", "sympathy")]
      colnames(BehavData) = c("ID", "Covariate_ExpLike")
      
    } else if (Covariate_choice == "All_ParticipantExperimenter_Ratings") {
      BehavData1 = ParticipantData[,c("ID", "attractiveness", "sympathy")]
      BehavData2 = ExperimenterData[,c("ID", "sympathy")]
      BehavData = merge(BehavData1,
                        BehavData2,
                        by = "ID"  )
      colnames(BehavData) = c("ID", "Covariate_PartAttractive", "Covariate_PartLike", "Covariate_ExpLike")
    }
    AddCovariate = 0
    AddBehavCovariate = 1
  
  }
    } else { 
    # No Covariate added
    AddCovariate = 0
    AddBehavCovariate = 0}
  
  #########################################################
  # (5) Prepare Output
  #########################################################
  # Merge Data with EEG Data
  output = merge(
    output,
    PersonalityData,
    by = c("ID"),
    all.x = TRUE,
    all.y = FALSE
  )
  
  if (AddCovariate == 1) {
    output = merge(
      output,
      CovariateData,
      by = c("ID"),
      all.x = TRUE,
      all.y = FALSE
    )}
  
  
  if (AddBehavCovariate == 1) {
    output = merge(
      output,
      BehavData,
      by = c("ID"),
      all.x = TRUE,
      all.y = FALSE
    )}
  
  
  # Recode Experimenter_Sex so it reflects only same or opposite of participant
  output$Experimenter_Sex[!output$Experimenter_Sex == output$Participant_Sex] = "Opposite"
  output$Experimenter_Sex[output$Experimenter_Sex == output$Participant_Sex] = "Same"
  
  
  # Make sure everything is in correct format
  NumericVariables = c("EEG_Signal", "SME", "Epochs", names(output)[grepl("Personality_|Covariate_", names(output))])
  FactorVariables = c("ID", "Hemisphere", "Electrode", "FrequencyBand", "Localisation", "Participant_Sex", "Experimenter_Sex")
  
  output[FactorVariables] = lapply(output[FactorVariables], as.factor)
  output[NumericVariables] = lapply(output[NumericVariables], as.numeric)
  
  # Unclear and still needs to be checked: Sometimes SME and EEG_Signal is Inf
  # Unclear why, but some EEG_Signal scores are -Inf
  # I don't see that this is due to the script. I think it is an issue with the data input.
  output$EEG_Signal[abs(output$EEG_Signal)==Inf] = NA
  output$SME[abs(output$SME)==Inf] = NA
  
  
  #########################################################
  # (6) Prepare Grouping Variables
  #########################################################
  # Get possible additional factors to be included in the GLM
  # Added Factors to the GLM depend on combination of Electrodes and Quantification method (some are redundant!)
  Levels_H = length(unlist(unique(output$Hemisphere)))
  Levels_L = length(unlist(unique(output$Localisation)))
  Levels_E = length(unlist(unique(output$Electrode)))
  Levles_F = length(unlist(unique(output$FrequencyBand)))
  # Levles_F rather than Levels_F but this is consistent in the script. Thought I'd mention it though in case you'd prefer to amend it.
  additional_Factors_Name = vector()
  additional_Factor_Formula = vector()
  if (Levels_H == 2) {
    additional_Factors_Name = "Hemisphere"
    additional_Factor_Formula = "* Hemisphere" 
  }
  if (Levels_L == 2 & Levels_E == 2) {
    additional_Factors_Name = c(additional_Factors_Name, "Localisation")
    additional_Factor_Formula = paste(additional_Factor_Formula, "* Localisation") 
  }
  if (Levels_E >1 & Levels_L < 2) { 
    additional_Factors_Name = c(additional_Factors_Name, "Electrode")
    additional_Factor_Formula = paste(additional_Factor_Formula, "+ Electrode") 
  }
  if (Levels_E == 6 & Levels_L == 2) { 
    additional_Factors_Name = c(additional_Factors_Name, "Electrode")
    additional_Factor_Formula = paste(additional_Factor_Formula, "* Electrode") 
  }
  if (Levles_F == 2) {
    additional_Factors_Name = c(additional_Factors_Name, "FrequencyBand")
    additional_Factor_Formula = paste(additional_Factor_Formula, "+ FrequencyBand")
  }
  
  # Grouping Variables in all Files and Merge with additional Factors
  GroupingVariables = c("Participant_Sex","Experimenter_Sex", additional_Factors_Name )
  input$stephistory$GroupingVariables = GroupingVariables
  input$stephistory$additional_Factors_Name = additional_Factors_Name
  input$stephistory$additional_Factor_Formula = additional_Factor_Formula
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}

