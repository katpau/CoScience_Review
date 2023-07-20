Covariate = function(input = NULL, choice = NULL) {
  StepName = "Covariate"
  Choices = c("None", "Gender", "Age", "BDI_Depression", "BFI_Anxiety", "BFI_OpenMindedness","BFI_Conscientiousness","BFI_Agreeableness","BFI_Extraversion", "BFI_NegativeEmotionality", "Big5_OCEAN")
  Order = 4
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by: CK 5/23

  # Handles all Choices listed above as well as choices from previous Steps 
  # (Attention Checks Personality, Outliers_Personality, Personality_Variable)
  # (1) Get Choices from previous Steps
  # (2) Depending on these choices the correct Personality Scoring File is loaded (have been prepared separately)
  # (3) Then only the relevant Scores are kept (for IV, DV and Covariates)
  # (4) Merge Personality Data with Personality Data and prepare output
  # (5) Get Grouping Variables for later steps
  
  
  
  
  
  #########################################################
  # (1) Preparations 
  #########################################################
  # Collect all Choices
  
  
  Attention_Checks_Personality_choice = unlist(input$stephistory["Attention_Checks_Personality"])
  Outliers_Personality_choice = unlist(input$stephistory["Outliers_Personality"])
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
  # (3) Extract Personality  (not forked)  + Covariates
  #########################################################
  PersonalityData = ScoreData[, c("ID", colnames(ScoreData)[grepl("Personality_", colnames(ScoreData))])]

  # Select only Relevant Covariate
  if (Covariate_choice != "None") {
    if(Covariate_choice == "Gender_MF"  ) {
      Covariate_Variable = "Gender"
      
    }  else if (Covariate_choice  == "Age_MF"  ) {
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
    CovariateData = ScoreData[, c("ID", paste0("Covariate_", Covariate_Variable))]
    
    AddCovariate = 1
  } else {AddCovariate = 0}
  
  
  
  #########################################################
  # (4) Prepare Output
  #########################################################
  # Keep Data Types Separate, do not merge (Personality, Behav/EEG)
  output_Personality = PersonalityData
  if (!AddCovariate == 0) {
    output_Personality = merge(
      output_Personality,
      CovariateData,
      by = c("ID"),
      all.x = TRUE,
      all.y = FALSE
    )}
  input$stephistory$output_Personality = output_Personality


  # Make sure everything is in correct format
  # Since this is now Single Trial Data, the EEG Signal is not yet in the correct (long) Format
  columnstoChange1 = colnames(output)[8]
  columnstoChange2 = colnames(output)[length(colnames(output))]
  
  # Rename Subject Variable
  colnames(output)[5] = "ID"
  
  output = output %>%
    gather(Component_Electrode, EEG_Signal, !!as.character(columnstoChange1):!!as.character(columnstoChange2)) %>%
    separate(Component_Electrode, into=c("Component", "Electrode"), sep="_")
  
  # Data is missing SME and total Epoch Number, calculate and add here
  output = output %>%
    group_by(ID, Congruency, Component, Electrode) %>%
    mutate(SME = sd(EEG_Signal)/sqrt(length(EEG_Signal)),
           Epochs = length(EEG_Signal))
  

  ##
  NumericVariables = c("EEG_Signal", "SME", "Epochs", "Congruency", "Trial")
  FactorVariables = c("ID",  "Electrode", "Component")
  
  NumericPersonalityVariables = c(names(output_Personality)[grepl("Personality_|Covariate_", names(output_Personality))])
  FactorPersonalityVariables = c("ID",  names(output)[grepl("Covariate_Gender", names(output_Personality))])

  output[,NumericVariables] = lapply(output[,NumericVariables], as.numeric)
  output[,FactorVariables] = lapply(output[,FactorVariables], as.factor)
  output_Personality[,NumericPersonalityVariables] = lapply(output_Personality[,NumericPersonalityVariables], as.numeric)
  if (!AddCovariate == 0) {
  output_Personality[,FactorPersonalityVariables] = lapply(output_Personality[,FactorPersonalityVariables], as.factor) 
  } else {
    output_Personality[,FactorPersonalityVariables] = as.factor(output_Personality[,FactorPersonalityVariables])
  }
  
  
  # Unclear and still needs to be checked: Sometimes SME and EEG_Signal is Inf
  # Unclear why, but some EEG_Signal scores are -Inf
  output$EEG_Signal[abs(output$EEG_Signal)==Inf] = NA
  output$SME[abs(output$SME)==Inf] = NA
  
  
  #########################################################
  # (5) Prepare Grouping Variables
  #########################################################
  # Get possible additional factors to be included in the GLM
  nEl = output %>% group_by(Component) %>% summarise(nEl = length(unique(Electrode))) %>% ungroup %>% summarise(nEl = max(nEl))
  if (nEl>1) {additional_Factors_Name = c("Electrode")
  additional_Factor_Formula = paste("+ Electrode") 
  } else {
    additional_Factors_Name = vector()
    additional_Factor_Formula = vector()
  }
  
  
  # Grouping Variables in all Files and Merge with additional Factors
  GroupingVariables = c("Congruency", "Component", additional_Factors_Name )
  input$stephistory$GroupingVariables = GroupingVariables
  input$stephistory$additional_Factors_Name = additional_Factors_Name
  input$stephistory$additional_Factor_Formula = additional_Factor_Formula
  input$stephistory$output_Personality = output_Personality
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
