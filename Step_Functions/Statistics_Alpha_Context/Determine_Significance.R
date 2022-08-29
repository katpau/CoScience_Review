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
  # Names are used to select relevant columns
  # Formula (parts) are used to be put together and parsed to the lm() function,
  # thats why they have to be added by a * or +
  
  # Get column Names for Personality Data (to to be used in the model formula)
  Personality_Name = names(output)[names(output) %like% "Personality_"]
  Personality_Formula = paste("* ", Personality_Name)
  
  # Get column Names for Behavioural Data
  Behavior_Name = names(output)[names(output) %like% "Behav_"]
  # Behavior Formula is built later

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
  }else { 
    Covariate_Name = names(output)[names(output) %like% "Covariate_"]
    Covariate_Formula = ""
  for (iCov in Covariate_Name) {
    Covariate_Formula = paste(Covariate_Formula, "*", iCov, " ")
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
  
  
  test_Hypothesis = function (Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase, SaveUseModel, ModelProvided) {
    # this function is used to export the relevant estimates from the tested model or the model (determined by SaveUseModel)
    # Name_Test is the Name that will be added as first collumn, to identify tests across forks, str (next to the actual interaction term)
    # lm_formula contains the formula that should be given to the lm, str
    # output contains (subset) of the data, df
    # Effect_of_Interest is used to identify which estimate should be exported, array of str.
    #             the effect is extended by any potential additional factors (hemisphere, electrode...)
    # collumns_to_keep lists the relevant collums in output, these will be checked for completedness, array of str
    # Task is used to select the relevant rows in output, array of str
    # AnalysisPhase is used to select the relevant rows in output, array of str
    # SaveUseModel, can be added or left out, options are 
    #           "default" (Model is calculated), 
    #           "exportModel", then model (not estimates) are returned (and Effect of interest and Name_Test are not used)
    #           "previousModel", then model is not recalculated but the provided one is used
    # ModelProvided only needed if SaveUseModel is set to "previousModel", output of lm()
    
    # Set relevant Input if not given
    if(missing(SaveUseModel)) { SaveUseModel = "default"  }
    
    # Drop Localisation and Electrode if both of them are given
    if (any(grepl("Localisation ", collumns_to_keep)) & any(grepl("Electrode", collumns_to_keep)) ) {
      collumns_to_keep = collumns_to_keep[!collumns_to_keep == "Localisation"]  }
    

      # Select relevant data and make sure its complete
      # First select Rows based on Task and Analysisphase
      Subset = output[output$Task %in% Task & output$AnalysisPhase %in% AnalysisPhase ,
                      names(output) %in% c("ID", "Epochs", "SME", "EEG_Signal", collumns_to_keep)]
      colNames_all = names(Subset)
      # Second select columns based
      relevant_collumns = c("EEG_Signal", colNames_all[grepl("Personality_", colNames_all)],  colNames_all[grepl("Covariate_", colNames_all)])
      # Third make sure cases are complete
      Subset = Subset[complete.cases(Subset[,relevant_collumns]), ]
      
      # Calculate LM Model
      if (!SaveUseModel == "previousModel"){      
      # If Model contains Electrodes AND Localisation, adjust formula (they are not orthogonal!)
      if (any(grepl("Localisation ", lm_formula)) & any(grepl("Electrode", lm_formula))) {
        lm_formula = gsub("\\* Localisation", "", lm_formula)     }

      # Calculate LM Model
      Model_Result = lm(as.formula(lm_formula), 
                        Subset)
      # Get coefficients
      AnovaModel = anova(Model_Result) 
      
      # If Model is provided, get it here
    } else {
      Model_Result = ModelProvided
      AnovaModel = anova(Model_Result) 
    }
    
    # if only model is exported, stop here
    if (SaveUseModel == "exportModel")  {
      return(Model_Result)
      
    # otherwise prepare export of parameters
    } else { 
    
    # Expand Effect of Interest by additional factors
    if ("Hemisphere" %in% collumns_to_keep) {
      Effect_of_Interest = c(Effect_of_Interest, "Hemisphere")  }
    if ("Localisation" %in% collumns_to_keep) {
      Effect_of_Interest = c(Effect_of_Interest, "Localisation")  }
    if ("Electrode" %in% collumns_to_keep) {
      Effect_of_Interest = c(Effect_of_Interest, "Electrode")  } # Or should we drop Electrode?
    Effect_of_Interest = unique(Effect_of_Interest)
    # Do not add other factors (Frequency Band)
    # These are different hypotheses. We are only focused 
    # on frontal alpha asymmetry.)
    
    
    # Find index of effect of interest for frontal alpha Asymmetry (and the indicated Conditions)
    Interest = rowSums(sapply(X = Effect_of_Interest, FUN = grepl, rownames(AnovaModel)))
    NrFactors = lengths(strsplit(rownames(AnovaModel), ":"))
    Idx_Effect_of_Interest = which(Interest == length(Effect_of_Interest) & NrFactors == length(Effect_of_Interest))
    
    # Get Etas
    Eta = eta_squared(Model_Result, partial = FALSE, alternative = "two.sided")
    Eta = Eta[Idx_Effect_of_Interest,]
    Eta = cbind( Eta$Eta2, Eta$CI_low, Eta$CI_high)
    
    # Get p value
    p_Value = AnovaModel$`Pr(>F)`[Idx_Effect_of_Interest]
    
    # some trouble shooting if Effect was not found
    if (length(Idx_Effect_of_Interest)==0) {
      p_Value = NA
      Eta = cbind(NA, NA, NA)    }
    
    # prepare export
    Estimates = cbind.data.frame(Name_Test, rownames(AnovaModel)[Idx_Effect_of_Interest],Eta, p_Value, length(unique(Subset$ID)), mean(Subset$Epochs), sd(Subset$Epochs))
    colnames(Estimates) = c("Effect_of_Interest", "Statistical_Test", "Eta2", "CI_low", "CI90_high", "p_Value", "n_participants", "av_epochs", "sd_epochs")
    
      return (Estimates)
    }
  }
  
  ###########################
  # For Hypothesis Set 2, the tests are conducted on the condition of the strongest correlation (if it was significant, otherwise the main effect)
  extract_StrongestCorrelation = function (SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Conditions, Average_Across_Conditions) {
    # This Function takes SignTest (the test of the interaction term with condition), if it is significant, the strongest correlation is found and exported
    if (SignTest < 0.05){
      Subset = Correlations_Within_Conditions[which(Correlations_Within_Conditions$Task == Task &
                                                      Correlations_Within_Conditions$AnalysisPhase == AnalysisPhase),]
      
      # only take frontal values!
      if ("Localisation" %in% additional_Factors_Name || "Elecrode" %in% additional_Factors_Name) {
        Subset = Subset[which(Subset$Localisation == "Frontal"),]}
      
      # Find Condition with highest correlation
      Idx = which.max(Subset$Correlation_with_Personality)
      # Take only data from that condition
      Extracted_Data = rbind(Extracted_Data, 
                             output[output$Task == Task &
                                      output$AnalysisPhase == AnalysisPhase &
                                      output$Condition == Subset$Condition[Idx],
                                    names(Average_Across_Conditions)])
      
    } else {
      # if no interaction significant, simply take average
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
  
  
  GroupingVariables1 = c("Task", "AnalysisPhase", "ID", additional_Factors_Name)
  GroupingVariables2 = c("Task", "AnalysisPhase", "Condition", additional_Factors_Name)
  GroupingVariables3 = c("Task", "AnalysisPhase", "Condition", "Condition2", additional_Factors_Name)  
  
  Average_Across_Conditions = output %>%
    group_by(across(all_of(GroupingVariables1))) %>%
    summarize(EEG_Signal = mean(EEG_Signal, na.rm = TRUE),
              SME = mean(SME, na.rm = TRUE),
              Epochs = mean(Epochs, na.rm = TRUE)) %>%
    ungroup()
  
  # Add Covariates back
  # this is done across subjects and there should be only one value per Subject when normalizing
  Relevant_Collumns =  names(output)[grep(c("Personality_|Covariate_"), names(output))]
  Personality = unique(output[,c("ID", Relevant_Collumns )])
  
  Average_Across_Conditions = merge(Average_Across_Conditions,  Personality, by = c("ID"),
                                    all.x = TRUE,  all.y = FALSE )
  
  # Calculate Correlations with Personality Variables
  Correlations_Within_Conditions = output %>%
    group_by(across(all_of(GroupingVariables2))) %>%
    summarize(Correlation_with_Personality = cor.test(EEG_Signal, get(Personality_Name))$estimate) %>%
    ungroup()  

  Correlations_Within_Both_Conditions = output %>%
    group_by(across(all_of(GroupingVariables3))) %>%
    summarize(Correlation_with_Personality = cor.test(EEG_Signal, get(Personality_Name))$estimate) %>%
    ungroup()  %>% 
    unite(Condition, Condition, Condition2, sep = "_", remove = TRUE)
  

  #########################################################
  # (4) Test State Hypothesis
  #########################################################
  
  # Hypothesis 1.1 ASY Gambling Anticipation ~ Reward Magnitude
  # In the gambling task, ASY during the anticipation of feedback will be larger when more money is at
  # stake compared to less (50 vs. 10 vs. 0 points)
  Name_Test = c("Anticipation_Gambling")
  lm_formula =   paste( "EEG_Signal ~ (Condition", additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Gambling"
  AnalysisPhase = "Anticipation"
  collumns_to_keep = c("Condition", Covariate_Name, additional_Factors_Name)  
  Effect_of_Interest = "Condition"
  H1.1 = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  # Hypothesis 1.2 ASY Gambling Consumption ~ Reward Magnitude * Feedback Type
  lm_formula =   paste( "EEG_Signal ~ (Condition * Condition2 ", additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Gambling"
  AnalysisPhase = "Consumption"
  collumns_to_keep = c("Condition", "Condition2", Covariate_Name, additional_Factors_Name) 
  H1.2_Model = test_Hypothesis( "",lm_formula, output, "", collumns_to_keep, Task, AnalysisPhase, "exportModel")
  
  # In the gambling task, ASY during the consumption of feedback will be larger immediately after
  # rewards compared to losses
  # Test for Valence
  Effect_of_Interest = "Condition2"
  Name_Test = c("Consumption_Gambling_Valence")
  H1.2.1 = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase, "previousModel", H1.2_Model)
  
  
  # and for rewards of high magnitude (50 points) compared to rewards of low magnitude (10 points)
  # Test for Magnitude
  Name_Test = c("Consumption_Gambling_Magnitude")
  Effect_of_Interest = "Condition:"
  H1.2.2_prepA = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase, "previousModel", H1.2_Model)
  # Test for Interaction  
  Effect_of_Interest = c("Condition:", "Condition2")
  H1.2.2_prepB = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase,"previousModel", H1.2_Model)
  
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
  # In the emotional stroop task, ASY during the anticipation of a picture will be larger when followed by
  # positive (and erotic) pictures compared to neutral pictures
  Name_Test = c("Anticipation_Stroop")
  lm_formula =   paste( "EEG_Signal ~ (Condition", additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Stroop"
  AnalysisPhase = "Anticipation"
  collumns_to_keep = c("Condition", Covariate_Name, additional_Factors_Name)  # Personality_Name not needed for this
  Effect_of_Interest = "Condition"
  H1.3 = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
  # # Hypothesis 1.4 ASY Stroop Consumption ~ Picture category * Pleasure Ratings
  # In the emotional stroop task, ASY during the consumption of a picture will be larger for positive (and
  # erotic) pictures compared to neutral pictures. This relationship could be possibly moderated by pleasantness ratings 
  # for the pictures, i.e. the pleasantness ratings of the categories drive the effect.
  
  if (!(input$stephistory[["BehavCovariate"]]== "pleasant_arousal_av")) {
     Behavior_Formula = paste("+ Condition * ", Behavior_Name,  collapse = ' ')
     lm_formula =  paste( "EEG_Signal ~ ((Condition", Behavior_Formula, ")", additional_Factor_Formula, ")", Covariate_Formula )
  } else { # if Average per condition, the factor condition is irrelevant
     lm_formula =  paste( "EEG_Signal ~ ((", paste(Behavior_Name, collapse = "+"), ")", additional_Factor_Formula, ")", Covariate_Formula )
  }
  
  Task = "Stroop"
  AnalysisPhase = "Consumption"
  collumns_to_keep = c("Condition", Covariate_Name, additional_Factors_Name, Behavior_Name)  
  H1.4_Model = test_Hypothesis( "",lm_formula, output, "", collumns_to_keep, Task, AnalysisPhase, "exportModel")
  
  Name_Test = c("Consumption_Stroop")
  Effect_of_Interest = "Condition"
  if (!(input$stephistory[["BehavCovariate"]]== "pleasant_arousal_av")) {
  H1.4.1 = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase, "previousModel", H1.4_Model)
  } else {
    # if Rating's averages across subjects are used to model, then there is no condition predictor!
    H1.4.1 = c(Name_Test, NA, NA, NA, NA, NA, NA, NA, NA)
  }
  
  
  Name_Test = c("Consumption_Stroop_Rating")
  if (!(input$stephistory[["BehavCovariate"]]== "pleasant_arousal_av")) { 
    Effect_of_Interest = c("Condition", Behavior_Name[idx_Valence = which(grepl("Pleasure", Behavior_Name))]) 
  } else {
    # if Rating's averages across subjects are used to model, then there is no condition predictor!
    Effect_of_Interest = c( Behavior_Name[idx_Valence = which(grepl("Pleasure", Behavior_Name))]) 
    }
  H1.4.2 = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase, "previousModel", H1.4_Model)
 
  
  # Hypothesis 1.5 ASY ~ Stroop Anticipation and Rest
  # Test Anticipation AV between Resting and other Task
  # In the emotional stroop task, ASY during anticipation of a picture will be larger than during rest.
  Name_Test = c("Anticipation_RestStroop")
  Task = c("Stroop", "Resting")
  lm_formula =   paste( "EEG_Signal ~ (Task", additional_Factor_Formula, ")", Covariate_Formula)
  AnalysisPhase = c("Anticipation", "NA")
  collumns_to_keep = c("Task", Covariate_Name, additional_Factors_Name)  
  Effect_of_Interest = "Task"
  H1.5.1 = test_Hypothesis( Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  # Add also for Gambling, even if not a hypothesis?
  Name_Test = c("Anticipation_RestGambling")
  Task = c("Gambling", "Resting")
  H1.5.2 = test_Hypothesis( Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  

  #########################################################
  # (5) Test Interaction with Personality for H2 
  #########################################################
  # To test for the specify of the Association between BAS and the separate conditions
  # within the task, the models outlined in 15) will be extended by the factor BAS. If there is a significant
  # interaction between any of the manipulated conditions and BAS, only the ASY scores of the condition
  # with the largest positive association will be included for the following comparisons. If no interaction
  # emerges, the average across all conditions is used
  
  # Hypothesis 2.1 ASY Gambling Anticipation ~ Reward Magnitude * Personality
  Task = "Gambling"
  AnalysisPhase = "Anticipation"
  collumns_to_keep = c("Condition", Covariate_Name, additional_Factors_Name, Personality_Name) 
  lm_formula =   paste( "EEG_Signal ~ (Condition", Personality_Formula, additional_Factor_Formula, ")", Covariate_Formula)
  Effect_of_Interest = c("Condition", Personality_Name)
  Name_Test = "Anticipation_Gambling_Magnitude_Personality"
  H2.1_prep = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  # Hypothesis 2.2 ASY Gambling Consumption ~ Reward Magnitude * Feedback Type
  lm_formula =   paste( "EEG_Signal ~ (Condition * Condition2", Personality_Formula, additional_Factor_Formula, ")", Covariate_Formula)
  AnalysisPhase = "Consumption"
  collumns_to_keep = c("Condition", "Condition2", Covariate_Name, additional_Factors_Name, Personality_Name) 
  H2.2_Model = test_Hypothesis( "",lm_formula, output, "", collumns_to_keep, Task, AnalysisPhase, "exportModel")
  
  # Test for Valence
  Name_Test = c("Consumption_Gambling_Valence_Personality")
  Effect_of_Interest = c("Condition2", Personality_Name)
  H2.2.1 = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.2_Model)
  # Test for Magnitude
  Name_Test = c("Consumption_Gambling_Magnitude_Personality")
  Effect_of_Interest = c("Condition:", Personality_Name)
  H2.2.2_prepA = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.2_Model)
  # Test for Interaction  
  Effect_of_Interest = c("Condition:", "Condition2", Personality_Name)
  H2.2.2_prepB = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase,"previousModel", H2.2_Model)


  # Hypothesis 2.3 ASY Stroop Anticipation ~ Picture category (before) * Personality 
  Name_Test = c("Anticipation_Stroop")
  lm_formula =   paste( "EEG_Signal ~ (Condition", Personality_Formula, additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Stroop"
  AnalysisPhase = "Anticipation"
  collumns_to_keep = c("Condition", Covariate_Name, additional_Factors_Name, Personality_Name)
  Effect_of_Interest = c("Condition", Personality_Name)
  H2.3_prep  = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
  # # Hypothesis 2.4 ASY Stroop Consumption ~ Picture category * Personality (*Behaviour)
  Name_Test = c("Consumption_Stroop")
  Task = "Stroop"
  AnalysisPhase = "Consumption"
  collumns_to_keep = c("Condition", Covariate_Name, additional_Factors_Name, Personality_Name, Behavior_Name)
  if (!(input$stephistory[["BehavCovariate"]]== "pleasant_arousal_av")) {
    Behavior_Formula = paste("+ Condition * ", Behavior_Name,  collapse = ' ')
    lm_formula =  paste( "EEG_Signal ~ (((Condition", Behavior_Formula, ")",Personality_Formula, ")", additional_Factor_Formula, ")", Covariate_Formula )
  } else { # if Average per condition, the factor condition is irrelevant
    lm_formula =   paste( "EEG_Signal ~ (((Behav_Arousal +   Behav_Pleasure)",Personality_Formula, ")", additional_Factor_Formula, ")", Covariate_Formula )
  }
  H2.4_Model = test_Hypothesis( "",lm_formula, output, "", collumns_to_keep, Task, AnalysisPhase, "exportModel")
  
  # Take main effect of condition 
  Effect_of_Interest = c("Condition", Personality_Name)
  
  if (!(input$stephistory[["BehavCovariate"]]== "pleasant_arousal_av")) { 
    Effect_of_Interest = c("Condition",Personality_Name) 
  } else {
    # if Rating's averages across subjects are used to model, then there is no condition predictor!
    Effect_of_Interest = c( Behavior_Name[idx_Valence = which(grepl("Pleasure", Behavior_Name))], Personality_Name) 
  }
  H2.4_prep  = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.4_Model)
  

  
  #########################################################
  # (6) Prepare which Data should be compared to Resting
  #########################################################
  #(could be either AV across all conditions or condition with strongest correlation, depends on interaction)
  
  # Resting data is taken as it is
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
  
  
  # Hypothesis 2.4 ASY Stroop Consumption ~ Picture category * Personality
  Task = "Stroop"
  AnalysisPhase = "Consumption"
  SignTest = H2.4_prep[6]
  Extracted_Data =  extract_StrongestCorrelation(SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Conditions, Average_Across_Conditions)

  
  #########################################################
  # (7) Compare Association to Personality for different Phases
  #########################################################
  lm_formula =   paste( Personality_Name, " ~ ((Task * EEG_Signal)",additional_Factor_Formula, ")", Covariate_Formula)
  collumns_to_keep = c("Task", Covariate_Name, additional_Factors_Name, Personality_Name)
  Effect_of_Interest = c("Task", "EEG_Signal")
  
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
  
  # Hypothesis 2.4 ASY Stroop Consumption ~ Picture category * Personality
  Task = c("Stroop", "Resting")
  AnalysisPhase = c("Consumption", "NA")
  Name_Test = c("Consumption_RestStroop_Personality")
  H2.4 = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  # Not a hypothesis but still add Association with Resting
  Task = c("Resting")
  AnalysisPhase = c("NA")
  lm_formula =   paste( Personality_Name, " ~ ((EEG_Signal)",additional_Factor_Formula, ")", Covariate_Formula)
  Name_Test = c("Resting_Personality")
  Effect_of_Interest = "EEG_Signal"
  H2.5x = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
  #########################################################
  # (8) Correct for Multiple Comparisons for Hypothesis 1
  #########################################################
  
  Estimates_H1 = as.data.frame(rbind(H1.1, H1.2.1, H1.2.2,  H1.3, H1.4.1,  H1.4.2))
  comparisons = sum(!is.na(Estimates_H1$p_Value))
  
  if (choice == "Holmes"){
    Estimates_H1$p_Value = p.adjust(Estimates_H1$p_Value, method = "holm", n = comparisons)
  }  else if (choice == "Bonferroni"){
    Estimates_H1$p_Value = p.adjust(Estimates_H1$p_Value, method = "bonferroni", n = comparisons)
  }
  
  Estimates = rbind(Estimates_H1, H1.5.1, H1.5.2, H2.1,H2.2, H2.3, H2.4, H2.5x )
  
  
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
