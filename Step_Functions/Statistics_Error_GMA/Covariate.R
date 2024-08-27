Covariate = function(input = NULL, choice = NULL) {
  StepName = "Covariate"
  Choices = c("None", "Gender_MF", "Gender", "Age_MF", "Age",  "BDI_Depression","BFI_Extraversion","BFI_OpenMindedness","BFI_Conscientiousness","BFI_Agreeableness","BFI_NegativeEmotionality", "Big5_OCEAN")
  Order = 4
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:
  
  # Handles all Choices listed above as well as choices from previous Steps 
  # (Attention Checks Personality, Outliers_Personality, Personality_Variable)
  # (1) Preparation. Get Choices from previous Steps
  # (2) Load Data. Depending on these choices the correct Personality Scoring File is loaded (have been prepared separately)
  # (3) run Choice Relevant Covariate Score , Keep only the relevant Scores 
  # (4) Prepare Output and get Grouping Variables for later steps
  
  
  
  
  
  
  #########################################################
  # (1) Preparations 
  #########################################################
  # Collect all Choices
  
  
  Attention_Checks_Personality_choice = unlist(input$stephistory["Attention_Checks_Personality"])
  Outliers_Personality_choice = unlist(input$stephistory["Outliers_Personality"])
  Personality_Variable_choice = c("Personality_MPS_PersonalStandards","Personality_MPS_ConcernOverMistakes")
  Covariate_choice = choice
  
  
  
  #########################################################
  # (2) Load Data
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
  # (3) run Choice Relevant Covariate Score 
  #########################################################
  
  # Select only Relevant Covariate
  if (Covariate_choice != "None") {
    if (Covariate_choice == "Gender_MF") {
      Covariate_Variable = "Gender"
    }  else if (Covariate_choice == "Age_MF") {
      Covariate_Variable = "Age"
    } else if (Covariate_choice == "Big5_OCEAN") {
      Covariate_Variable = c(
        "BFI_OpenMindedness",
        "BFI_Conscientiousness",
        "BFI_Agreeableness",
        "BFI_NegativeEmotionality",
        "BFI_Extraversion"
      )
    } else  {
      Covariate_Variable = Covariate_choice
    }
    CovariateData = ScoreData[, c("ID",  paste0("Covariate_",Covariate_Variable))]
    AddCovariate = 1
  } else {AddCovariate = 0}
  
  
  
  #########################################################
  # (4) Prepare Output
  #########################################################

  quantileMs <- function (p, shape, rate, srate, modeSmp, modeMs) {
    frate <- 1000 / srate
    # Calculate the measurement sample offset from a given transformation
    xOff <- -(modeMs / frate - modeSmp)
    qSmp <- qgamma(p, shape = shape, rate = rate)
    return((qSmp - xOff) * frate)
  }

  output <- output %>% rowwise() %>% mutate(
    onset_ms = quantileMs(0.025, shape, rate, eeg_srate, mode, mode_ms),
    offset_ms = quantileMs(0.975, shape, rate, eeg_srate, mode, mode_ms),
    .after = excess
  )

  # Restructure wide into Long 
  output = output %>% 
    select(subject,lab,experimenter,task,condition,channel,component,n_trials, shape, rate,yscale, ip1_ms, ip2_ms, skew, excess, onset_ms, offset_ms) %>%
    gather(GMA_Measure, EEG_Signal, shape:offset_ms)
  colnames(output)[1:8] = str_to_title(colnames(output)[1:8])
  
  output = output %>%  # consistence across Projects
    rename(ID = Subject,
           Electrode = Channel,
           Epochs = N_trials)
  
  
  
  # Merge Data with EEG Data
  output = merge(
    output,
    ScoreData[,c("ID", Personality_Variable_choice)],
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
  
  
  # Make sure everything is in correct format
  NumericVariables = c("EEG_Signal", "Epochs", names(output)[grepl("Covariate_", names(output))])
  GroupingVariables = c("ID", "Condition",  "Component", "Task",  "GMA_Measure", names(output)[grepl("Covariate_Gender", names(output))])
  
  output[GroupingVariables] = lapply(output[GroupingVariables], as.factor)
  output[NumericVariables] = lapply(output[NumericVariables], as.numeric)
  
  
  # Grouping Variables in all Files and Merge with additional Factors
  GroupingVariables = c("Condition", "Component", "Task", "GMA_Measure")
  input$stephistory$GroupingVariables = GroupingVariables
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
