Determine_Significance = function(input = NULL, choice = NULL) {
  StepName = "Determine_Significance"
  Choices = c("Holm", "Bonferroni", "None")
  Order = 13
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:
  
  # Handles all Choices listed above 
  # Runs the statistical Test, corrects for multiple comparisons and 
  # Prepares Output Table
  
  # (1) Get Names and Formulas of variable Predictors
  # (2) Initiate Functions for Hypothesis Testing
  # (3) Main Effects of Accuracy for different Tasks
  # (4) Interaction with Perfectionism
  # (5) Correct for Multiple Comparisons
  # (6) Export as CSV file


  # General notes for GMA
  # - The analysis step which removes trials outside an RT window (RT.R) is not neccessary, since they were already
  #   set as NA during  the GMA preprocessing.


  #########################################################
  # (1) Get Names and Formulas of variable Predictors
  #########################################################
  # Names are used to select relevant columns
  # Formula (parts) are used to be put together and parsed to the lm() function,
  # thats why they have to be added by a * or +
  
  
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
  # these have been determined at earlier step (Covariate) when determining the grouping variables)
  #additional_Factors_Name = input$stephistory[["additional_Factors_Name"]]
  #additional_Factor_Formula = input$stephistory[["additional_Factor_Formula"]]
  # not sure but always three electrodes?

  # [OSC] Electrode factor removed
  # additional_Factors_Name = "Electrode"
  # additional_Factor_Formula = "+ Electrode"
  additional_Factors_Name <- ""
  additional_Factor_Formula <- ""
  
  # merge GMA and Component collumn
  output$Component <- as.character(output$GMA_Measure)
  #########################################################
  # (2) Initiate Functions for Hypothesis Testing
  #########################################################
  wrap_test_Hypothesis <- function (Name_Test, lm_formula, Data, Component, Task, Effect_of_Interest, DirectionEffect,
                                   columns_to_keep, SaveUseModel, ModelProvided, t_group = NA) {
    # wrapping function to parse specific Information to the test_Hypothesis Function
    # Does three things: (1) Select Subset depending on Conditions and Tasks ans Analysis Phase
    # (2) Test the Hypothesis/Calculate Model and 
    # (3) Checks the direction of the effects
    # Inputs:
    # Name_Test is the Name that will be added as first collumn, to identify tests across forks, str (next to the actual interaction term)
    # lm_formula contains the formula that should be given to the lm, str
    # Data contains data (that will be filtered), df
    # GMA_Measure selects relevant Data
    # Task selects relevant Data
    # Effect_of_Interest is used to identify which estimate should be exported, array of str.
    #             the effect is extended by any potential additional factors (hemisphere, electrode...)
    # DirectionEffect is a list with the following named elements:
    #               Effect - char to determine what kind of test, either main, interaction, correlation, interaction_correlation, interaction2_correlation
    #               Personality - char name of personality collumn
    #               Larger - array of 2 chars: first name of collumn coding condition, second name of factor with larger effect
    #               Smaller - array of 2 chars: first name of collumn coding condition, second name of factor with smaller effect
    #               Interaction - array of 3 chars: first name of collumn coding condition additional to Larger/Smaller, second name of factor with smaller effect, third with larger effect
    # columns_to_keep lists all collumns that should be checked for completeness, array of str
    # Task lists the tasks included in this test, array of str
    # SaveUseModel, can be added or left out, options are 
    #           "default" (Model is calculated), 
    #           "exportModel", then model (not estimates) are returned (and Effect of interest and Name_Test are not used)
    #           "previousModel", then model is not recalculated but the provided one is used
    
    # ModelProvided only needed if SaveUseModel is set to "previousModel", output of lm()
    if(missing(SaveUseModel)) { SaveUseModel <- "default"  }
    if(missing(ModelProvided)) { ModelProvided <- "none"  }


    # Create Subset
    Subset <- Data[Data$Component == Component &
                    Data$Task == Task,
                  names(Data) %in% c("ID", "Lab", "Epochs", "SME", "Component", columns_to_keep)]
    
    # Run Test
    # Add false as 7th parameter to not include Lab predictor
    ModelResult <- test_Hypothesis(Name_Test, lm_formula, Subset, Effect_of_Interest, SaveUseModel, ModelProvided, FALSE)
    
    # Test Direction
    if (SaveUseModel != "exportModel") {
      if (!is.na(ModelResult$value_EffectSize)) {
        ModelResult <- test_DirectionEffect(DirectionEffect, Subset, ModelResult)
      }
      
      # [OCS] Add group id for p adjustment
      ModelResult <- ModelResult %>% mutate(t_group = as.integer(t_group))
    }
    
    
    return(ModelResult)
  }
  
  
  
  # General GMA and electrode related

  allElectrodes <- unique(input$data$Electrode)
  allElectrodes <- allElectrodes[!is.na(allElectrodes)]
  
  # Keep track of p adjustment group (family)
  # NOTE: (KLUDGE) While increasing the group ID in the model-test construction loops works, it is a bit complicated in
  # nested loops.
  testGroup <- 0L
  Estimates <- data.frame()
  #########################################################
  # (3) Main Effects of Accuracy for different Tasks
  #########################################################
  # Even though it may seem redundant, the GMA main effects are tested separately, since
  # a) we want to keep the groups sizes independent of the presence of personality measures, and
  # b) we want to correct the p-values for the whole group of parameters — as opposed to the correction per model.

  Names_GMA <- c("rate", "excess", "shape", "skewness", "inflection1", "scaling", "inflection2")
  GMA_colnames <- c("rate", "excess", "shape", "skew", "ip1_ms", "yscale", "ip2_ms")
  nGmaNames <- length(GMA_colnames)
  columns_to_keep <- c("Condition", Covariate_Name, additional_Factors_Name, "GMA_Measure", "EEG_Signal")
  Effect_of_Interest <- "Condition"
  lm_formula <- paste("EEG_Signal ~  Condition ", Covariate_Formula, additional_Factor_Formula)
  # Electrode Fix or possible?
  DirectionEffect_larger <- list("Effect" = "main",
                                "Larger" = c("Condition", "error"),
                                "Smaller" = c("Condition", "correct"))
  DirectionEffect_smaller <- list("Effect" = "main",
                                 "Larger" = c("Condition", "correct"),
                                 "Smaller" = c("Condition", "error"))

  # GMA: All complete cases (i.e., without any missing value caused by a failed GMA or with a missing EEG peak value)
  GmaSet <- output %>%
    filter(GMA_Measure %in% GMA_colnames) %>%
    group_by(ID, Task, Electrode) %>%
    filter(!any(is.na(EEG_Signal))) %>%
    ungroup()

  for (i_task in c("GoNoGo", "Flanker")) {
    for (ch in allElectrodes) {

      testGroup <- testGroup + 1

      for (i_GMA in 1:nGmaNames) {
        print(paste("=== Test ", i_task, Names_GMA[i_GMA]))
        Name_Test <- paste0("GMA_", Names_GMA[i_GMA], "_", i_task, "_", ch)
        if (Names_GMA[i_GMA] %in% c("shape", "rate", "inflection1")) {
          DirectionEffect <- DirectionEffect_larger
        } else {
          DirectionEffect <- DirectionEffect_smaller
        }

        tEstimate <- wrap_test_Hypothesis(
          Name_Test, lm_formula,
          GmaSet %>% filter(Electrode == ch),
          GMA_colnames[i_GMA], i_task,
          Effect_of_Interest, DirectionEffect, columns_to_keep,
          ,, testGroup
        )

        Estimates <- rbind(
          Estimates,
          tEstimate
        )
      }
    }
  }




  #########################################################
  # (4) Personality Effect: GMA (Exploration)
  #########################################################
  # The models in including personality predictors will be p-adjusted per model.

  persColnames <- c("Personality_MPS_PersonalStandards", "Personality_MPS_ConcernOverMistakes")
  persLabels <- c("PSP", "ECP")
  nPersCols <- length(persColnames)

  for (i_task in c("GoNoGo", "Flanker")) {
    for (ch in allElectrodes) {

      GmaSetElec <- GmaSet %>% filter(Electrode == ch)

      lm_formula <- paste("EEG_Signal ~ Condition *", paste(persColnames, collapse = " * "), Covariate_Formula, additional_Factor_Formula)
      columns_to_keep <- c("Condition", Covariate_Name, persColnames, additional_Factors_Name, "GMA_Measure", "EEG_Signal")

      for (i_GMA in 1:nGmaNames) {
        # One p-adjustment group per model (DV)
        testGroup <- testGroup + 1

        Model <- wrap_test_Hypothesis("", lm_formula, GmaSet, GMA_colnames[i_GMA], i_task,
                                     "", "", columns_to_keep,
                                     "exportModel")



        # Test personality main Effect
        DirectionEffect_Main <- list("Effect" = "main",
                                      "Larger" = c("Condition", "error"),
                                      "Smaller" = c("Condition", "correct"))
        Name_Test <- paste0("Condition_", Names_GMA[i_GMA], "_", i_task, "_", ch)
        Estimates <- rbind(Estimates, wrap_test_Hypothesis(paste0("Main_", Name_Test),
                                                           lm_formula,
                                                           GmaSetElec,
                                                           GMA_colnames[i_GMA], i_task,
                                                           "Condition",
                                                           DirectionEffect_Main, columns_to_keep,
                                                           "previousModel", Model, testGroup))

        for (i_pers in 1:nPersCols) {

          persCol <- persColnames[i_pers]
          persLabel <- persLabels[i_pers]

          DirectionEffect_Main <- list("Effect" = "correlation",
                                      "Personality" = persCol)

          DirectionEffect_IA <- list("Effect" = "interaction_correlation",
                                    "Larger" = c("Condition", "error"),
                                    "Smaller" = c("Condition", "correct"),
                                    "Personality" = persCol)



          # Test personality main Effect
          Name_Test <- paste0(persLabel, "_", Names_GMA[i_GMA], "_", i_task, "_", ch)
          Estimates <- rbind(Estimates, wrap_test_Hypothesis(paste0("Main_", Name_Test),
                                                            lm_formula,
                                                            GmaSetElec,
                                                            GMA_colnames[i_GMA], i_task,
                                                            persCol,
                                                            DirectionEffect_Main, columns_to_keep,
                                                            "previousModel", Model, testGroup))

          # Test main Effect of CEI
          Estimates <- rbind(Estimates, wrap_test_Hypothesis(paste0("Interaction_", Name_Test),
                                                            lm_formula,
                                                            GmaSetElec,
                                                            GMA_colnames[i_GMA], i_task,
                                                            c("Condition", persCol),
                                                            DirectionEffect_IA, columns_to_keep,
                                                            "previousModel", Model, testGroup))

        }


        # Interaction of both personlity variables
        Name_Test <- paste0(paste(persLabels, collapse = "_"), "_", Names_GMA[i_GMA], "_", i_task, "_", ch)
        Estimates <- rbind(Estimates, wrap_test_Hypothesis(paste0("Interaction_", Name_Test),
                                                           lm_formula,
                                                           GmaSetElec,
                                                           GMA_colnames[i_GMA], i_task,
                                                           persColnames,
                                                           DirectionEffect_IA, columns_to_keep,
                                                           "previousModel", Model, testGroup))
        # Interaction of condition and both personlity variables
        Name_Test <- paste0("Condition_", paste(persLabels, collapse = "_"), "_", Names_GMA[i_GMA], "_", i_task, "_", ch)
        Estimates <- rbind(Estimates, wrap_test_Hypothesis(paste0("Interaction_", Name_Test),
                                                                    lm_formula,
                                                                    GmaSetElec,
                                                                    GMA_colnames[i_GMA], i_task,
                                                                    c("Condition", persColnames),
                                                                    DirectionEffect_IA, columns_to_keep,
                                                                    "previousModel", Model, testGroup))

      }
    }
  }

  
  ######################################
  # (6) Correct for Multiple Comparisons
  ######################################

  allGroups <- unique(Estimates$t_group)
  allGroups <- allGroups[!is.na(allGroups)]
  
  for (i_group in allGroups) {
    idx <- !is.na(Estimates$t_group) & Estimates$t_group == i_group
    nrTests <- sum(idx, na.rm = TRUE)
    Estimates$p_adj[idx] <- p.adjust(Estimates$p_Value[idx], method = tolower(choice), n = nrTests)
  }
  
  #########################################################
  # (6) Export as CSV file
  #########################################################
  FileName <- input$stephistory[["Final_File_Name"]]
  write.csv(Estimates,FileName, row.names = FALSE)
  
  
  #No change needed below here - just for bookkeeping
  stephistory <- input$stephistory
  stephistory[StepName] <- choice
  return(list(
    data = Estimates,
    stephistory = stephistory
  ))
}
