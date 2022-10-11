Covariate = function(input = NULL, choice = NULL) {
  StepName = "Covariate"
  Choices = c("None", "Gender_MF", "Gender", "Age_MF", "Age",  "AGG_Anger", "WHO5_Depression", "BFI_Open.Mindedness", "BFI_Conscientiousness", "BFI_Agreeableness", "BFI_Negative_Emotionality", "Big5_OCAN")
  Order = 4
  output = input$data
  
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
  
  QuestFolder = paste0(input$stephistory["Root_Personality"], "Alpha_Context/")
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
  
  QuestFolder="C:/Users/Paul/Documents/Work/PersonalityEEG/FINAL_RDF/HUMMEL/home/ForCompiling/Only_ForGit_To_TestRun/QuestionnaireData/Alpha_Context/"
  #QuestFolder="/work/bay2875/QuestionnaireData/Alpha_Context/"
  ScoreData = read.csv(paste0(QuestFolder, QuestionnaireFile), header = TRUE)
  
  
  #########################################################
  # (3) run Choice Relevant Personality Score 
  #########################################################
  # select only relevant personality score (and all covariates)
  PersonalityData = ScoreData[, c("ID", Personality_Variable_choice)]
  names(PersonalityData) = c("ID", paste0("Personality_", Personality_Variable_choice))
  
  # Select only Relevant Covariate
  if (Covariate_choice != "None") {
    if (Covariate_choice == "Gender_MF") {
      Covariate_Variable = "Gender"
    }  else if (Covariate_choice == "Age_MF") {
      Covariate_Variable = "Age"
    } else if (Covariate_choice == "Big5_OCAN") {
      Covariate_Variable = c(
        "BFI_Open.Mindedness",
        "BFI_Conscientiousness",
        "BFI_Agreeableness",
        "BFI_Negative_Emotionality"
      )
    } else  {
      Covariate_Variable = Covariate_choice
    }
    CovariateData = ScoreData[, c("ID", Covariate_Variable)]
    
    names(CovariateData)[names(CovariateData)==Covariate_Variable] = paste0("Covariate_",Covariate_Variable)
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
  # (5) Rename Stroop Conditions
  #########################################################
  # Add Gender to rename conditions later
  Gender = ScoreData[, c("ID", "Gender")]
  output = merge(
    output,
    Gender,
    by = c("ID"),
    all.x = TRUE,
    all.y = FALSE
  )
  
 
  
  
  # Make sure everything is in correct format
  NumericVariables = c("EEG_Signal", "SME", "Epochs", names(output)[grepl("Personality_|Covariate_", names(output))])
  GroupingVariables = c("ID", "Condition", "Hemisphere", "Electrode", "FrequencyBand", "Localisation",  names(output)[grepl("Covariate_Gender", names(output))])
  
  output[GroupingVariables] = lapply(output[GroupingVariables], as.factor)
  output[NumericVariables] = lapply(output[NumericVariables], as.numeric)
  
  # Unclear and still needs to be checked: Sometimes SME and EEG_Signal is Inf
  # Unclear why, but some EEG_Signal scores are -Inf
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
  GroupingVariables = c("Condition", "Condition2", "Task", "AnalysisPhase", additional_Factors_Name )
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
