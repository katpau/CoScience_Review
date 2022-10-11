Determine_Significance = function(input = NULL, choice = NULL) {
  StepName = "Determine_Significance"
  Choices = c("Holm", "Bonferroni", "None")
  Order = 13
  output = input$data
  names(output)[names(output)=="Condition"] = "Condition1"
  
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
    if(missing(ModelProvided)) { ModelProvided = "none"  }
    StopModel = 0
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Always update Subset (to extract correct Nr of Subjects and Effects of Interest)
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
    
    classes_df = lapply(Subset[names(Subset)], class)
    make_Factor = names(classes_df[classes_df == "character"])
    Subset[make_Factor] = lapply(Subset[make_Factor], as.factor)
    
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Prepare and Calculate LMer Model
    if (!SaveUseModel == "previousModel"){  
      # check if data has been processed, otherwise don't proceed
      if (length(unique(Subset$ID))<100) {
        Model_Result = "Error_data_seems_incomplete_less_than_200_subs"
      } else {
        
        #?? Update Formula if levels singular?
        for (iCol in collumns_to_keep) {
          if(length(unique(as.character((as.data.frame(Subset)[,iCol]))))<2) {
            if (grepl(iCol, lm_formula)) {
              print("Dropped Factor")
              lm_formula = gsub(paste0("\\* ", iCol), "", lm_formula)
            }}
        }
        
        # Add subjects as random factors for Model based on lm_formula (within subject Design!!)
        Predictors = unlist(strsplit(lm_formula, "\\~"))[2]
        Predictors = gsub("\\ ", "", Predictors)
        Predictors = gsub("\\+", "*", Predictors)
        Predictors = gsub("\\)", "", Predictors)
        Predictors = gsub("\\(", "", Predictors)
        Predictors = unique(unlist(strsplit(Predictors, "\\*")))
        Predictors = Predictors[!grepl("Covariate_", Predictors)]
        Predictors = Predictors[!grepl("Personality_", Predictors)]
        Predictors = Predictors[!grepl("Behav_", Predictors)]
        Predictors = Predictors[!grepl("EEG_Signal", Predictors)]
        
        if (length(Predictors)>0) {
          noRandomFactor = 0
          lm_formula = paste(lm_formula, "+ (1|ID)")
          if (length(Predictors) > 1) {
            for  (iPredictor in Predictors) {
              lm_formula = paste0(lm_formula, "+ (1|", iPredictor, ":ID)")
            }}
        } else {
          noRandomFactor = 1}
        # Calculate LM Model
        
        
        Model_Result = tryCatch({
          if (noRandomFactor == 0) {
            Model_Result = lmer(as.formula(lm_formula), 
                                Subset) 
            
            
          }   else {
            Model_Result = lm(as.formula(lm_formula), 
                              Subset)
          }
          Model_Result
        }, error = function(e) {
          print("Error with Model")
          Model_Result = "Error_when_computing_Model"
          return(Model_Result)
        })
        
        
        
        # If Model is provided, get it here
      }} else {  Model_Result = ModelProvided }
    
    
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # if only model is exported, stop here
    if (SaveUseModel == "exportModel")  {
      return(Model_Result)
      break
      # prepare export of parameters
    } else { 
      # Check if Model was calculated successfully
      #  If there were Problems with the Model, extract NAs
      if (is.character(Model_Result) &&  grepl( "Error", Model_Result)) {
        Estimates = cbind.data.frame(Name_Test, Model_Result, NA, NA, NA, NA,NA, NA, length(unique(as.character(Subset$ID))),NA, NA, NA)
        
      } else {
        # get Anova from model
        AnovaModel = anova(Model_Result)
        
        # Check Type of Model
        if(class(Model_Result) == "lm") {
          noRandomFactor = 1
        } else {
          noRandomFactor = 0
        }
        
        # Check Singularity
        if (noRandomFactor == 0) {
          Singularity = isSingular(Model_Result)
        } else { Singularity = NA}
        
        
        
        
        # Expand Effect of Interest by additional factors
        if ("Hemisphere" %in% collumns_to_keep) {
          Effect_of_Interest = c(Effect_of_Interest, "Hemisphere")  }
        if ("Localisation" %in% collumns_to_keep) {
          Effect_of_Interest = c(Effect_of_Interest, "Localisation")  }
        # Add Electrode to effect of interest only if frontal/paripartial_Etal
        if ("Electrode" %in% collumns_to_keep) {
          if (length(unlist(unique(Subset$Electrode))) == 6) {
            Effect_of_Interest = c(Effect_of_Interest, "Electrode")  }}
        
        Effect_of_Interest = unique(Effect_of_Interest)
        # Do not add other factors (Frequency Band)
        # These are different hypotheses. We are only focused 
        # on frontal alpha asymmetry.)
        
        
        # Find index of effect of interest for frontal alpha Asymmetry (and the indicated Conditions)
        if (length(Effect_of_Interest)>1) {
          Interest = rowSums(sapply(X = Effect_of_Interest, FUN = grepl, rownames(AnovaModel)))
          NrFactors = lengths(strsplit(rownames(AnovaModel), ":"))
          Idx_Effect_of_Interest = which(Interest == length(Effect_of_Interest) & NrFactors == length(Effect_of_Interest))
        }  else {
          Interest = grepl(Effect_of_Interest, rownames(AnovaModel))
          NrFactors = lengths(strsplit(rownames(AnovaModel), ":"))
          Idx_Effect_of_Interest = which(Interest & NrFactors == length(Effect_of_Interest))
        }
        
        
        # Get partial_Etas
        partial_Eta = effectsize::eta_squared(Model_Result,  alternative = "two.sided") # partial = FALSE does only partial
        partial_Eta = partial_Eta[Idx_Effect_of_Interest,]
        if (is.null(partial_Eta$Eta2_partial)) { partial_Eta$Eta2_partial = partial_Eta$Eta2} # For one-way between subjects designs, partial eta squared is equivalent to eta squared.
        partial_Eta = cbind( partial_Eta$Eta2_partial, partial_Eta$CI_low, partial_Eta$CI_high)
        
        # Get p value
        p_Value = AnovaModel$`Pr(>F)`[Idx_Effect_of_Interest]
        
        # Get Name of Test
        StatTest = rownames(AnovaModel)[Idx_Effect_of_Interest]
        
        # Get Estimates
        EstimatesModel=summary(Model_Result)$coefficients
        
        # Find index of effect of interest for frontal alpha Asymmetry (and the indicated Conditions)
        if (length(Effect_of_Interest)>1) {
          Interest = rowSums(sapply(X = Effect_of_Interest, FUN = grepl, rownames(EstimatesModel)))
          NrFactors = lengths(strsplit(rownames(EstimatesModel), ":"))
          Idx_Effect_of_Interest = which(Interest == length(Effect_of_Interest) & NrFactors == length(Effect_of_Interest))
        } else {
          Interest = grepl(Effect_of_Interest, rownames(EstimatesModel))
          NrFactors = lengths(strsplit(rownames(EstimatesModel), ":"))
          Idx_Effect_of_Interest = which(Interest & NrFactors == length(Effect_of_Interest))
        }
        Est = EstimatesModel[Idx_Effect_of_Interest, 1:2]
        # Get Standardized effects
        #effectsize::standardize_parameters(Model_Result)
        
        # some trouble shooting if Effect was not found
        if (length(Idx_Effect_of_Interest)==0) {
          p_Value = NA
          partial_Eta = cbind(NA, NA, NA)    }
        
        # get subject nr
        if (noRandomFactor == 0) { 
          Nr_Subs = min(summary(Model_Result)$ngrps)
        } else {
          if (any(grep("Task", colnames(Subset)))) {
            Nr_Subs = Subset %>% group_by(Task) %>% summarise(n = length(unique(ID)))
            Nr_Subs = min(Nr_Subs$n)
          } else {Nr_Subs = length(unique(Subset$ID))}
          
        }
        
        # prepare export
        Estimates = cbind.data.frame(Name_Test, StatTest,partial_Eta, p_Value, Est[1], Est[2], Nr_Subs, mean(Subset$Epochs), sd(Subset$Epochs), Singularity)
      } 
      colnames(Estimates) = c("Effect_of_Interest", "Statistical_Test", "partial_Eta2", "CI_low", "CI90_high", "p_Value", "Estimate", "Std.Error", "n_participants", "av_epochs", "sd_epochs", "Singularity")
      return (Estimates)
    }
  }
  
  
  
  
  ###########################
  # For Hypothesis Set 2, the tests are conducted on the Condition1 of the strongest correlation (if it was significant, otherwise the main effect)
  extract_StrongestCorrelation = function (SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Conditions, Average_Across_Conditions) {
    # This Function takes SignTest (the test of the interaction term with Condition1), if it is significant, the strongest correlation is found and exported
    if (!is.na(SignTest)) {
      if (SignTest < 0.05){
        Subset = Correlations_Within_Conditions[which(Correlations_Within_Conditions$Task == Task &
                                                        Correlations_Within_Conditions$AnalysisPhase == AnalysisPhase),]
        
        # only take frontal values!
        if ("Localisation" %in% additional_Factors_Name || "Elecrode" %in% additional_Factors_Name) {
          Subset = Subset[which(Subset$Localisation == "Frontal"),]}
        
        # Find Condition1 with highest correlation
        Idx = which.max(Subset$Correlation_with_Personality)
        # Take only data from that Condition1
        Extracted_Data = rbind(Extracted_Data, 
                               output[output$Task == Task &
                                        output$AnalysisPhase == AnalysisPhase &
                                        output$Condition1 == Subset$Condition1[Idx],
                                      names(Average_Across_Conditions)])
        
      } else {
        # if no interaction significant, simply take average
        Extracted_Data = rbind(Extracted_Data, 
                               Average_Across_Conditions[which(Average_Across_Conditions$Task == Task &
                                                                 Average_Across_Conditions$AnalysisPhase == AnalysisPhase),] )
      }} else {
        # if no interaction significant, simply take average
        Extracted_Data = rbind(Extracted_Data, 
                               Average_Across_Conditions[which(Average_Across_Conditions$Task == Task &
                                                                 Average_Across_Conditions$AnalysisPhase == AnalysisPhase),] )
        
      }
    return(Extracted_Data)
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
  H1.1 = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  # Hypothesis 1.2 ASY Gambling Consumption ~ Reward Magnitude * Feedback Type
  lm_formula =   paste( "EEG_Signal ~ (Condition1 * Condition2 ", additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Gambling"
  AnalysisPhase = "Consumption"
  collumns_to_keep = c("Condition1", "Condition2", Covariate_Name, additional_Factors_Name) 
  H1.2_Model = test_Hypothesis( "",lm_formula, output, "", collumns_to_keep, Task, AnalysisPhase, "exportModel")
  
  # In the gambling task, ASY during the consumption of feedback will be larger immediately after
  # rewards compared to losses
  # Test for Valence
  Effect_of_Interest = "Condition2"
  Name_Test = c("State_Gambling_Consumption-Valence")
  H1.2.1 = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase, "previousModel", H1.2_Model)
  
  
  # and for rewards of high magnitude (50 points) compared to rewards of low magnitude (10 points)
  # Test for Magnitude
  Name_Test = c("State_Gambling_Consumption-Magnitude")
  Effect_of_Interest = "Condition1"
  H1.2.2_prepA = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase, "previousModel", H1.2_Model)
  # Test for Interaction  
  Effect_of_Interest = c("Condition1", "Condition2")
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
  Name_Test = c("State_Stroop_Anticipation")
  lm_formula =   paste( "EEG_Signal ~ (Condition1", additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Stroop"
  AnalysisPhase = "Anticipation"
  collumns_to_keep = c("Condition1", Covariate_Name, additional_Factors_Name)  # Personality_Name not needed for this
  Effect_of_Interest = "Condition1"
  H1.3 = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
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
  H1.4_Model = test_Hypothesis( "",lm_formula, output, "", collumns_to_keep, Task, AnalysisPhase, "exportModel")
  
  Name_Test = c("State_Stroop_Consumption")
  Effect_of_Interest = "Condition1"
  if (!(input$stephistory[["BehavCovariate"]]== "pleasant_arousal_av")) {
    H1.4.1 = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase, "previousModel", H1.4_Model)
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
  H1.4.2 = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase, "previousModel", H1.4_Model)
  
  
  # Hypothesis 1.5 ASY ~ Stroop Anticipation and Rest
  # Test Anticipation AV between Resting and other Task
  # In the emotional stroop task, ASY during anticipation of a picture will be larger than during rest.
  Name_Test = c("State_Stroop-Rest_Anticipation")
  Task = c("Stroop", "Resting")
  lm_formula =   paste( "EEG_Signal ~ (Task", additional_Factor_Formula, ")", Covariate_Formula)
  AnalysisPhase = c("Anticipation", "NA")
  collumns_to_keep = c("Task", Covariate_Name, additional_Factors_Name)  
  Effect_of_Interest = "Task"
  H1.5.1 = test_Hypothesis( Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  # Add also for Gambling, even if not a hypothesis?
  Name_Test = c("State_Gambling-Rest_Anticipation")
  Task = c("Gambling", "Resting")
  H1.5.2 = test_Hypothesis( Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
  
  # Not a Hypothesis, but comparing Anticipation vs Consumption
  AnalysisPhase = c("Anticipation", "Consumption")
  collumns_to_keep = c("AnalysisPhase", Covariate_Name, additional_Factors_Name)  
  Effect_of_Interest = "AnalysisPhase"
  lm_formula =   paste( "EEG_Signal ~ (AnalysisPhase", additional_Factor_Formula, ")", Covariate_Formula)
  Name_Test = c("State_Gambling_Ant-Consum")
  Task = c("Gambling")
  H1.6.1 = test_Hypothesis( Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  Name_Test = c("State_Stroop_Ant-Consum")
  Task = c("Stroop")
  H1.6.2 = test_Hypothesis( Name_Test,lm_formula, Average_Across_Conditions, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  Average_Across_Conditions2 = Average_Across_Conditions
  Average_Across_Conditions2$Task_Phase = as.factor(paste0(as.character(Average_Across_Conditions2$Task), as.character(Average_Across_Conditions$AnalysisPhase)))
  Name_Test = c("State_AllTasks_Ant-Consum")
  AnalysisPhase = c("Anticipation", "Consumption", "NA")
  collumns_to_keep = c("Task_Phase", "AnalysisPhase", Covariate_Name, additional_Factors_Name)  
  Effect_of_Interest = "Task_Phase"
  lm_formula =   paste( "EEG_Signal ~ (Task_Phase", additional_Factor_Formula, ")", Covariate_Formula)
  Task = c("Gambling", "Stroop", "Resting")
  H1.6.3 = test_Hypothesis( Name_Test,lm_formula, Average_Across_Conditions2, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
  
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
  Name_Test = "Personality_Gambling_Anticipation-IA"
  H2.1_prep = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  # Hypothesis 2.2 ASY Gambling Consumption ~ Reward Magnitude * Feedback Type
  lm_formula =   paste( "EEG_Signal ~ (Condition1 * Condition2", Personality_Formula, additional_Factor_Formula, ")", Covariate_Formula)
  AnalysisPhase = "Consumption"
  collumns_to_keep = c("Condition1", "Condition2", Covariate_Name, additional_Factors_Name, Personality_Name) 
  H2.2_Model = test_Hypothesis( "",lm_formula, output, "", collumns_to_keep, Task, AnalysisPhase, "exportModel")
  
  # Test for Valence
  Name_Test = c("Personality_Gambling_Consumption-ValIA")
  Effect_of_Interest = c("Condition2", Personality_Name)
  H2.2.1_prep = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.2_Model)
  # Test for Magnitude
  Name_Test = c("Personality_Gambling_Consumption-MagIA")
  Effect_of_Interest = c("Condition1", Personality_Name)
  H2.2.2_prepA = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.2_Model)
  # Test for Interaction  
  Effect_of_Interest = c("Condition1", "Condition2", Personality_Name)
  H2.2.2_prepB = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase,"previousModel", H2.2_Model)
  
  
  # Hypothesis 2.3 ASY Stroop Anticipation ~ Picture category (before) * Personality 
  Name_Test = c("Personality_Stroop_Anticipation-IA")
  lm_formula =   paste( "EEG_Signal ~ (Condition1", Personality_Formula, additional_Factor_Formula, ")", Covariate_Formula)
  Task = "Stroop"
  AnalysisPhase = "Anticipation"
  collumns_to_keep = c("Condition1", Covariate_Name, additional_Factors_Name, Personality_Name)
  Effect_of_Interest = c("Condition1", Personality_Name)
  H2.3_prep  = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
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
  H2.4_Model = test_Hypothesis( "",lm_formula, output, "", collumns_to_keep, Task, AnalysisPhase, "exportModel")
  
  # Take main effect of Condition1 
  Effect_of_Interest = c("Condition1", Personality_Name)
  
  if (!(input$stephistory[["BehavCovariate"]]== "pleasant_arousal_av")) { 
    Effect_of_Interest = c("Condition1",Personality_Name) 
  } else {
    # if Rating's averages across subjects are used to model, then there is no Condition1 predictor!
    Effect_of_Interest = c( Behavior_Name[idx_Valence = which(grepl("Pleasure", Behavior_Name))], Personality_Name) 
  }
  H2.4_prep  = test_Hypothesis( Name_Test,lm_formula, output, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase, "previousModel", H2.4_Model)
  
  
  
  #########################################################
  # (6) Prepare which Data should be compared to Resting
  #########################################################
  #(could be either AV across all Condition1s or Condition1 with strongest correlation, depends on interaction)
  
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

  if (all(is.na(c(H2.2.2_prepA[3], H2.2.2_prepB[3])))) {
    # Use Main Effect even if not meaningful
    ToExtract = "Main"
  } else {
    if (any(is.na(c(H2.2.2_prepA[3], H2.2.2_prepB[3])))) {
      if (!is.na(H2.2.2_prepA[3])) {
        ToExtract = "Main"
      }
      else {
        ToExtract = "IA"
      }
    } else {
      if (H2.2.2_prepA[3] > H2.2.2_prepB[3]) {
        ToExtract = "Main"
      }
      else {
        ToExtract = "IA"
      }
    }
  }
  if (ToExtract == "Main") { 
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
  print("Test Associations")
  lm_formula =   paste( Personality_Name, " ~ ((Task * EEG_Signal)",additional_Factor_Formula, ")", Covariate_Formula)
  collumns_to_keep = c("Task", Covariate_Name, additional_Factors_Name, Personality_Name)
  Effect_of_Interest = c("Task", "EEG_Signal")
  
  # Hypothesis 2.1 ASY Gambling Anticipation ~ Reward Magnitude * Personality
  Task = c("Gambling", "Resting")
  AnalysisPhase = c("Anticipation", "NA")
  Name_Test = c("Personality_RestGambling_Anticipation-EEG")
  H2.1 = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
  # Hypothesis 2.2 ASY Gambling Consumption ~ Reward Magnitude * Feedback  
  Task = c("Gambling", "Resting")
  AnalysisPhase = c("Consumption", "NA")
  Name_Test = c("Personality_RestGambling_Consumption-EEG")
  H2.2 = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
  # Hypothesis 2.3 ASY Stroop Anticipation ~ Picture category (before) * Personality
  Task = c("Stroop", "Resting")
  AnalysisPhase = c("Anticipation", "NA")
  Name_Test = c("Personality_RestStroop_Anticipation-EEG")
  H2.3 = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  # Hypothesis 2.4 ASY Stroop Consumption ~ Picture category * Personality
  Task = c("Stroop", "Resting")
  AnalysisPhase = c("Consumption", "NA")
  Name_Test = c("Personality_RestStroop_Consumption-EEG")
  H2.4 = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
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
  H2.1B = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
  # Hypothesis 2.2 ASY Gambling Consumption ~ Reward Magnitude * Feedback  
  Task = c("Gambling", "Resting")
  AnalysisPhase = c("Consumption", "NA")
  Name_Test = c("Personality_RestGambling_Consumption-EEG-OW")
  H2.2B = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
  # Hypothesis 2.3 ASY Stroop Anticipation ~ Picture category (before) * Personality
  Task = c("Stroop", "Resting")
  AnalysisPhase = c("Anticipation", "NA")
  Name_Test = c("Personality_RestStroop_Anticipation-EEG-OW")
  H2.3B = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  # Hypothesis 2.4 ASY Stroop Consumption ~ Picture category * Personality
  Task = c("Stroop", "Resting")
  AnalysisPhase = c("Consumption", "NA")
  Name_Test = c("Personality_RestStroop_Consumption-EEG-OW")
  H2.4B = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
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
  H2.5x = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
    # Not a hypothesis but still add Association with just for different Phases 
  Effect_of_Interest = Personality_Name
  lm_formula =   paste( "EEG_Signal ~ ((", Personality_Name, ")",additional_Factor_Formula, ")", Covariate_Formula)
  Task = c("Resting")
  AnalysisPhase = c("NA")
  Name_Test = c("Personality_Resting-EEG-OW")
  H2.5Bx = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  # Not a hypothesis but still add Association with Resting
  Task = c("Gambling")
  AnalysisPhase = c("Anticipation")
  Name_Test = c("Personality_Gambling_Anticipation-EEG-OW")
  H2.5B1x = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
 
  AnalysisPhase = c("Consumption")
  Name_Test = c("Personality_Gambling_Consumption-EEG-OW")
  H2.5B2x = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)

  # Not a hypothesis but still add Association with Resting
  Task = c("Stroop")
  AnalysisPhase = c("Anticipation")
  Name_Test = c("Personality_Stroop_Anticipation-EEG-OW")
  H2.5B3x = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  AnalysisPhase = c("Consumption")
  Name_Test = c("Personality_Stroop_Consumption-EEG-OW")
  H2.5B4x = test_Hypothesis( Name_Test,lm_formula, Extracted_Data, Effect_of_Interest, collumns_to_keep, Task, AnalysisPhase)
  
  
  
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
  
  library(cocor)
  # Calculate correlations
  for (iTask in c("Resting", "Stroop", "Gambling")) {
    if (iTask == "Resting") {
      Subset = output_AV[output_AV$Task==iTask,]
      Subset = Subset[!is.na(Subset$EEG_Signal),]
      Subset = Subset[!is.na(Subset$Personality),]
      if (nrow(Subset)>10) {
        Test = cor.test(Subset$EEG_Signal, Subset$Personality)
        Estimate = cbind("Correlation_AVMax_Resting", "R", Test$estimate, Test$conf.int[1], Test$conf.int[2], Test$p.value, NA, NA, length(unique(Subset$ID)), NA, NA, NA)
      }else {
        Estimate = cbind("Correlation_AVMax_Resting", "R", NA,NA,NA,NA, NA, NA, length(unique(Subset$ID)), NA, NA, NA)
      }
    } else {
      for (iPhase in c("Anticipation", "Consumption")) {
        
        Subset = output_AV[output_AV$Task==iTask & output_AV$AnalysisPhase == iPhase,]
        Subset = Subset[!is.na(Subset$EEG_Signal),]
        Subset = Subset[!is.na(Subset$Personality),]
        if (nrow(Subset)>10) {
          Test = cor.test(Subset$EEG_Signal, Subset$Personality) 
          
          CorComp = tryCatch({
            cocor(as.formula(paste0("~Personality + EEG_Signal.Resting_NA | Personality + EEG_Signal.", iTask, "_", iPhase)), data = Extracted_Data_wide,
                  test = c("hittner2003"))@hittner2003$p.value
          }, error = function(e) {
            return(NA)
          })
          
          Estimate = rbind(Estimate,
                           cbind(paste0("Correlation_AVMax_", iTask, "_", iPhase), "R", Test$estimate, Test$conf.int[1], Test$conf.int[2], Test$p.value, 
                                 CorComp, NA,  length(unique(Subset$ID)), NA, NA, NA)) }
        else {
          Estimate = rbind(Estimate,
                           cbind("Correlation_AVMax_Resting", "R", NA,NA,NA,NA, NA, NA, length(unique(Subset$ID)), NA, NA, NA)
          )
          
        }
        
      }  }  }
  colnames(Estimate) = c("Effect_of_Interest", "Statistical_Test", "partial_Eta2", "CI_low", "CI90_high", "p_Value", "Estimate", "Std.Error", "n_participants", "av_epochs", "sd_epochs", "Singularity")
  
 
  

  

  

  
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
