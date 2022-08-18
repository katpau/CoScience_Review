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

QuestFolder = "/work/bay2875/QuestionnaireData/Alpha_Context/"
#QuestFolder = "C:/Users/Paul/Documents/Work/PersonalityEEG/FINAL_RDF/HUMMEL/work/QuestionnaireData/Alpha_Context/"
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

# Depends  if Choice includes Factors from Factor analysis (then multiple scores)
if (Personality_Variable_choice != "Factor_Analysis") {
  PersonalityData = ScoreData[, c("ID", Personality_Variable_choice)]
  names(PersonalityData) = c("ID", paste0("Personality_", Personality_Variable_choice))
} else {
  PersonalityData = ScoreData[, c(1, grep("FactorAnalysis", names(ScoreData)))]
  names(PersonalityData) = c("ID", paste0("Personality_", names(PersonalityData[2:ncol(PersonalityData)])))
}

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

#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
