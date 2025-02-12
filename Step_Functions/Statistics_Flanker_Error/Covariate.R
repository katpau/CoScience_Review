Covariate = function(input = NULL, choice = NULL) {
  StepName = "Covariate"
  Choices = c("None", "Gender", "Age", "BDI_Depression", "BFI_OpenMindedness","BFI_Conscientiousness","BFI_Agreeableness","BFI_Extraversion", "Big5_OCEA")
  Order = 4
  output = input$data
  choice = "None"
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:
  
  # CS 01/23

  # Handles all Choices listed above as well as choices from previous Steps 
  # (Attention Checks Personality, Outliers_Personality, Personality_Variable)
  # (1) Get Choices from previous Steps
  # (2) Depending on these choices the correct Personality Scoring File is loaded (have been prepared separately)
  # (3) Then only the relevant Scores are kept (for IV, DV and Covariates)
  # (4) Merge Personality Data with Personality Data and prepare output
  # (5) Get Grouping Variables for later steps
  
  
  
   From = strsplit(output$TimeWindow, " ")
   From = as.numeric(  lapply(From, `[[`, 1))
   ERN =    From < 100
   PE = From >= 100
   output$Component = NA
   output$Component[ERN] = "ERN"
   output$Component[PE] = "PE"

output = output[which(output$Component == "ERN"),]



output  = output  %>% 
        group_by(ID, Condition) %>%
        summarise(EEG_Signal = mean(EEG_Signal, na.rm =TRUE),
	Lab = Lab[1],
	Experimenter = Experimenter[1],
	Electrode = Electrode[1],
	TimeWindow = TimeWindow[1],
	SME = SME[1],
	Epochs = Epochs[1],
	Component=Component[1])


if(grepl("_15.3_", input$stephistory["Inputfile"])){
output$EEG_Signal = output$EEG_Signal/100}

remove_extremes = function(Signal) {
  Min = mean(Signal, na.rm=T) - 3.29*sd(Signal, na.rm=T)
  Max = mean(Signal, na.rm=T) + 3.29*sd(Signal, na.rm=T)
  Signal[which(Signal<Min)] = NA
  Signal[which(Signal>Max)] = NA
  return(Signal)
}
output$EEG_Signal = remove_extremes(output$EEG_Signal)
output$EEG_Signal = remove_extremes(output$EEG_Signal)



  
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
  QuestionnaireFile = "Personality-Scores_ImposedEffect.csv"
  QuestFolder = paste0(input$stephistory["Root_Personality"])
  ScoreData = read.csv(paste0(QuestFolder, QuestionnaireFile), header = TRUE)
  
  
  #########################################################
  # (3) Extract Personality  (not forked)  + Covariates
  #########################################################
  PersonalityData = ScoreData[, c("ID", "Subset",
                                  colnames(ScoreData)[grepl( "PSWQ", colnames(ScoreData))])]
 

  # Select only Relevant Covariate
  if (Covariate_choice != "None") {
    if(Covariate_choice == "Gender_MF"  ) {
      Covariate_Variable = "Gender"
      
    }  else if (Covariate_choice  == "Age_MF"  ) {
      Covariate_Variable = "Age"
      
    } else if (Covariate_choice == "Big5_OCEA") {
     # Covariate_Variable = c(
    #    "BFI_OpenMindedness",
    #    "BFI_Conscientiousness",
    #    "BFI_Agreeableness",
    #    "BFI_Extraversion"
    #  )
      choice = "BFI_Extraversion"
      Covariate_Variable = "BFI_Extraversion"
    } else  {
      Covariate_Variable = Covariate_choice
    }
    CovariateData = ScoreData[, c("ID", names(ScoreData)[grepl( paste(Covariate_Variable, collapse = "|"), names(ScoreData))])]
    
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
  


  # Make sure everything is in correct format
  NumericVariables = c("EEG_Signal", "SME", "Epochs", names(output)[grepl("Personality_|Covariate_", names(output))])
  FactorVariables = c("ID", "Condition", "Electrode", 
                      names(output)[grepl("Covariate_Gender", names(output))],
                      "Subset")
  
  # for minimal preprocessing only Remove any PE
  output = output[output$Component == "ERN",]
  
  
  output[NumericVariables] = lapply(output[NumericVariables], as.numeric)
  output[FactorVariables] = lapply(output[FactorVariables], as.factor)
  
  # Unclear and still needs to be checked: Sometimes SME and EEG_Signal is Inf
  # Unclear why, but some EEG_Signal scores are -Inf
  output$EEG_Signal[abs(output$EEG_Signal)==Inf] = NA
  output$SME[abs(output$SME)==Inf] = NA
  
  
  #########################################################
  # (5) Prepare Grouping Variables
  #########################################################
  # Get possible additional factors to be included in the GLM
  
  if (length(unlist(unique(output$Electrode)))>1) {
    additional_Factors_Name = c("Electrode")
    additional_Factor_Formula = paste("* Electrode") 
  } else {
    additional_Factors_Name = vector()
    additional_Factor_Formula = vector()
  }
  
  
  # Grouping Variables in all Files and Merge with additional Factors
  GroupingVariables = c("Condition", "Subset", additional_Factors_Name )
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
