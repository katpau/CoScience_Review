Covariate = function(input = NULL, choice = NULL) {
  StepName = "Covariate"
  Choices = c("None","Gender_MF", "Gender", "Age_MF", "Age","BFI_Anxiety","Anxiety_Age_Gender_State","BFI_OpenMindedness","BFI_Conscientiousness","BFI_Agreeableness", "BFI_Extraversion", "Big5_OCEA")
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
  # (4) Get Mood Rating
  # (5) Prepare Output
  # (6) Prepare Grouping Variables

  
  #########################################################
  # (1) Preparations 
  #########################################################
  # Collect all Choices
  
  
  Attention_Checks_Personality_choice = unlist(input$stephistory["Attention_Checks_Personality"])
  Outliers_Personality_choice = unlist(input$stephistory["Outliers_Personality"])
  Depression_choice = unlist(input$stephistory["Depression"])
  RewardSensitivity_choice = unlist(input$stephistory["RewardSensitivity"])
  Covariate_choice = choice
  
  
  
  #########################################################
  # (2) run Choice Attention_Checks and Outliers 
  #########################################################
  # load correct file, these files have been created separately
  
  QuestFolder = paste0(input$stephistory["Root_Personality"])
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
  # select only relevant personality score (and Anhedonia)
  PersonalityData = ScoreData[, c("ID",  paste0("Personality_", 
                                                c(Depression_choice,
                                                  RewardSensitivity_choice,
                                                  "PDI5_Anhedonia")))]
  
  
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
    } else if(Covariate_choice == "Anxiety_Age_Gender_State") {
      Covariate_Variable = c(
        "PSWQ_Concerns",
        "Age",
        "BFI_Gender"
      )
    } else  {
      Covariate_Variable = Covariate_choice
    }
    CovariateData = ScoreData[, c("ID", paste0("Covariate_", Covariate_Variable))]
    
    AddCovariate = 1
  } else {AddCovariate = 0}
  
  
  
  #########################################################
  # (4) Get Mood Rating
  #########################################################
  
  # Read Behavioural Data
  BehavFile = paste0(input$stephistory["Root_Behavior"], "task_SR_beh.csv")
  BehavData = read.csv(BehavFile, header = TRUE)
  
  # keep only Ratings after GoNoGo Task
  if ((Covariate_choice == "Anxiety_Age_Gender_State")) {
    BehavData = BehavData[ BehavData$Run == 3 , c("ID", "sad", "anxious")]
    colnames(BehavData) = c("ID", "Behav_StateSadness", "Covariate_StateAnxiety")
  
  } else {
  BehavData = BehavData[ BehavData$Run == 3 , c("ID", "sad")]
  colnames(BehavData) = c("ID", "Behav_StateSadness")
  }
  
  
  #########################################################
  # (5) Prepare Output
  #########################################################
  # Drop all Difference Scores, since no Forking with them
  output = output[!grepl("Diff", output$Condition),]
  
  # Merge Data with EEG Data
  output = merge(
    output,
    BehavData,
    by = c("ID"),
    all.x = TRUE,
    all.y = FALSE
  )
  
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
  
  
  # First Split Condition Name of EEG into two collumns
  output = output %>%
    separate(Condition, c("Magnitude","FB"), "_")

  # Make sure everything is in correct format
  NumericVariables = c("EEG_Signal", "SME", "Epochs", names(output)[grepl("Personality_|Covariate_|Behav_", names(output))])
  FactorVariables = c("ID", "FB", "Magnitude", "Electrode",   "Component",
                      names(output)[grepl("Covariate_Gender", names(output))])
  
  
  output[NumericVariables] = lapply(output[NumericVariables], as.numeric)
  output[FactorVariables] = lapply(output[FactorVariables], as.factor)
  
  # Unclear and still needs to be checked: Sometimes SME and EEG_Signal is Inf
  # Unclear why, but some EEG_Signal scores are -Inf
  output$EEG_Signal[abs(output$EEG_Signal)==Inf] = NA
  output$SME[abs(output$SME)==Inf] = NA
  
  
  #########################################################
  # (6) Prepare Grouping Variables
  #########################################################
  # Get possible additional factors to be included in the GLM
  
  if (length(unlist(unique(output$Electrode)))>1) {additional_Factors_Name = c("Electrode")
  additional_Factor_Formula = paste("+ Electrode") 
  } else {
    additional_Factors_Name = vector()
    additional_Factor_Formula = vector()
  }
  
  
  # Grouping Variables in all Files and Merge with additional Factors
  GroupingVariables = c("FB", "Magnitude", "Component", additional_Factors_Name )
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
