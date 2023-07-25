Determine_Significance = function(input = NULL, choice = NULL) {
  StepName = "Determine_Significance"
  Choices = c("Holm", "Bonferroni", "None")
  Order = 13
  output = input$data
  names(output)[names(output)=="Condition"] = "Condition1"

  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:
  
  # Handles all Choices listed above 
  # Runs the statistical Test, corrects for multiple comparisons and 
  # Prepares Output Table
  
  # (1) Get Names and Formulas of variable Predictors
  # (2) Initiate Functions for Hypothesis Testing
  # (3) Prepare Averages across Condition1s and Correlations
  # (4) Test State Hypothesis (H1)
  # (5) Test Interaction with Personality in preparation for H2
  # (6) Prepare which Data should be compared to Resting (could be either AV across all Condition1s or Condition1 with strongest correlation)
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
  } else { 
    Covariate_Name = names(output)[names(output) %like% "Covariate_"]
    if (length(Covariate_Name)  > 1) {
      Covariate_Formula = paste("*(", paste(Covariate_Name, collapse = " + "), ")")
    } else {
      Covariate_Formula = paste( "*", Covariate_Name)
    }
  }
  
  
  # Get possible additional factors to be included in the GLM (depends on the forking
  # if e.g. no difference scores were calculated, then hemisphere should be added.
  # these have been determined at earlier step (Covariate) when determining the grouping variables)
  additional_Factors_Name = input$stephistory[["additional_Factors_Name"]]
  additional_Factor_Formula = input$stephistory[["additional_Factor_Formula"]]
  
 
  
  #########################################################
  # (2) Prepare Stat Function to test Hypothesis
  #########################################################
  
  wrap_test_Hypothesis = function (Name_Test,lm_formula,  Data, Effect_of_Interest, DirectionEffect,
                                   collumns_to_keep, Task, AnalysisPhase,  SaveUseModel, ModelProvided) {
    # wrapping function to parse specific Information to the test_Hypothesis Function
    # Does three things: (1) Select Subset depending on Conditions and Tasks ans Analysis Phase
    # (2) Test the Hypothesis/Calculate Model and 
    # (3) Checks the direction of the effects
    # Inputs:
    # Name_Test is the Name that will be added as first collumn, to identify tests across forks, str (next to the actual interaction term)
    # lm_formula contains the formula that should be given to the lm, str
    # Data contains data (that will be filtered), df
    # Effect_of_Interest is used to identify which estimate should be exported, array of str.
    #             the effect is extended by any potential additional factors (hemisphere, electrode...)
    # DirectionEffect is a list with the following named elements:
    #               Effect - char to determine what kind of test, either main, interaction, correlation, interaction_correlation, interaction2_correlation
    #               Personality - char name of personality collumn
    #               Larger - array of 2 chars: first name of collumn coding condition, second name of factor with larger effect
    #               Smaller - array of 2 chars: first name of collumn coding condition, second name of factor with smaller effect
    #               Interaction - array of 3 chars: first name of collumn coding condition additional to Larger/Smaller, second name of factor with smaller effect, third with larger effect
    # collumns_to_keep lists all collumns that should be checked for completeness, array of str
    # Task lists the tasks included in this test, array of str
    # AnalysisPhase lists the analysis phase included in this test, array of str
    # SaveUseModel, can be added or left out, options are 
    #           "default" (Model is calculated), 
    #           "exportModel", then model (not estimates) are returned (and Effect of interest and Name_Test are not used)
    #           "previousModel", then model is not recalculated but the provided one is used
    
    # ModelProvided only needed if SaveUseModel is set to "previousModel", output of lm()
    if(missing(SaveUseModel)) { SaveUseModel = "default"  }
    if(missing(ModelProvided)) { ModelProvided = "none"  }
    
    
    # Create Subset
    Subset = Data[Data$Task %in% Task & Data$AnalysisPhase %in% AnalysisPhase ,
                  names(Data) %in% c("ID", "Epochs", "SME", "EEG_Signal", collumns_to_keep, "Lab")]
    
    # Run Test
    ModelResult = test_Hypothesis( Name_Test,lm_formula, Subset, Effect_of_Interest, SaveUseModel, ModelProvided)
    
    # Test Direction
    if (!SaveUseModel == "exportModel") {
      if(!is.character(ModelResult) &&  any(!grepl( "Error", ModelResult))) {
        if(!is.na(ModelResult$value_EffectSize)){
      ModelResult = test_DirectionEffect(DirectionEffect, Subset, ModelResult) 
    }}}
    
    return(ModelResult)
  }
  
  #########################################################
  # (3.0) Recode Gambling Consumption, so that First Condition is Valence (The more important one!)
  #########################################################
  # For Consumption make Condition1 Valence, not Magnitude!
  BU = output
  output$Condition1[output$Task == "Gambling" &
                      output$AnalysisPhase == "Consumption"] = 
    BU$Condition2[output$Task == "Gambling"&
                    output$AnalysisPhase == "Consumption"]
  output$Condition2[output$Task == "Gambling" &
                                      output$AnalysisPhase == "Consumption"] = 
    BU$Condition1[output$Task == "Gambling"&
                    output$AnalysisPhase == "Consumption"]
  rm(BU)  
  
  #########################################################
  # (3.1) Prepare Averages across Conditions [for comparing to Resting]
  #########################################################
  GroupingVariables1 = c("Task", "AnalysisPhase", "ID", additional_Factors_Name)
  
  Average_Across_Conditions = output %>%
    group_by(across(all_of(GroupingVariables1))) %>%
    summarize(EEG_Signal = mean(EEG_Signal, na.rm = TRUE),
              SME = mean(SME, na.rm = TRUE),
              Epochs = mean(Epochs, na.rm = TRUE),
              Lab = Lab[1],
              ) %>%
    ungroup()
  
  # Add Covariates to Averages_Across (as there could be many to none, do it like that)
  Relevant_Collumns =  names(output)[grep(c("Personality_|Covariate_"), names(output))]
  Personality = unique(output[,c("ID", Relevant_Collumns )])
  Average_Across_Conditions = merge(Average_Across_Conditions,  Personality, by = c("ID"),
                                    all.x = TRUE,  all.y = FALSE )
  
  #########################################################
  # (3.2) Prepare Correlations for each Condition (if significant in lmer, then take the largest later)
  #########################################################
  GroupingVariables2 = c("Task", "AnalysisPhase", "Condition1")
  
  output_for_Correlation = output %>%
                         filter(!is.na(EEG_Signal),
                                !is.na(Personality_Name[1]), # Get only first in case there are multiple in Factor Analysis
                                Localisation == "Frontal") %>% # Get only Frontal Ones
                         group_by(Task, AnalysisPhase, Condition1,Condition2, Hemisphere, ID) %>%
                         summarise(EEG_Signal = mean(EEG_Signal, na.rm =TRUE),
                                   Personality = .data[[Personality_Name[1]]][1])  # Get average across different electrodes?
  
  # If not Diff, calculate Diff
  if (length(unique(output_for_Correlation$Hemisphere))>1) {
    output_for_Correlation = spread(output_for_Correlation, Hemisphere, EEG_Signal)
    output_for_Correlation$EEG_Signal = output_for_Correlation$right - output_for_Correlation$left
  }
 
  # Calculate Correlations with Personality Variables
  Correlations_Within_Conditions = output_for_Correlation %>%
    group_by(across(all_of(GroupingVariables2)), .drop = TRUE) %>%
    filter(length(unique(ID))>3)%>% 
    summarize(Correlation_with_Personality = cor.test(EEG_Signal, Personality)$estimate) %>%
    ungroup()  
  
  # Calculate Correlations with Personality Variables for two Conditions (for Gambling)
  Correlations_Within_Both_Conditions = output_for_Correlation %>%
    filter(Task == "Gambling",
           AnalysisPhase == "Consumption") %>%
    unite(Condition1, Condition1, Condition2, sep = "_", remove = TRUE) %>%
    group_by(across(all_of(GroupingVariables2))) %>%
    filter(length(unique(ID))>3)%>% 
    summarize(Correlation_with_Personality = cor.test(EEG_Signal, Personality)$estimate) %>%
    ungroup() 
  

 
  
  #########################################################
  # (4) Test State Hypothesis 
  #########################################################
  print("Test State Hypotheses")
  # Hypothesis 1.1 ASY Gambling Anticipation ~ Reward Magnitude
  # In the gambling task, ASY during the anticipation of feedback will be larger when more money is at
  # stake compared to less (50 vs. 10 vs. 0 points)
  Name_Test = c("State_Gambling_Anticipation")
  lm_formula =   paste( "EEG_Signal ~ (Condition1", additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Gambling"
  AnalysisPhase = "Anticipation"
  collumns_to_keep = c("Condition1", Covariate_Name, additional_Factors_Name)  
  Effect_of_Interest = "Condition1"
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Condition1", "0"),
                         "Smaller" = c("Condition1", "50"))
  
  H1.1_Mag = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                               DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  

  
  
  # Hypothesis 1.2 ASY Gambling Consumption ~ Reward Magnitude * Feedback Type
  lm_formula =   paste( "EEG_Signal ~ (Condition1 * Condition2 ", additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Gambling"
  AnalysisPhase = "Consumption"
  collumns_to_keep = c("Condition1", "Condition2", Covariate_Name, additional_Factors_Name) 
  
  H1.2_Model = wrap_test_Hypothesis("",lm_formula, output, "", "", 
                              collumns_to_keep, Task, AnalysisPhase,
                              "exportModel")
 
  
  # In the gambling task, ASY during the consumption of feedback will be larger immediately after
  # rewards compared to losses
  # Test for Valence
  Effect_of_Interest = "Condition1"
  Name_Test = c("State_Gambling_Consumption-Valence")
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Condition1", "Win"),
                         "Smaller" = c("Condition1", "Loss"))
  
  H1.2_Val = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                              DirectionEffect, collumns_to_keep, Task, AnalysisPhase,
                              "previousModel", H1.2_Model)
  
  # and for rewards of high magnitude (50 points) compared to rewards of low magnitude (10 points)
  # Test for Magnitude
  Name_Test = c("State_Gambling_Consumption-Magnitude")
  Effect_of_Interest = "Condition2"
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Condition2", "0"),
                         "Smaller" = c("Condition2", "50"))
  
  H1.2_prepMag = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                DirectionEffect, collumns_to_keep, Task, AnalysisPhase,
                                "previousModel", H1.2_Model)
  
  
  # Test for Interaction  
  Effect_of_Interest = c("Condition1", "Condition2")
  DirectionEffect = list("Effect" = "interaction",
                         "Larger" = c("Condition1", "Win"),
                         "Smaller" = c("Condition1", "Loss"),
                         "Interaction" = c("Condition2", "0", "50"))
  H1.2_prepMagVal = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                      DirectionEffect, collumns_to_keep, Task, AnalysisPhase,
                                      "previousModel", H1.2_Model)
  
  # Take the larger effects of the two (interaction or main effect of magnitude)
  ToCompare = rbind(H1.2_prepMag,H1.2_prepMagVal)
  ToCompare = ToCompare[which(!is.na(ToCompare$value_EffectSize)),]
  if (nrow(ToCompare)>0) {
    H1.2_Mag = ToCompare[which.max(ToCompare$value_EffectSize),] 
  } else {
    H1.2_Mag = H1.2_prepMag
  }
  

  # Hypothesis 1.3 ASY Stroop Anticipation ~ Picture category (before)
  # In the emotional stroop task, ASY during the anticipation of a picture will be larger when followed by
  # positive (and erotic) pictures compared to neutral pictures
  Name_Test = c("State_Stroop_Anticipation")
  lm_formula =   paste( "EEG_Signal ~ (Condition1", additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Stroop"
  AnalysisPhase = "Anticipation"
  collumns_to_keep = c("Condition1", Covariate_Name, additional_Factors_Name)  # Personality_Name not needed for this
  Effect_of_Interest = "Condition1"
  
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Condition1", "EroticCouple"),
                         "Smaller" = c("Condition1", "Tree"))
  
  H1.3_Pic = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                              DirectionEffect, collumns_to_keep, Task, AnalysisPhase)

  
  # # Hypothesis 1.4 ASY Stroop Consumption ~ Picture category * Pleasure Ratings
  # In the emotional stroop task, ASY during the consumption of a picture will be larger for positive (and
  # erotic) pictures compared to neutral pictures. This relationship could be possibly moderated by pleasantness ratings 
  # for the pictures, i.e. the pleasantness ratings of the categories drive the effect.
  
  if (!(input$stephistory[["BehavCovariate"]]== "pleasant_arousal_av")) {
    Behavior_Formula = paste("+ Condition1 * ", Behavior_Name,  collapse = ' ')
    lm_formula =  paste( "EEG_Signal ~ ((Condition1", Behavior_Formula, ")", additional_Factor_Formula, ")", Covariate_Formula )
  } else { # if Average per Condition1, the factor Condition1 is irrelevant
    lm_formula =  paste( "EEG_Signal ~ ((", paste(Behavior_Name, collapse = "+"), ")", additional_Factor_Formula, ")", Covariate_Formula )
  }
  
  Task = "Stroop"
  AnalysisPhase = "Consumption"
  collumns_to_keep = c("Condition1", Covariate_Name, additional_Factors_Name, Behavior_Name)  
  
  H1.4_Model = wrap_test_Hypothesis("",lm_formula, output, "",
                                    "", collumns_to_keep, Task, AnalysisPhase,
                                     "exportModel", "")
  
  
  Name_Test = c("State_Stroop_Consumption")
  Effect_of_Interest = "Condition1"
  if (!(input$stephistory[["BehavCovariate"]]== "pleasant_arousal_av")) {
    H1.4_Pic = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                        DirectionEffect, collumns_to_keep, Task, AnalysisPhase,
                                        "previousModel", H1.4_Model)
    
  } else {
    # if Rating's averages across subjects are used to model, then there is no Condition1 predictor!
    H1.4_Pic = c(Name_Test, "notRundueToSetUp", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA)
  }
  
  
  Name_Test = c("State_Stroop_Consumption-Rating")
  if (!(input$stephistory[["BehavCovariate"]]== "pleasant_arousal_av")) { 
    Effect_of_Interest = c("Condition1", Behavior_Name[idx_Valence = which(grepl("Pleasure", Behavior_Name))]) 
  } else {
    # if Rating's averages across subjects are used to model, then there is no Condition1 predictor!
    Effect_of_Interest = c( Behavior_Name[idx_Valence = which(grepl("Pleasure", Behavior_Name))]) 
  }
  
  H1.4_prepRatingIA = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                DirectionEffect, collumns_to_keep, Task, AnalysisPhase,
                                "previousModel", H1.4_Model)

  Effect_of_Interest = c( Behavior_Name[idx_Valence = which(grepl("Pleasure", Behavior_Name))]) 
  H1.4_prepRatingMF = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                       DirectionEffect, collumns_to_keep, Task, AnalysisPhase,
                                       "previousModel", H1.4_Model)
  
  # Take the larger effects of the two (interaction or main effect)
  ToCompare = rbind(H1.4_prepRatingMF,H1.4_prepRatingIA)
  ToCompare = ToCompare[which(!is.na(ToCompare$value_EffectSize)),]
  if (nrow(ToCompare)>0) {
    H1.4_Rating = ToCompare[which.max(ToCompare$value_EffectSize),] 
  } else {
    H1.4_Rating = H1.4_prepRatingMF
  }
  
  
  #########################################################
  # (5) Test Phases against each other
  #########################################################
  # Hypothesis 1.5 ASY ~ Stroop Anticipation and Rest
  # Test Anticipation AV between Resting and other Task
  # In the emotional stroop task, ASY during anticipation of a picture will be larger than during rest.
  Name_Test = c("State_Stroop-Rest_Anticipation")
  Task = c("Stroop", "Resting")
  lm_formula =   paste( "EEG_Signal ~ (Task", additional_Factor_Formula, ")", Covariate_Formula)
  AnalysisPhase = c("Anticipation", "NA")
  collumns_to_keep = c("Task", Covariate_Name, additional_Factors_Name)  
  Effect_of_Interest = "Task"
  
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Task", "Stroop"),
                         "Smaller" = c("Task", "Resting"))
  H1.5_SR = wrap_test_Hypothesis(Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest,
                              DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  # Add also for Gambling, even if not a hypothesis
  Name_Test = c("State_Gambling-Rest_Anticipation")
  Task = c("Gambling", "Resting")
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Task", "Gambling"),
                         "Smaller" = c("Task", "Resting"))
  H1.5_GR = wrap_test_Hypothesis(Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest,
                                DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  
  ##############################################################
  #Not a Hypothesis, but comparing Anticipation vs Consumption
  AnalysisPhase = c("Anticipation", "Consumption")
  collumns_to_keep = c("AnalysisPhase", Covariate_Name, additional_Factors_Name)  
  Effect_of_Interest = "AnalysisPhase"
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("AnalysisPhase", "Anticipation"),
                         "Smaller" = c("AnalysisPhase", "Consumption"))
  lm_formula =   paste( "EEG_Signal ~ (AnalysisPhase", additional_Factor_Formula, ")", Covariate_Formula)
  
  # For Gambling
  Name_Test = c("State_Gambling_Ant-Consum")
  Task = c("Gambling")
  H1.6_Gam = wrap_test_Hypothesis(Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest,
                                DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  # For Stroop
  Name_Test = c("State_Stroop_Ant-Consum")
  Task = c("Stroop")
  H1.6_Str = wrap_test_Hypothesis(Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest,
                                DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
 
  
  
  #########################################################
  # (5) Test Interaction with Personality for H2 
  #########################################################
  print("Test Interactions")
  # To test for the specify of the Association between BAS and the separate Condition1s
  # within the task, the models outlined in 15) will be extended by the factor BAS. If there is a significant
  # interaction between any of the manipulated Condition1s and BAS, only the ASY scores of the Condition1
  # with the largest positive association will be included for the following comparisons. If no interaction
  # emerges, the average across all Condition1s is used
  
  # Hypothesis 2.1 ASY Gambling Anticipation ~ Reward Magnitude * Personality
  Task = "Gambling"
  AnalysisPhase = "Anticipation"
  collumns_to_keep = c("Condition1", Covariate_Name, additional_Factors_Name, Personality_Name) 
  lm_formula =   paste( "EEG_Signal ~ (Condition1", Personality_Formula, additional_Factor_Formula, ")", Covariate_Formula)
  H2.1_Model = wrap_test_Hypothesis( "",lm_formula, output, "", 
                                     "", collumns_to_keep, Task, AnalysisPhase, "exportModel", "")
  
  Name_Test = "Personality_Gambling_Anticipation-IA"
  Effect_of_Interest = c("Condition1", Personality_Name)
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Condition1", "50"),
                         "Smaller" = c("Condition1", "0"),
                         "Personality" = Personality_Name)
  H2.1_IA = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                    DirectionEffect, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.1_Model)
  
  Name_Test = "Personality_Gambling_Anticipation-MF"
  Effect_of_Interest = c(Personality_Name)
  DirectionEffect = list("Effect" = "correlation",
                         "Personality" = Personality_Name)
  H2.1_MF = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                  DirectionEffect, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.1_Model) 
  
  ############################################################################
  # Hypothesis 2.2 ASY Gambling Consumption ~ Reward Magnitude * Feedback Type
  AnalysisPhase = "Consumption"
  collumns_to_keep = c("Condition1", "Condition2", Covariate_Name, additional_Factors_Name, Personality_Name) 
  lm_formula =   paste( "EEG_Signal ~ (Condition1 * Condition2", Personality_Formula, additional_Factor_Formula, ")", Covariate_Formula)
  H2.2_Model = wrap_test_Hypothesis( "",lm_formula, output, "", 
                                "", collumns_to_keep, Task, AnalysisPhase, "exportModel", "")

  
  # Test for Valence * Personality
  Name_Test = c("Personality_Gambling_Consumption-ValIA")
  Effect_of_Interest = c("Condition1", Personality_Name)
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Condition1", "Win"),
                         "Smaller" = c("Condition1", "Loss"),
                         "Personality" = Personality_Name)
  H2.2_IAv = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                     DirectionEffect, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.2_Model)
  
  # Test for Magnitude * Personality
  Name_Test = c("Personality_Gambling_Consumption-MagIA")
  Effect_of_Interest = c("Condition2", Personality_Name)
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Condition2", "50"),
                         "Smaller" = c("Condition2", "0"),
                         "Personality" = Personality_Name)
  H2.2_prepMag = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                  DirectionEffect, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.2_Model)
  
  # Test for Interaction  Valence*Magnitude * Personality
  Effect_of_Interest = c("Condition1", "Condition2", Personality_Name)
  DirectionEffect = list("Effect" = "interaction2_correlation",
                         "Larger" = c("Condition1", "Win"),
                         "Smaller" = c("Condition1", "Loss"),
                         "Interaction" = c("Condition2", "0", "50"),
                         "Personality" = Personality_Name)
  H2.2_prepMagVal = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                       DirectionEffect, collumns_to_keep, Task, AnalysisPhase,"previousModel", H2.2_Model)
  
  # Take the larger effects of the two (interaction or main effect of magnitude)
  ToCompare = rbind(H2.2_prepMag,H2.2_prepMagVal)
  ToCompare = ToCompare[which(!is.na(ToCompare$value_EffectSize)),]
  if (nrow(ToCompare)>0) {
    H2.2_IAm = ToCompare[which.max(ToCompare$value_EffectSize),] 
  } else {
    H2.2_IAm = H2.2_prepMag
  }
  
  
  # Test for Main Effect of Personality
  Name_Test = "Personality_Gambling_Consumption-MF"
  Effect_of_Interest = c(Personality_Name)
  DirectionEffect = list("Effect" = "correlation",
                         "Personality" = Personality_Name)
  H2.2_MF = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                  DirectionEffect, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.2_Model) 
  
  
  #######################################################################
  # Hypothesis 2.3 ASY Stroop Anticipation ~ Picture category (before) * Personality 
  lm_formula =   paste( "EEG_Signal ~ (Condition1", Personality_Formula, additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Stroop"
  AnalysisPhase = "Anticipation"
  collumns_to_keep = c("Condition1", Covariate_Name, additional_Factors_Name, Personality_Name)
  H2.3_Model = wrap_test_Hypothesis( "",lm_formula, output, "", 
                                     "", collumns_to_keep, Task, AnalysisPhase, "exportModel", "")
  
  # Test IA Condition*Personality
  Name_Test = c("Personality_Stroop_Anticipation-IA")
  Effect_of_Interest = c("Condition1", Personality_Name)
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Condition1", "EroticCouple"),
                         "Smaller" = c("Condition1", "Tree"),
                         "Personality" = Personality_Name)
  H2.3_IA = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                  DirectionEffect, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.3_Model) 
  
  # Test for Main Effect of Personality
  Name_Test = "Personality_Stroop_Anticipation-MF"
  Effect_of_Interest = c(Personality_Name)
  DirectionEffect = list("Effect" = "correlation",
                         "Personality" = Personality_Name)
  H2.3_MF = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                  DirectionEffect, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.3_Model) 
  
  
  
  #######################################################################
  # # Hypothesis 2.4 ASY Stroop Consumption ~ Picture category * Personality (* Rating)
  Task = "Stroop"
  AnalysisPhase = "Consumption"
  collumns_to_keep = c("Condition1", Covariate_Name, additional_Factors_Name, Personality_Name, Behavior_Name)
  if (!(input$stephistory[["BehavCovariate"]]== "pleasant_arousal_av")) {
    Behavior_Formula = paste("+ Condition1 * ", Behavior_Name,  collapse = ' ')
    lm_formula =  paste( "EEG_Signal ~ (((Condition1", Behavior_Formula, ")",Personality_Formula, ")", additional_Factor_Formula, ")", Covariate_Formula )
  } else { # if Average per Condition1, the factor Condition1 is irrelevant
    lm_formula =   paste( "EEG_Signal ~ (((Behav_Arousal +   Behav_Pleasure)",Personality_Formula, ")", additional_Factor_Formula, ")", Covariate_Formula )
  }
  H2.4_Model = wrap_test_Hypothesis( "",lm_formula, output, "", 
                                "", collumns_to_keep, Task, AnalysisPhase, "exportModel")
  
  
  # Test for Main Effect of Personality
  Name_Test = "Personality_Stroop_Consumption-MF"
  Effect_of_Interest = c(Personality_Name)
  DirectionEffect = list("Effect" = "correlation",
                         "Personality" = Personality_Name)
  H2.4_MF = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                  DirectionEffect, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.4_Model) 
  
  
  # Test for Condition only
  Name_Test = "Personality_Stroop_Consumption-IA"
  Effect_of_Interest = c("Condition1", Personality_Name)
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Condition1", "EroticCouple"),
                         "Smaller" = c("Condition1", "Tree"),
                         "Personality" = Personality_Name)
  H2.4_prepCond = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                  DirectionEffect, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.4_Model) 
  
  # Test for Rating only
  Effect_of_Interest = c(Behavior_Name[grepl("Pleasure", Behavior_Name)], Personality_Name)
  DirectionEffect = "notdirected"
  H2.4_prepRating = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                        DirectionEffect, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.4_Model) 
  
  # Test for Condition * Rating
  # Test for Rating only
  Effect_of_Interest = c(Behavior_Name[grepl("Pleasure", Behavior_Name)], Personality_Name, "Condition1")
  DirectionEffect = "notdirected"
  H2.4_prepRatingCond = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                          DirectionEffect, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.4_Model) 
  
  
  # Pick the largest from above
  ToCompare = rbind(H2.4_prepCond,H2.4_prepRating,H2.4_prepRatingCond )
  ToCompare = ToCompare[which(!is.na(ToCompare$value_EffectSize)),]
  if (nrow(ToCompare)>0) {
  H2.4_IA = ToCompare[which.max(ToCompare$value_EffectSize),] 
  } else {
    H2.4_IA = H2.4_prepCond
  }
  

  ##############################################################
  #Not a Hypothesis, but comparing Anticipation vs Consumption and Add Personality
  AnalysisPhase = c("Anticipation", "Consumption")
  collumns_to_keep = c("AnalysisPhase", Covariate_Name, Personality_Name, additional_Factors_Name)  
  Effect_of_Interest = c("AnalysisPhase", Personality_Name)
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("AnalysisPhase", "Anticipation"),
                         "Smaller" = c("AnalysisPhase", "Consumption"),
                         "Personality" = Personality_Name)
  lm_formula =   paste( "EEG_Signal ~ (AnalysisPhase", Personality_Formula, additional_Factor_Formula, ")", Covariate_Formula)
  
  
  
  # For Gambling
  Name_Test = c("Personality_Gambling_Ant-Consum")
  Task = c("Gambling")
  H1.6_GamIA = wrap_test_Hypothesis(Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest,
                                DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  # For Stroop
  Name_Test = c("Personality_Stroop_Ant-Consum")
  Task = c("Stroop")
  H1.6_StrIA = wrap_test_Hypothesis(Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest,
                                DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  
  
  
  #########################################################
  # (6) Prepare which Data should be compared to Resting
  #########################################################
  #(could be either AV across all Condition1s or Condition1 with strongest correlation, depends on interaction)
  
  # Resting data is taken as it is
  Extracted_Data = output[output$Task == "Resting", names(Average_Across_Conditions) ] 
  
  # Hypothesis 2.1 ASY Gambling Anticipation ~ Reward Magnitude * Personality
  Task = "Gambling"
  AnalysisPhase = "Anticipation"
  SignTest = H2.1_IA$p_Value
  Extracted_Data =  extract_StrongestCorrelation(SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Conditions, Average_Across_Conditions, output)
  
  # Hypothesis 2.2 ASY Gambling Consumption ~ Reward Magnitude * Feedback
  Task = "Gambling"
  AnalysisPhase = "Consumption"
  # if IA Magnitude*Valence significant, otherwise take only valence
  if (is.na(H2.2_prepMagVal$p_Value)) {
    Take = "Main"
  } else {
  if (H2.2_prepMagVal$p_Value <0.05) {
    Take = "Interaction"
   } else { # If not, test only Valence Effect
     Take = "Main"   
   }}
  
  if (Take == "Interaction") {
    SignTest = H2.2_prepMagVal$p_Value
    output2 = output %>%
      filter(Task == "Gambling",
             AnalysisPhase == "Consumption") %>%
      unite(Condition1, Condition1, Condition2, sep = "_", remove = TRUE) 
    Extracted_Data =  extract_StrongestCorrelation(SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Both_Conditions , Average_Across_Conditions , output2)
  } else { # Main
    SignTest = H2.2_IAv$p_Value
    Extracted_Data =  extract_StrongestCorrelation(SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Conditions, Average_Across_Conditions, output)
  }
  
  # Hypothesis 2.3 ASY Stroop Anticipation ~ Picture category (before) * Personality
  Task = "Stroop"
  AnalysisPhase = "Anticipation"
  SignTest = H2.3_IA$p_Value
  Extracted_Data =  extract_StrongestCorrelation(SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Conditions, Average_Across_Conditions, output)
  
  
  # Hypothesis 2.4 ASY Stroop Consumption ~ Picture category * Personality
  Task = "Stroop"
  AnalysisPhase = "Consumption"
  SignTest = H2.4_prepCond$p_Value
  Extracted_Data =  extract_StrongestCorrelation(SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Conditions, Average_Across_Conditions, output)
  
  
  
  # #########################################################
  # # (7) Compare Association to Personality to Resting for different Phases
  # #########################################################
  print("Test Associations")
  lm_formula =   paste( "EEG_Signal ~ ((Task * ", Personality_Name, ")",additional_Factor_Formula, ")", Covariate_Formula)
  collumns_to_keep = c("Task", AnalysisPhase, Covariate_Name, additional_Factors_Name, Personality_Name)
  Effect_of_Interest = c("Task", Personality_Name)

  
  
  # Hypothesis 2.1 ASY Gambling Anticipation ~ Task * Personality
  Task = c("Gambling", "Resting")
  AnalysisPhase = c("Anticipation", "NA")
  Name_Test = c("Personality_RestGambling_Anticipation")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Task", "Gambling"),
                         "Smaller" = c("Task", "Resting"),
                         "Personality" = Personality_Name)
  H2.1B = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, 
                           DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  
  # Hypothesis 2.2 ASY Gambling Consumption ~ Task * Personality
  Task = c("Gambling", "Resting")
  AnalysisPhase = c("Consumption", "NA")
  Name_Test = c("Personality_RestGambling_Consumption")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Task", "Gambling"),
                         "Smaller" = c("Task", "Resting"),
                         "Personality" = Personality_Name)
  H2.2B = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, 
                           DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  
  # Hypothesis 2.3 ASY Stroop Anticipation ~ Task * Personality
  Task = c("Stroop", "Resting")
  AnalysisPhase = c("Anticipation", "NA")
  Name_Test = c("Personality_RestStroop_Anticipation")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Task", "Stroop"),
                         "Smaller" = c("Task", "Resting"),
                         "Personality" = Personality_Name)
  H2.3B = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest,
                           DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  # Hypothesis 2.4 ASY Stroop Consumption ~ Task * Personality
  Task = c("Stroop", "Resting")
  AnalysisPhase = c("Consumption", "NA")
  Name_Test = c("Personality_RestStroop_Consumption")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Task", "Stroop"),
                         "Smaller" = c("Task", "Resting"),
                         "Personality" = Personality_Name)
  H2.4B = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest,
                           DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  
  
  # Test also Resting and BAS
  Effect_of_Interest = Personality_Name
  DirectionEffect = list("Effect" = "correlation",
                         "Personality" = Personality_Name)
  lm_formula =   paste( "EEG_Signal ~ ((", Personality_Name, ")",additional_Factor_Formula, ")", Covariate_Formula)
  Task = c("Resting")
  AnalysisPhase = c("NA")
  Name_Test = c("Personality_Resting")
  H2.xB = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, 
                                 DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  #########################################################
  # (7) Correct for Multiple Comparisons for Hypothesis 1
  #########################################################
  
  Estimates_H1 = as.data.frame(rbind(H1.1_Mag, H1.2_Val, H1.2_Mag,  H1.3_Pic, H1.4_Pic,  H1.4_Rating))
  comparisons = sum(!is.na(Estimates_H1$p_Value))
  
  if (choice == "Holm"){
    Estimates_H1$p_Value = p.adjust(Estimates_H1$p_Value, method = "holm", n = comparisons)
  }  else if (choice == "Bonferroni"){
    Estimates_H1$p_Value = p.adjust(Estimates_H1$p_Value, method = "bonferroni", n = comparisons)
  }
  
  Estimates = rbind(Estimates_H1, 
                    H1.5_SR, H1.5_GR, H1.6_Gam, H1.6_Str,
                    H2.1_IA, H2.1_MF, H2.2_IAv, H2.2_IAm, H2.2_MF,
                    H2.3_IA, H2.3_MF, H2.4_MF, H2.4_IA,
                    H2.1B, H2.2B, H2.3B, H2.4B,
                    H2.xB)
  Estimates$av_epochs[which(Estimates$av_epochs == "NaN")] = NA
  
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
