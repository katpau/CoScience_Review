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
                  names(Data) %in% c("ID", "Epochs", "SME", "EEG_Signal", collumns_to_keep)]
    
    # Run Test
    ModelResult = test_Hypothesis( Name_Test,lm_formula, Subset, Effect_of_Interest, SaveUseModel, ModelProvided)
    
    # Test Direction
    if (!SaveUseModel == "exportModel") {
      ModelResult = test_DirectionEffect(DirectionEffect, Subset, ModelResult) 
    }
    
    return(ModelResult)
  }
  
  #########################################################
  # (3) Prepare Averages across Condition1s and Correlations
  #########################################################
  
  # For Hypotheses 1.5 and 2 Average across Condition1s and calculate Correlations per Condition1
  GroupingVariables1 = c("Task", "AnalysisPhase", "ID", additional_Factors_Name)
  GroupingVariables2 = c("Task", "AnalysisPhase", "Condition1", additional_Factors_Name)
  GroupingVariables3 = c("Task", "AnalysisPhase", "Condition1", "Condition2", additional_Factors_Name)  
  
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
  
  # if for any Condition1 there are no subjects, do not run it for that one
  output_to_AV = output[!is.na(output$EEG_Signal),]
  output_to_AV = as.data.frame(output_to_AV[!is.na(output_to_AV[,Personality_Name]),])
  
  Count_Subs = output_to_AV %>%
    group_by(across(all_of(c(GroupingVariables2, "Localisation", "FrequencyBand")))) %>%
    count(!is.na(EEG_Signal))
  
  Errors = as.data.frame(Count_Subs[which(Count_Subs$n<3),])
  
  if (nrow(Errors)>0) {
    for (iError in 1:nrow(Errors)){
      idx = rep(TRUE, nrow(output_to_AV))
      for (iGroupingV in GroupingVariables2) {
        idx = cbind(idx, as.character(output_to_AV[,iGroupingV]) == as.character(Errors[iError,iGroupingV]))
      }
      idx= which(apply(idx,1, all))
      output_to_AV = output_to_AV[-idx,]
    }}
  
  # Calculate Correlations with Personality Variables
  Correlations_Within_Conditions = output_to_AV %>%
    group_by(across(all_of(GroupingVariables2)), .drop = TRUE) %>%
    summarize(Correlation_with_Personality = cor.test(EEG_Signal, get(Personality_Name))$estimate) %>%
    ungroup()  
  
  Count_Subs = output_to_AV %>%
    group_by(across(all_of(c(GroupingVariables3, "Localisation", "FrequencyBand")))) %>%
    count(!is.na(EEG_Signal))
  
  Errors = as.data.frame(Count_Subs[which(Count_Subs$n<3),])
  
  if (nrow(Errors)>0) {
    for (iError in 1:nrow(Errors)){
      idx = rep(TRUE, nrow(output_to_AV))
      for (iGroupingV in GroupingVariables3) {
        idx = cbind(idx, as.character(output_to_AV[,iGroupingV]) == as.character(Errors[iError,iGroupingV]))
      }
      idx= which(apply(idx,1, all))
      output_to_AV = output_to_AV[-idx,]
    }}
  
  Correlations_Within_Both_Conditions = output_to_AV %>%
    group_by(across(all_of(GroupingVariables3))) %>%
    summarize(Correlation_with_Personality = cor.test(EEG_Signal, get(Personality_Name))$estimate) %>%
    ungroup()  %>% 
    unite(Condition1, Condition1, Condition2, sep = "_", remove = TRUE)
  
  
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
  
  H1.1 = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
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
  Effect_of_Interest = "Condition2"
  Name_Test = c("State_Gambling_Consumption-Valence")
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Condition2", "Win"),
                         "Smaller" = c("Condition2", "Loss"))
  
  H1.2.1 = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                              DirectionEffect, collumns_to_keep, Task, AnalysisPhase,
                              "previousModel", H1.2_Model)
  
  # and for rewards of high magnitude (50 points) compared to rewards of low magnitude (10 points)
  # Test for Magnitude
  Name_Test = c("State_Gambling_Consumption-Magnitude")
  Effect_of_Interest = "Condition1"
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Condition1", "0"),
                         "Smaller" = c("Condition1", "50"))
  
  H1.2.2_prepA = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                DirectionEffect, collumns_to_keep, Task, AnalysisPhase,
                                "previousModel", H1.2_Model)
  
  
   # Test for Interaction  
  Effect_of_Interest = c("Condition1", "Condition2")
  DirectionEffect = list("Effect" = "interaction",
                         "Larger" = c("Condition2", "Win"),
                         "Smaller" = c("Condition2", "Loss"),
                         "Interaction" = c("Condition1", "0", "50"))
  H1.2.2_prepB = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                      DirectionEffect, collumns_to_keep, Task, AnalysisPhase,
                                      "previousModel", H1.2_Model)
  
  
 
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
  Name_Test = c("State_Stroop_Anticipation")
  lm_formula =   paste( "EEG_Signal ~ (Condition1", additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Stroop"
  AnalysisPhase = "Anticipation"
  collumns_to_keep = c("Condition1", Covariate_Name, additional_Factors_Name)  # Personality_Name not needed for this
  Effect_of_Interest = "Condition1"
  
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Condition1", "EroticCouple"),
                         "Smaller" = c("Condition1", "Tree"))
  
  H1.3 = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
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
    H1.4.1 = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                        DirectionEffect, collumns_to_keep, Task, AnalysisPhase,
                                        "previousModel", H1.4_Model)
    
  } else {
    # if Rating's averages across subjects are used to model, then there is no Condition1 predictor!
    H1.4.1 = c(Name_Test, "notRundueToSetUp", NA, NA, NA, NA, NA, NA, NA)
  }
  
  
  Name_Test = c("State_Stroop_Consumption-Rating")
  if (!(input$stephistory[["BehavCovariate"]]== "pleasant_arousal_av")) { 
    Effect_of_Interest = c("Condition1", Behavior_Name[idx_Valence = which(grepl("Pleasure", Behavior_Name))]) 
  } else {
    # if Rating's averages across subjects are used to model, then there is no Condition1 predictor!
    Effect_of_Interest = c( Behavior_Name[idx_Valence = which(grepl("Pleasure", Behavior_Name))]) 
  }
  
  H1.4.2 = wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                DirectionEffect, collumns_to_keep, Task, AnalysisPhase,
                                "previousModel", H1.4_Model)

  
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
  H1.5.1 = wrap_test_Hypothesis(Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest,
                              DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  # Add also for Gambling, even if not a hypothesis?
  Name_Test = c("State_Gambling-Rest_Anticipation")
  Task = c("Gambling", "Resting")
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Task", "Gambling"),
                         "Smaller" = c("Task", "Resting"))
  H1.5.2 = wrap_test_Hypothesis(Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest,
                                DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  ############
  # Not a Hypothesis, but comparing Anticipation vs Consumption
  AnalysisPhase = c("Anticipation", "Consumption")
  collumns_to_keep = c("AnalysisPhase", Covariate_Name, additional_Factors_Name)  
  Effect_of_Interest = "AnalysisPhase"
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("AnalysisPhase", "Anticipation"),
                         "Smaller" = c("AnalysisPhase", "Consumption"))
  
  lm_formula =   paste( "EEG_Signal ~ (AnalysisPhase", additional_Factor_Formula, ")", Covariate_Formula)
  Name_Test = c("State_Gambling_Ant-Consum")
  Task = c("Gambling")
  
  H1.6.1 = wrap_test_Hypothesis(Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest,
                                DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  
  Name_Test = c("State_Stroop_Ant-Consum")
  Task = c("Stroop")
  H1.6.2 = wrap_test_Hypothesis(Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest,
                                DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
 
  
  Average_Across_Conditions2 = Average_Across_Conditions
  Average_Across_Conditions2$Task_Phase = as.factor(paste0(as.character(Average_Across_Conditions2$Task), as.character(Average_Across_Conditions$AnalysisPhase)))
  Name_Test = c("State_AllTasks_Ant-Consum")
  AnalysisPhase = c("Anticipation", "Consumption", "NA")
  collumns_to_keep = c("Task_Phase", "AnalysisPhase", Covariate_Name, additional_Factors_Name)  
  Effect_of_Interest = "Task_Phase"
  lm_formula =   paste( "EEG_Signal ~ (Task_Phase", additional_Factor_Formula, ")", Covariate_Formula)
  Task = c("Gambling", "Stroop", "Resting")
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Task_Phase", "GamblingAnticipation"),
                         "Smaller" = c("Task_Phase", "RestingNA"))
  H1.6.3 = wrap_test_Hypothesis(Name_Test,lm_formula, Average_Across_Conditions2, Effect_of_Interest,
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
  Effect_of_Interest = c("Condition1", Personality_Name)
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Condition1", "50"),
                         "Smaller" = c("Condition1", "0"),
                         "Personality" = Personality_Name)
  Name_Test = "Personality_Gambling_Anticipation-IA"
  H2.1_prep = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                    DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
 
  
  
  # Hypothesis 2.2 ASY Gambling Consumption ~ Reward Magnitude * Feedback Type
  lm_formula =   paste( "EEG_Signal ~ (Condition1 * Condition2", Personality_Formula, additional_Factor_Formula, ")", Covariate_Formula)
  AnalysisPhase = "Consumption"
  collumns_to_keep = c("Condition1", "Condition2", Covariate_Name, additional_Factors_Name, Personality_Name) 
  H2.2_Model = wrap_test_Hypothesis( "",lm_formula, output, "", 
                                "", collumns_to_keep, Task, AnalysisPhase, "exportModel", "")

  
  # Test for Valence
  Name_Test = c("Personality_Gambling_Consumption-ValIA")
  Effect_of_Interest = c("Condition2", Personality_Name)
  DirectionEffect = list("Effect" = "interaction",
                         "Larger" = c("Condition2", "Win"),
                         "Smaller" = c("Condition2", "Loss"),
                         "Interaction" = c("Condition1", "0", "50"))
  H2.2.1_prep = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                 DirectionEffect, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.2_Model)
  
  # Test for Magnitude
  Name_Test = c("Personality_Gambling_Consumption-MagIA")
  Effect_of_Interest = c("Condition1", Personality_Name)
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Condition1", "50"),
                         "Smaller" = c("Condition1", "0"),
                         "Personality" = Personality_Name)
  H2.2.2_prepA = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                  DirectionEffect, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.2_Model)
  
  # Test for Interaction  
  Effect_of_Interest = c("Condition1", "Condition2", Personality_Name)
  DirectionEffect = list("Effect" = "interaction2_correlation",
                         "Larger" = c("Condition2", "Win"),
                         "Smaller" = c("Condition2", "Loss"),
                         "Interaction" = c("Condition1", "0", "50"),
                         "Personality" = Personality_Name)
  H2.2.2_prepB = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                       DirectionEffect, collumns_to_keep, Task, AnalysisPhase,"previousModel", H2.2_Model)
  
  
  # Hypothesis 2.3 ASY Stroop Anticipation ~ Picture category (before) * Personality 
  Name_Test = c("Personality_Stroop_Anticipation-IA")
  lm_formula =   paste( "EEG_Signal ~ (Condition1", Personality_Formula, additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Stroop"
  AnalysisPhase = "Anticipation"
  collumns_to_keep = c("Condition1", Covariate_Name, additional_Factors_Name, Personality_Name)
  Effect_of_Interest = c("Condition1", Personality_Name)
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Condition1", "EroticCouple"),
                         "Smaller" = c("Condition1", "Tree"),
                         "Personality" = Personality_Name)

  H2.3_prep  = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  
  # # Hypothesis 2.4 ASY Stroop Consumption ~ Picture category * Personality (*Behaviour)
  Name_Test = c("Personality_Stroop_Consumption-RatingIA")
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
  
  # Take main effect of Condition1 
  Effect_of_Interest = c("Condition1", Personality_Name)
  
  if (!(input$stephistory[["BehavCovariate"]]== "pleasant_arousal_av")) { 
    Effect_of_Interest = c("Condition1",Personality_Name) 
  } else {
    # if Rating's averages across subjects are used to model, then there is no Condition1 predictor!
    Effect_of_Interest = c( Behavior_Name[idx_Valence = which(grepl("Pleasure", Behavior_Name))], Personality_Name) 
  }
  H2.4_prep  = wrap_test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, 
                                DirectionEffect, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.4_Model)
  
  
  
  #########################################################
  # (6) Prepare which Data should be compared to Resting
  #########################################################
  #(could be either AV across all Condition1s or Condition1 with strongest correlation, depends on interaction)
  
  # Resting data is taken as it is
  Extracted_Data = output[output$Task == "Resting", names(Average_Across_Conditions) ] 
  
  # Hypothesis 2.1 ASY Gambling Anticipation ~ Reward Magnitude * Personality
  Task = "Gambling"
  AnalysisPhase = "Anticipation"
  SignTest = H2.1_prep[7]
  Extracted_Data =  extract_StrongestCorrelation(SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Conditions, Average_Across_Conditions)
  
  # Hypothesis 2.2 ASY Gambling Consumption ~ Reward Magnitude * Feedback
  Task = "Gambling"
  AnalysisPhase = "Consumption"
  # Take the larger effects of the two (interaction or main effect of magnitude)
  
  if (all(is.na(c(H2.2.2_prepA[4], H2.2.2_prepB[4])))) {
    # Use Main Effect even if not meaningful
    ToExtract = "Main"
  } else {
    if (any(is.na(c(H2.2.2_prepA[4], H2.2.2_prepB[4])))) {
      if (!is.na(H2.2.2_prepA[4])) {
        ToExtract = "Main"
      }
      else {
        ToExtract = "IA"
      }
    } else {
      if (H2.2.2_prepA[4] > H2.2.2_prepB[4]) {
        ToExtract = "Main"
      }
      else {
        ToExtract = "IA"
      }
    }
  }
  if (ToExtract == "Main") { 
    SignTest = H2.2.2_prepA[7]
    Extracted_Data =  extract_StrongestCorrelation(SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Conditions, Average_Across_Conditions)
  } else { # Interaction
    SignTest = H2.2.2_prepB[7]
    Extracted_Data =  extract_StrongestCorrelation(SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Both_Conditions , Average_Across_Conditions)
  }
  
  # Hypothesis 2.3 ASY Stroop Anticipation ~ Picture category (before) * Personality
  Task = "Stroop"
  AnalysisPhase = "Anticipation"
  SignTest = H2.3_prep[7]
  Extracted_Data =  extract_StrongestCorrelation(SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Conditions, Average_Across_Conditions)
  
  
  # Hypothesis 2.4 ASY Stroop Consumption ~ Picture category * Personality
  Task = "Stroop"
  AnalysisPhase = "Consumption"
  SignTest = H2.4_prep[7]
  Extracted_Data =  extract_StrongestCorrelation(SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Conditions, Average_Across_Conditions)
  
  
  #########################################################
  # (7) Compare Association to Personality for different Phases
  #########################################################
  print("Test Associations")
  lm_formula =   paste( Personality_Name, " ~ ((Task * EEG_Signal)",additional_Factor_Formula, ")", Covariate_Formula)
  collumns_to_keep = c("Task", Covariate_Name, additional_Factors_Name, Personality_Name)
  Effect_of_Interest = c("Task", "EEG_Signal")

  
  # Hypothesis 2.1 ASY Gambling Anticipation ~ Reward Magnitude * Personality
  Task = c("Gambling", "Resting")
  AnalysisPhase = c("Anticipation", "NA")
  Name_Test = c("Personality_RestGambling_Anticipation-EEG")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Task", "Gambling"),
                         "Smaller" = c("Task", "Resting"),
                         "Personality" = Personality_Name)
  H2.1 = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, 
                          DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  
  # Hypothesis 2.2 ASY Gambling Consumption ~ Reward Magnitude * Feedback  
  Task = c("Gambling", "Resting")
  AnalysisPhase = c("Consumption", "NA")
  Name_Test = c("Personality_RestGambling_Consumption-EEG")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Task", "Gambling"),
                         "Smaller" = c("Task", "Resting"),
                         "Personality" = Personality_Name)
  H2.2 = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, 
                          DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  
  # Hypothesis 2.3 ASY Stroop Anticipation ~ Picture category (before) * Personality
  Task = c("Stroop", "Resting")
  AnalysisPhase = c("Anticipation", "NA")
  Name_Test = c("Personality_RestStroop_Anticipation-EEG")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Task", "Stroop"),
                         "Smaller" = c("Task", "Resting"),
                         "Personality" = Personality_Name)
  H2.3 = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, 
                          DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  # Hypothesis 2.4 ASY Stroop Consumption ~ Picture category * Personality
  Task = c("Stroop", "Resting")
  AnalysisPhase = c("Consumption", "NA")
  Name_Test = c("Personality_RestStroop_Consumption-EEG")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Task", "Stroop"),
                         "Smaller" = c("Task", "Resting"),
                         "Personality" = Personality_Name)
  H2.4 = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, 
                          DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  
  #########################################################
  # (7B) Compare Association to Personality for different Phases
  # Above one often results in unestimatable Models, change DV
  #########################################################
  print("Test Associations other way round")
  lm_formula =   paste( "EEG_Signal ~ ((Task * ", Personality_Name, ")",additional_Factor_Formula, ")", Covariate_Formula)
  collumns_to_keep = c("Task", Covariate_Name, additional_Factors_Name, Personality_Name)
  Effect_of_Interest = c("Task", Personality_Name)
  
  # Hypothesis 2.1 ASY Gambling Anticipation ~ Reward Magnitude * Personality
  Task = c("Gambling", "Resting")
  AnalysisPhase = c("Anticipation", "NA")
  Name_Test = c("Personality_RestGambling_Anticipation-EEG-OW")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Task", "Gambling"),
                         "Smaller" = c("Task", "Resting"),
                         "Personality" = Personality_Name)
  H2.1B = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, 
                           DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  
  # Hypothesis 2.2 ASY Gambling Consumption ~ Reward Magnitude * Feedback  
  Task = c("Gambling", "Resting")
  AnalysisPhase = c("Consumption", "NA")
  Name_Test = c("Personality_RestGambling_Consumption-EEG-OW")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Task", "Gambling"),
                         "Smaller" = c("Task", "Resting"),
                         "Personality" = Personality_Name)
  H2.2B = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, 
                           DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  
  # Hypothesis 2.3 ASY Stroop Anticipation ~ Picture category (before) * Personality
  Task = c("Stroop", "Resting")
  AnalysisPhase = c("Anticipation", "NA")
  Name_Test = c("Personality_RestStroop_Anticipation-EEG-OW")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Task", "Stroop"),
                         "Smaller" = c("Task", "Resting"),
                         "Personality" = Personality_Name)
  H2.3B = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest,
                           DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  # Hypothesis 2.4 ASY Stroop Consumption ~ Picture category * Personality
  Task = c("Stroop", "Resting")
  AnalysisPhase = c("Consumption", "NA")
  Name_Test = c("Personality_RestStroop_Consumption-EEG-OW")
  DirectionEffect = list("Effect" = "interaction_correlation",
                         "Larger" = c("Task", "Stroop"),
                         "Smaller" = c("Task", "Resting"),
                         "Personality" = Personality_Name)
  H2.4B = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest,
                           DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  
  #########################################################
  # (7) "Simple" Assoications
  #########################################################
  print("Test simple associations")
  
  # Not a hypothesis but still add Association with Resting
  Task = c("Resting")
  AnalysisPhase = c("NA")
  collumns_to_keep = c("Task", Covariate_Name, additional_Factors_Name, Personality_Name)
  lm_formula =   paste( Personality_Name, " ~ ((EEG_Signal)",additional_Factor_Formula, ")", Covariate_Formula)
  Name_Test = c("Personality_Resting-EEG")
  Effect_of_Interest = "EEG_Signal"
  DirectionEffect = list("Effect" = "correlation",
                         "Personality" = Personality_Name)
  H2.5x = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest,
                           DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  
  # Not a hypothesis but still add Association with just for different Phases 
  Effect_of_Interest = Personality_Name
  DirectionEffect = list("Effect" = "correlation",
                         "Personality" = Personality_Name)
  lm_formula =   paste( "EEG_Signal ~ ((", Personality_Name, ")",additional_Factor_Formula, ")", Covariate_Formula)
  Task = c("Resting")
  AnalysisPhase = c("NA")
  Name_Test = c("Personality_Resting-EEG-OW")
  H2.5Bx = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, 
                            DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  # Not a hypothesis but still add Association with Resting
  Task = c("Gambling")
  AnalysisPhase = c("Anticipation")
  Name_Test = c("Personality_Gambling_Anticipation-EEG-OW")
  H2.5B1x = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, 
                             DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  AnalysisPhase = c("Consumption")
  Name_Test = c("Personality_Gambling_Consumption-EEG-OW")
  H2.5B2x = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest,
                             DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  # Not a hypothesis but still add Association with Resting
  Task = c("Stroop")
  AnalysisPhase = c("Anticipation")
  Name_Test = c("Personality_Stroop_Anticipation-EEG-OW")
  H2.5B3x = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, 
                             DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  AnalysisPhase = c("Consumption")
  Name_Test = c("Personality_Stroop_Consumption-EEG-OW")
  H2.5B4x = wrap_test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, 
                             DirectionEffect, collumns_to_keep, Task, AnalysisPhase)
  
  
  
  #########################################################
  # (7) Run correlation on Averages
  #########################################################
  print("Only Corrrelations")
  output_AV = output[as.character(output$Localisation) == "Frontal",] %>%
    group_by(ID, Task, AnalysisPhase, Hemisphere) %>%
    dplyr::summarize(EEG_Signal = mean(EEG_Signal, na.rm = TRUE),
                     Personality =  mean(!!sym(Personality_Name), na.rm=TRUE))
  
  if (length(unique(output_AV$Hemisphere))>1) {
    output_AV$Hemisphere = as.factor(output_AV$Hemisphere)
    output_AV = spread(output_AV, key = Hemisphere, value = EEG_Signal)
    output_AV$EEG_Signal = output_AV$right - output_AV$left
    output_AV = output_AV[,-which(names(output_AV) %in% c("left", "right"))]
  }
  
  output_AV_wide = output_AV %>% 
              unite("Task_AnalysisPhase",Task:AnalysisPhase ) %>%
              spread(Task_AnalysisPhase, EEG_Signal)

  
  
  
  # Calculate correlations
  for (iTask in c("Resting", "Stroop", "Gambling")) {
    if (iTask == "Resting") {
      Subset = output_AV[output_AV$Task==iTask,]
      Subset = Subset[!is.na(Subset$EEG_Signal),]
      Subset = Subset[!is.na(Subset$Personality),]
      if (nrow(Subset)>10) {
        Test = cor.test(Subset$EEG_Signal, Subset$Personality)
        Estimate = cbind("Correlation_AVMax_Resting", "Pearson", "R", 
                         Test$estimate, Test$conf.int[1], Test$conf.int[2], Test$p.value,  
                         length(unique(Subset$ID)), NA, NA, NA)
      }else {
        Estimate = cbind("Correlation_AVMax_Resting", "R", 
                         NA,NA,NA,NA, NA, 
                         length(unique(Subset$ID)), NA, NA, NA)
      }
    } else {
      for (iPhase in c("Anticipation", "Consumption")) {
        
        Subset = output_AV[output_AV$Task==iTask & output_AV$AnalysisPhase == iPhase,]
        Subset = Subset[!is.na(Subset$EEG_Signal),]
        Subset = Subset[!is.na(Subset$Personality),]
        if (nrow(Subset)>10) {
          Test = cor.test(Subset$EEG_Signal, Subset$Personality) 
          
          Estimate = rbind(Estimate,
                           cbind(paste0("Correlation_AVMax_", iTask, "_", iPhase), "Pearson",  "R", 
                                 Test$estimate, Test$conf.int[1], Test$conf.int[2], Test$p.value, 
                                 length(unique(Subset$ID)), NA, NA, NA)   ) 
          
          # Statistically Test Difference of Correlation with rest
          CorComp = tryCatch({
               CompCorr = cocor(as.formula(paste0("~ Personality + Resting_NA | Personality + ", iTask, "_", iPhase)), 
                             data = as.data.frame(output_AV_wide), 
                             test = c("zou2007", "hittner2003" ),
                             conf.level = 0.90)
            
               Estimate = rbind(Estimate,
                                cbind(paste0("Difference_CorrAVMax_", iTask, "_", iPhase), "HittnerFischer",  "Diff", 
                                CompCorr@diff, CompCorr@zou2007$conf.int[1], CompCorr@zou2007$conf.int[2], CompCorr@hittner2003$p.value,
                                length(unique(Subset$ID)), NA, NA, NA))
            
            
          }, error = function(e) {
            return(NA)
          })
          
    }  else {
          Estimate = rbind(Estimate,
                           cbind(paste0("Correlation_AVMax_", iTask, "_", iPhase), "R", 
                                 NA, NA, NA, NA, NA,
                                 length(unique(Subset$ID)), NA, NA, NA)   )
          
          
        }
        
      }  }  }
  colnames(Estimate) = c("Effect_of_Interest", "Statistical_Test", "EffectSizeType" ,"value_EffectSize", "CI_low", "CI90_high", "p_Value",  "n_participants", "av_epochs", "sd_epochs", "Singularity")
  
  
  
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
  
  Estimates = rbind(Estimates_H1, 
                    H1.5.1, H1.5.2, H1.6.1, H1.6.2, H1.6.3,
                    H2.1,H2.2, H2.3, H2.4, H2.5x, 
                    H2.1B,H2.2B, H2.3B, H2.4B, H2.5Bx,
                    H2.5B1x, H2.5B2x , H2.5B3x , H2.5B4x,
                    H2.1_prep, H2.2.2_prepA, H2.2.2_prepB, H2.3_prep, H2.4_prep,
                    Estimate)
  
  
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
