Determine_Significance = function(input = NULL, choice = NULL) {
  StepName = "Determine_Significance"
  Choices = c("Holm", "Bonferroni", "None")
  Order = 13
  output = input$data
  
  # Handles all Choices listed above 
  # Runs the statistical Test, corrects for multiple comparisons and 
  # Prepares Output Table
  # (1) Get Names and Formulas of variable Predictors
  # (2) Initiate Functions for Hypothesis Testing
  # (3) Prepare Averages across Conditions and Correlations
  # (4) Test State Hypothesis (H1)
  # (5) Test Interaction with Personality in preparation for H2
  # (6) Prepare which Data should be compared to Resting (could be either AV across all conditions or condition with strongest correlation)
  # (7) Compare Association to Personality for different Phases and Tasks
  # (8) Correct for Multiple Comparisons for Hypothesis 1 and Combine all Estimates
  # (9) Export as CSV file
  
  
  
  ## Before Start, check that all Tasks have been processed
  if (length(unique(output$Task))<3) {
    stop("Processing Stopped at Determine Significance. Not all Tasks preprocessed")
  } else if (all(is.na((unique(output$Behav_Pleasure))))) {
    stop("Processing Stopped at Determine Significance. Ratings Stroop Missing")
  }
  
  
  #########################################################
  # (1) Get Names and Formulas of variable Predictors
  #########################################################
  
  # Get column Names for Personality Data (to to be used in the model formula)
  Personality_Name = names(output)[names(output) %like% "Personality_"]
  Personality_Formula = paste("* ", Personality_Name)
  
  # Get column Names for Behavioural Data
  Behavior_Name = names(output)[names(output) %like% "Behav_"]

  # Get column Names for Covariates
  if (input$stephistory["Covariate"] == "None") { 
    Covariate_Formula = ""
    Covariate_Name = vector()
  } else if (input$stephistory["Covariate"] == "Gender_MF") { 
    Covariate_Formula = "+ Covariate_Gender"
    Covariate_Name = "Covariate_Gender"
  } else if (input$stephistory["Covariate"] == "Age_MF") { 
    Covariate_Formula = "+ Covariate_Age"
    Covariate_Name = "Covariate_Age"
  }else { 
    Covariate_Name = names(output)[names(output) %like% "Covariate_"]
    Covariate_Formula = ""
  for (iCov in Covariate_Name) {
    Covariate_Formula = paste(Covariate_Formula, "*", iCov, " ")
  }
  }
  
  
  
  # Get possible additional factors to be included in the GLM
  # Added Factors depend on combination of Electrodes and Quantification method
  Levels_H = length(unlist(unique(output$Hemisphere)))
  Levels_L = length(unlist(unique(output$Localisation)))
  Levels_E = length(unlist(unique(output$Electrode)))

  if (Levels_H == 2 & Levels_L == 1 & Levels_E == 2) {
    additional_Factors_Name = "Hemisphere"
    additional_Factor_Formula = "* Hemisphere" 
    }  else if (Levels_H == 2 & Levels_L == 1 & Levels_E == 6) {
    additional_Factors_Name = c("Hemisphere", "Electrode")
    additional_Factor_Formula = "* Hemisphere * Electrode" 
    }  else if (Levels_H == 2 & Levels_L == 2 & Levels_E == 4) {
    additional_Factors_Name = c("Hemisphere", "Localisation")
    additional_Factor_Formula = "* Hemisphere * Localisation"
    }  else if (Levels_H == 2 & Levels_L == 2 & Levels_E == 12) {
    additional_Factors_Name = c("Hemisphere", "Localisation","Electrode")
    additional_Factor_Formula = "* Hemisphere * Localisation * Electrode"
    }  else if (Levels_H == 1 & Levels_L == 1 & Levels_E == 1) {
    additional_Factors_Name = vector()
    additional_Factor_Formula = vector()
    }  else if (Levels_H == 1 & Levels_L == 1 & Levels_E == 3) {
    additional_Factors_Name = c("Electrode")
    additional_Factor_Formula = "* Electrode"
    }  else if (Levels_H == 1 & Levels_L == 2 & Levels_E == 2) {
    additional_Factors_Name =  c( "Localisation")
    additional_Factor_Formula = "* Localisation"
    }  else if (Levels_H == 1 & Levels_L == 2 & Levels_E == 6) {
    additional_Factors_Name = c( "Localisation","Electrode")
    additional_Factor_Formula = "* Electrode * Localisation"}
  

  #########################################################
  # (2) Initiate Functions for Hypothesis Testing
  #########################################################
  
  test_Hypothesis = function (Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase) {
    Subset = output[output$Task %in% Task & output$AnalysisPhase %in% AnalysisPhase ,
                    names(output) %in% c("ID", "Epochs", "SME", "EEG_Signal", collumns_to_keep)]
    # Unclear why, but some EEG_Signal scores are -Inf
    Subset$EEG_Signal[abs(Subset$EEG_Signal)==Inf] = NA
    Subset = Subset[complete.cases(Subset), ]

    Model_Result = lm(as.formula(lm_formula), 
                      Subset)
    
    AnovaModel = anova(Model_Result)
    # Expand Effect of Interest with additional factors (Hemisphere, Localisation... no Effect expected for Electrode)
    if ("Hemisphere" %in% collumns_to_keep) {
      Effect_of_Interest = paste0(Effect_of_Interest, ":Hemisphere")
    }
    if ("Localisation" %in% collumns_to_keep) {
      Effect_of_Interest = paste0(Effect_of_Interest, ":Localisation")
    }
    if ("FrequencyBand" %in% collumns_to_keep) {
      Effect_of_Interest = paste0(Effect_of_Interest, ":FrequencyBand")
    }

    Idx_Effect_of_Interest = which(rownames(AnovaModel) == Effect_of_Interest)
    p_Value = AnovaModel$`Pr(>F)`[Idx_Effect_of_Interest]
    
    Eta = eta_squared(Model_Result, partial = FALSE, alternative = "two.sided")
    Eta = Eta[Idx_Effect_of_Interest,]
    Eta = cbind( Eta$Eta2, Eta$CI_low, Eta$CI_high)
    
    if (length(Idx_Effect_of_Interest)==0) {
      p_Value = NA
      Eta = cbind(NA, NA, NA)
      
    }
    Estimates = cbind(Name_Test, Effect_of_Interest,Eta, p_Value, length(unique(Subset$ID)), mean(Subset$Epochs), sd(Subset$Epochs))
    colnames(Estimates) = c("Effect_of_Interest", "Statistical_Test", "Eta2", "CI_low", "CI90_high", "p_Value", "n_participants", "av_epochs", "sd_epochs")
    
    return (Estimates)
  }
  
  
  extract_StrongestCorrelation = function (SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Conditions, Average_Across_Conditions) {
    if (SignTest < 0.05){
      Subset = Correlations_Within_Conditions[which(Correlations_Within_Conditions$Task == Task &
                                                      Correlations_Within_Conditions$AnalysisPhase == AnalysisPhase),]
      if ("Localisation" %in% additional_Factors_Name) {
        Subset = Subset[which(Subset$Localisation == "Frontal"),]}
      
      Idx = which.max(Subset$Corelation_with_Personality)
      Extracted_Data = rbind(Extracted_Data, 
                             output[output$Task == Task &
                                      output$AnalysisPhase == AnalysisPhase &
                                      output$Condition == Subset$Condition[Idx],
                                    names(Average_Across_Conditions)])
      
    } else {
      Extracted_Data = rbind(Extracted_Data, 
                             Average_Across_Conditions[which(Average_Across_Conditions$Task == Task &
                                                               Average_Across_Conditions$AnalysisPhase == AnalysisPhase),] )
    }
    return(Extracted_Data)
  }
 
  #########################################################
  # (3) Prepare Averages across Conditions and Correlations
  #########################################################
  
  # For Hypotheses 1.5 and 2 Average across conditions and calculate Correlations per Condition
  
  
  GroupingVariables1 = c("Task", "AnalysisPhase", "ID", additional_Factors_Name, Covariate_Name, Personality_Name)
  GroupingVariables2 = c("Task", "AnalysisPhase", "Condition", additional_Factors_Name)
  GroupingVariables3 = c("Task", "AnalysisPhase", "Condition", "Condition2", additional_Factors_Name)  
  
  Average_Across_Conditions = output %>%
    group_by(across(all_of(GroupingVariables1))) %>%
    summarize(EEG_Signal = mean(EEG_Signal, na.rm = TRUE),
              SME = mean(SME, na.rm = TRUE),
              Epochs = mean(Epochs, na.rm = TRUE)) %>%
    ungroup()
  
  Correlations_Within_Conditions = output %>%
    group_by(across(all_of(GroupingVariables2))) %>%
    summarize(Corelation_with_Personality = cor.test(EEG_Signal, get(Personality_Name))$estimate) %>%
    ungroup()  

  Correlations_Within_Both_Conditions = output %>%
    group_by(across(all_of(GroupingVariables3))) %>%
    summarize(Corelation_with_Personality = cor.test(EEG_Signal, get(Personality_Name))$estimate) %>%
    ungroup()  %>% 
    unite(Condition, Condition, Condition2, sep = "_", remove = TRUE)


  #########################################################
  # (4) Test State Hypothesis
  #########################################################
  
  # Hypothesis 1.1 ASY Gambling Anticipation ~ Reward Magnitude
  Name_Test = c("Anticipation_Gambling")
  lm_formula =   paste( "EEG_Signal ~ (Condition", additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Gambling"
  AnalysisPhase = "Anticipation"
  collumns_to_keep = c("Condition", Covariate_Name, additional_Factors_Name)  # Personality_Name not needed for this
  Effect_of_Interest = "Condition"
  H1.1 = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
  # Hypothesis 1.2 ASY Gambling Consumption ~ Reward Magnitude * Feedback
  Name_Test = c("Consumption_Gambling_Valence")
  lm_formula =   paste( "EEG_Signal ~ (Condition * Condition2 ", additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Gambling"
  AnalysisPhase = "Consumption"
  collumns_to_keep = c("Condition", "Condition2", Covariate_Name, additional_Factors_Name)  # Personality_Name not needed for this
  Effect_of_Interest = "Condition2"
  H1.2.1 = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  Name_Test = c("Consumption_Gambling_Magnitude")
  Effect_of_Interest = "Condition"
  H1.2.2_prepA = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  Effect_of_Interest = "Condition:Condition2"
  H1.2.2_prepB = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  # Take the larger effects of the two (interaction or main effect of magnitude)
  if (!is.na(H1.2.2_prepA[3])) {
    if (H1.2.2_prepA[3]>H1.2.2_prepB[3]) {
    H1.2.2 = H1.2.2_prepA
  } else {
    H1.2.2 = H1.2.2_prepB
  } } else {
    H1.2.2 = H1.2.2_prepB
  }

  
  
  # Hypothesis 1.3 ASY Stroop Anticipation ~ Picture category (before)
  Name_Test = c("Anticipation_Stroop")
  lm_formula =   paste( "EEG_Signal ~ (Condition", additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Stroop"
  AnalysisPhase = "Anticipation"
  collumns_to_keep = c("Condition", Covariate_Name, additional_Factors_Name)  # Personality_Name not needed for this
  Effect_of_Interest = "Condition"
  H1.3 = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
  # Hypothesis 1.4 ASY Stroop Consumption ~ Picture category * Pleasure Ratings
  Name_Test = c("Consumption_Stroop")
  Behavior_Formula = paste("+ Condition * ", Behavior_Name,  collapse = ' ')
  lm_formula =  paste( "EEG_Signal ~ ((Condition", Behavior_Formula, ")", additional_Factor_Formula, ")", Covariate_Formula )
  Task = "Stroop"
  AnalysisPhase = "Consumption"
  collumns_to_keep = c("Condition", Covariate_Name, additional_Factors_Name, Behavior_Name)  # Personality_Name not needed for this
  Effect_of_Interest = "Condition"
  H1.4.1 = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  Name_Test = c("Consumption_Stroop_Rating")
  Effect_of_Interest = paste0("Condition:", Behavior_Name[idx_Valence = which(grepl("Pleasure", Behavior_Name))]) # Add Index if Arousal also modelled
  H1.4.2 = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
 
  
  # Hypothesis 1.5 ASY ~ Stroop Anticipation and Rest
  # Test Anticipation AV between Resting and other Task
  Name_Test = c("Anticipation_RestStroop")
  Task = c("Stroop", "Resting")
  lm_formula =   paste( "EEG_Signal ~ (Task", additional_Factor_Formula, ")", Covariate_Formula)
  AnalysisPhase = c("Anticipation", "NA")
  collumns_to_keep = c("Task", Covariate_Name, additional_Factors_Name)  # Personality_Name not needed for this
  Effect_of_Interest = "Task"
  H1.5.1 = test_Hypothesis( Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  Name_Test = c("Anticipation_RestGambling")
  Task = c("Gambling", "Resting")
  H1.5.2 = test_Hypothesis( Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  

  #########################################################
  # (5) Test Interaction with Personality for H2
  #########################################################
  
  # Hypothesis 2.1 ASY Gambling Anticipation ~ Reward Magnitude * Personality
  Name_Test = c("Personality_Anticipation_Gambling")
  lm_formula =   paste( "EEG_Signal ~ (Condition", Personality_Formula, additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Gambling"
  AnalysisPhase = "Anticipation"
  collumns_to_keep = c("Condition", Covariate_Name, additional_Factors_Name, Personality_Name) 
  Effect_of_Interest = paste0("Condition:",Personality_Name)
  H2.1_prep = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
 
  # Hypothesis 2.2 ASY Gambling Consumption ~ Reward Magnitude * Feedback
  Name_Test = c("Personality_Consumption_Gambling")
  lm_formula =   paste( "EEG_Signal ~ (Condition * Condition2 ", Personality_Formula, additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Gambling"
  AnalysisPhase = "Consumption"
  collumns_to_keep = c("Condition", "Condition2", Covariate_Name, additional_Factors_Name, Personality_Name)
  Effect_of_Interest = paste0("Condition2:",Personality_Name)
  H2.2.1_prep = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  Name_Test = c("Personality_Consumption_GamblingMagnitude")
  Effect_of_Interest = paste0("Condition:",Personality_Name)
  H2.2.2_prepA = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  Effect_of_Interest = paste0("Condition:Condition2:",Personality_Name)
  H2.2.2_prepB = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  # Hypothesis 2.3 ASY Stroop Anticipation ~ Picture category (before) * Personality
  Name_Test = c("Anticipation_Stroop")
  lm_formula =   paste( "EEG_Signal ~ (Condition", Personality_Formula, additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Stroop"
  AnalysisPhase = "Anticipation"
  collumns_to_keep = c("Condition", Covariate_Name, additional_Factors_Name, Personality_Name)  # Personality_Name not needed for this
  Effect_of_Interest = paste0("Condition:",Personality_Name)
  H2.3_prep = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  # Hypothesis 2.4 ASY Stroop Consumption ~ Picture category * Pleasure Ratings * Personality
  Name_Test = c("Consumption_Stroop")
  Behavior_Formula = paste("+ Condition * ", Behavior_Name,  collapse = ' ')
  lm_formula =  paste( "EEG_Signal ~ (((Condition", Behavior_Formula,  ")",Personality_Formula, ")", additional_Factor_Formula, ")", Covariate_Formula )
  Task = "Stroop"
  AnalysisPhase = "Consumption"
  collumns_to_keep = c("Condition", Covariate_Name, additional_Factors_Name, Personality_Name, Behavior_Name)  # Personality_Name not needed for this
  Effect_of_Interest = paste0("Condition:",Personality_Name)
  H2.4.1_prep = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  Name_Test = c("Consumption_Stroop_Rating")
  Effect_of_Interest = paste0("Condition:", Behavior_Name[idx_Valence = which(grepl("Pleasure", Behavior_Name))],":", Personality_Name) # Add Index if Arousal also modelled
  H2.4.2_prep = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
 
  
  #########################################################
  # (6) Prepare which Data should be compared to Resting
  #########################################################
  #(could be either AV across all conditions or condition with strongest correlation)
  
  Extracted_Data = output[output$Task == "Resting", names(Average_Across_Conditions) ] 
  # Hypothesis 2.1 ASY Gambling Anticipation ~ Reward Magnitude * Personality
  Task = "Gambling"
  AnalysisPhase = "Anticipation"
  SignTest = H2.1_prep[6]
  Extracted_Data =  extract_StrongestCorrelation(SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Conditions, Average_Across_Conditions)
  
  # Hypothesis 2.2 ASY Gambling Consumption ~ Reward Magnitude * Feedback
  Task = "Gambling"
  AnalysisPhase = "Consumption"
  # Take the larger effects of the two (interaction or main effect of magnitude)
  if (H2.2.2_prepA[3]>H2.2.2_prepB[3]) { # Main Effect
    SignTest = H2.2.2_prepA[6]
    Extracted_Data =  extract_StrongestCorrelation(SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Conditions, Average_Across_Conditions)
  } else { # Interaction
    SignTest = H2.2.2_prepB[6]
    Extracted_Data =  extract_StrongestCorrelation(SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Both_Conditions , Average_Across_Conditions)
  }
  
  # Hypothesis 2.3 ASY Stroop Anticipation ~ Picture category (before) * Personality
  Task = "Stroop"
  AnalysisPhase = "Anticipation"
  SignTest = H2.3_prep[6]
  Extracted_Data =  extract_StrongestCorrelation(SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Conditions, Average_Across_Conditions)
  
  
  # Hypothesis 2.4 ASY Stroop Consumption ~ Picture category * Pleasure Ratings * Personality
  Task = "Stroop"
  AnalysisPhase = "Consumption"
  SignTest = H2.4.1_prep[6]
  Extracted_Data =  extract_StrongestCorrelation(SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Conditions, Average_Across_Conditions)
  
  
  #########################################################
  # (7) Compare Association to Personality for different Phases
  #########################################################
  lm_formula =   paste( Personality_Name, " ~ ((Task * EEG_Signal)",additional_Factor_Formula, ")", Covariate_Formula)
  collumns_to_keep = c("Task", Covariate_Name, additional_Factors_Name, Personality_Name)
  Effect_of_Interest = paste0("Task:EEG_Signal")
  
  # Hypothesis 2.1 ASY Gambling Anticipation ~ Reward Magnitude * Personality
  Task = c("Gambling", "Resting")
  AnalysisPhase = c("Anticipation", "NA")
  Name_Test = c("Anticipation_RestGambling_Personality")
  H2.1 = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
  # Hypothesis 2.2 ASY Gambling Consumption ~ Reward Magnitude * Feedback  
  Task = c("Gambling", "Resting")
  AnalysisPhase = c("Consumption", "NA")
  Name_Test = c("Consumption_RestGambling_Personality")
  H2.2 = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
  # Hypothesis 2.3 ASY Stroop Anticipation ~ Picture category (before) * Personality
  Task = c("Stroop", "Resting")
  AnalysisPhase = c("Anticipation", "NA")
  Name_Test = c("Anticipation_RestStroop_Personality")
  H2.3 = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  # Hypothesis 2.4 ASY Stroop Consumption ~ Picture category * * Personality
  Task = c("Stroop", "Resting")
  AnalysisPhase = c("Consumption", "NA")
  Name_Test = c("Consumption_RestStroop_Personality")
  H2.4 = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  # Not a hypothesis but still add Association with Resting
  Task = c("Resting")
  AnalysisPhase = c("NA")
  lm_formula =   paste( Personality_Name, " ~ ((EEG_Signal)",additional_Factor_Formula, ")", Covariate_Formula)
  Name_Test = c("Resting_Personality")
  Effect_of_Interest = paste0("EEG_Signal")
  H2.5x = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
  #########################################################
  # (8) Correct for Multiple Comparisons for Hypothesis 1
  #########################################################
  
  Estimates_H1 = as.data.frame(rbind(H1.1, H1.2.1, H1.2.2,  H1.3, H1.4.1,  H1.4.2))

  comparisons = 6
  if (choice == "Holmes"){
    Estimates_H1$p_Value = p.adjust(Estimates_H1$p_Value, method = "holm", n = comparisons)
  }  else if (choice == "Bonferroni"){
    Estimates_H1$p_Value = p.adjust(Estimates_H1$p_Value, method = "bonferroni", n = comparisons)
  }
  
  Estimates = rbind(Estimates_H1, H1.5.1, H1.5.2, H2.1,H2.2, H2.3, H2.4, H2.5x )
  
  
  #########################################################
  # (9) Export as CSV file
  #########################################################
  FileName= unlist(input$stephistory["Final_File_Name"])
  write.csv(Estimates,FileName, row.names = FALSE)
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = Estimates,
    stephistory = stephistory
  ))
}
