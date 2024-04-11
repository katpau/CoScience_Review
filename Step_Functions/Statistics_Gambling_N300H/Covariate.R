Covariate = function(input = NULL, choice = NULL) {
  StepName = "Covariate"
  Choices = c("None", "Gender_MF", "Gender", "Age_MF", "Age", "BDI_Depression","BFI_Extraversion","BFI_OpenMindedness","BFI_Conscientiousness","BFI_Agreeableness", "Big5_OCEA")
  Order = 4
  output = input$data

  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:
  
  # Handles all Choices listed above as well as choices from previous Steps 
  # (Attention Checks Personality, Outliers_Personality, Personality_Variable)
  # (1) Get Choices from previous Steps
  # (2) Depending on these choices the correct Personality Scoring File is loaded (have been prepared separately)
  # (3) Then only the relevant Scores are kept (for IV, DV and Covariates)
  # (4) Merge Personality Data with Personality Data
  # (5) Rename Stroop Conditions to reflect same-opposite Sex 
  # (6) Get Grouping Variables for later steps
  
  
  
  #########################################################
  # (1) Preparations 
  #########################################################
  # Collect all Choices
  
  
  Attention_Checks_Personality_choice = unlist(input$stephistory["Attention_Checks_Personality"])
  Outliers_Personality_choice = unlist(input$stephistory["Outliers_Personality"])
  Personality_Variable_choice = unlist(input$stephistory["Personality_Variable"])
  Covariate_choice = choice
  
  
  #########################################################
  # (2) run Choice Attention_Checks and Outliers 
  #########################################################
  # load correct file, these files have been created separately
  
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
  
  ScoreData = read.csv(paste0(QuestFolder, QuestionnaireFile), header = TRUE)
  
  
  #########################################################
  # (3) run Choice Relevant Personality Score 
  #########################################################
  # select only relevant personality score (and all covariates)
  PersonalityData = ScoreData[, c("ID",  paste0("Personality_", Personality_Variable_choice))]
  
  
  # Select only Relevant Covariate
  if (Covariate_choice != "None") {
    if (Covariate_choice == "Gender_MF") {
      Covariate_Variable = "Gender"
    }  else if (Covariate_choice == "Age_MF") {
      Covariate_Variable = "Age"
    } else if (Covariate_choice == "Big5_OCEA") {
      Covariate_Variable = c(
        "BFI_OpenMindedness",
        "BFI_Conscientiousness",
        "BFI_Agreeableness",
        "BFI_Extraversion"
      )
    } else  {
      Covariate_Variable = Covariate_choice
    }
    CovariateData = ScoreData[, c("ID", paste0("Covariate_",Covariate_Variable))]
    AddCovariate = 1
  } else {AddCovariate = 0}
  
  
  
  #########################################################
  # (4) Prepare Output
  #########################################################
  # Merge Data with EEG Data
  output = merge(
    output,
    PersonalityData,
    by = c("ID"),
    all.x = TRUE,
    all.y = FALSE
  )
  
  if (!AddCovariate == 0) {
    output = merge(
      output,
      CovariateData,
      by = c("ID"),
      all.x = TRUE,
      all.y = FALSE
    )}
  
  
  
  
  #########################################################
  # (5) Prepare Export
  #########################################################
  # Make sure everything is in correct format
  NumericVariables = c("EEG_Signal", "Epochs", names(output)[grepl("Personality_|Covariate_|Behav_", names(output))])
  FactorVariables = c("ID", "Condition", "Electrode",   
                      names(output)[grepl("Covariate_Gender", names(output))])
  
  
  output[NumericVariables] = lapply(output[NumericVariables], as.numeric)
  output[FactorVariables] = lapply(output[FactorVariables], as.factor)
  
  # Unclear and still needs to be checked: Sometimes SME and EEG_Signal is Inf
  # Unclear why, but some EEG_Signal scores are -Inf
  output$EEG_Signal[abs(output$EEG_Signal)==Inf] = NA
  
  
  #########################################################
  # (6) Prepare Grouping Variables
  #########################################################
  # Get possible additional factors to be included in the GLM
  
  additional_Factors_Name = vector()
  additional_Factor_Formula = vector()
  
  if (length(unlist(unique(output$Electrode)))>1) {
    additional_Factors_Name = c(additional_Factors_Name, "Electrode")
    additional_Factor_Formula =  paste(additional_Factor_Formula, "* Electrode") 
  }
  
  if (length(unlist(unique(output$Bin)))>1) {
    additional_Factors_Name = c(additional_Factors_Name, "Bin")
    additional_Factor_Formula =  paste(additional_Factor_Formula, "* Bin") 
  }
  
  # Grouping Variables in all Files and Merge with additional Factors
  GroupingVariables = c("Condition",  additional_Factors_Name )
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
