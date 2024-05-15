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
  # additional_Factors_Name = "Electrode"
  # additional_Factor_Formula = "+ Electrode"
  additional_Factor_Formula = ""

  #########################################################
  # (2) Initiate Functions for Hypothesis Testing
  #########################################################
  wrap_test_Hypothesis = function (Name_Test, lm_formula, Data, Component, Task, columns_to_keep, t_group = NA) {
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
    # columns_to_keep lists all collumns that should be checked for completeness, array of str

    # Create Subset
    Subset = Data[Data$Component == Component &
                    Data$Task == Task,
                  names(Data) %in% c("ID", "Lab", "Epochs", "SME", "Component", columns_to_keep)]

    # Run Model
    ModelResult = test_Hypothesis( Name_Test,lm_formula, Subset, Effect_of_Interest, "exportModel", , FALSE)

    # extract all Effects
    Estimates = rbind(
      # Main Condition
      test_Hypothesis( "Main_Condition",lm_formula, Subset, "Condition", "previousModel", ModelResult, FALSE),

      # Main PersonalStandards
      test_Hypothesis( "Main_PSP",lm_formula, Subset, "Personality_MPS_PersonalStandards", "previousModel", ModelResult, FALSE),

      # Main ConcernOverMistakes
      test_Hypothesis( "Main_ECP",lm_formula, Subset, "Personality_MPS_ConcernOverMistakes", "previousModel", ModelResult, FALSE),

      #  Condition * PersonalStandards
      test_Hypothesis( "ConditionxPSP",lm_formula, Subset, c("Condition", "Personality_MPS_PersonalStandards"), "previousModel", ModelResult, FALSE),

      #  Condition * ConcernOverMistakes
      test_Hypothesis( "ConditionxECP",lm_formula, Subset, c("Condition", "Personality_MPS_ConcernOverMistakes"), "previousModel", ModelResult, FALSE),

      #  PersonalStandards * ConcernOverMistakes
      test_Hypothesis( "PSPxECP",lm_formula, Subset, c("Personality_MPS_PersonalStandards", "Personality_MPS_ConcernOverMistakes"), "previousModel", ModelResult, FALSE),

      #  Condition *PersonalStandards * ConcernOverMistakes
      test_Hypothesis( "ConditionxPSPxESP",lm_formula, Subset, c("Condition", "Personality_MPS_ConcernOverMistakes", "Personality_MPS_PersonalStandards"), "previousModel", ModelResult, FALSE)
    )

    # Adjust Direction to estimates
    # [OCS] Disabled effect direction adjustment to harmonize the results
    # Estimates$value_EffectSize[which(Estimates$Estimate_summary<0)] = Estimates$value_EffectSize[which(Estimates$Estimate_summary<0)]*-1

    # Add Info for Label
    Estimates$Effect_of_Interest = paste0(Name_Test, "_", Estimates$Effect_of_Interest)

    # [OCS] Add group id for p adjustment
    Estimates <- Estimates %>% mutate(t_group = as.integer(t_group))

    return(Estimates)
  }

  # Keep track of p adjustment group (family)
  # NOTE: (KLUDGE) While increasing the group ID in the model-test construction loops works, it is a bit complicated in
  # nested loops.
  testGroup <- 0L


  #########################################################
  # (1) EEG Components
  #########################################################
  #5.1. We expect larger Ne/c amplitudes with higher PSP scores.
  #5.2. We expect smaller Ne/c amplitudes with higher ECP scores.
  #5.3. We expect larger Pe/c amplitudes with larger PSP scores

  # Since there will be no correction for these hypotheses, just use the uncorrected values.

  Estimates = data.frame()

  columns_to_keep = c("Condition", Covariate_Name,
                      "Personality_MPS_PersonalStandards",
                      "Personality_MPS_ConcernOverMistakes",
                      "EEG_Signal")
  lm_formula = paste( "EEG_Signal ~ (Condition * Personality_MPS_PersonalStandards * Personality_MPS_ConcernOverMistakes)",
                      Covariate_Formula, additional_Factor_Formula)

  for (i_Component in c("ERN", "PE")) {
    # General GMA and electrode related
    compData <- output %>% filter(Component == i_Component)
    compElectrodes <- unique(compData$Electrode)
    compElectrodes <- compElectrodes[!is.na(compElectrodes)]

    for (i_task in c("GoNoGo", "Flanker")) {
      for (ch in compElectrodes) {
        print(paste("Test ", i_task, i_Component, ch))

        testGroup <- testGroup + 1L

        Estimates = rbind(Estimates,
                          wrap_test_Hypothesis(paste0(i_task, "_", i_Component, "_", ch),
                                               lm_formula, output %>% filter(Electrode == ch),
                                               i_Component, i_task,
                                               columns_to_keep, testGroup))

      }}}


  #########################################################
  # (5) Behaviour
  #########################################################
  #5.4. We expect more Post-Response Accuracy with higher PSP scores.
  #5.5. We expect less Post-Response Accuracy with higher ECP scores.
  #5.6. We expect more Pre-Post-Response Reaction Time Differences with higher PSP scores.
  #5.7. We expect less Pre-Post-Response Reaction Time Differences with higher ECP scores.
  columns_to_keep <- c("Condition", Covariate_Name,
                       "Personality_MPS_PersonalStandards",
                       "Personality_MPS_ConcernOverMistakes",
                       "Behav")
  lm_formula <- paste("Behav ~ (Condition * Personality_MPS_PersonalStandards * Personality_MPS_ConcernOverMistakes)",
                      Covariate_Formula)

  # Match end of name for hypotheses
  hypoExpr <- c("ConditionxECP$", "ConditionxPSP$")


  for (i_task in c("GoNoGo", "Flanker")) {
    behEstimates <- data.frame()
    for (i_Component in c("RTDiff", "post_ACC")) {
      print(paste("Test ", i_task, i_Component))

      testGroup <- testGroup + 1L

      behEstimates <- rbind(behEstimates,
                            wrap_test_Hypothesis(
                              paste0(i_task, "_", i_Component),
                              lm_formula,
                              output,
                              i_Component,
                              i_task,
                              columns_to_keep,
                              testGroup
                            )
      )
    }

    # [OCS] KLUDGE: Extract the hypotheses' tests and assign them a separate group for p-adjustment.
    #   Hypothesis tests will be prefixed with "H_".
    for(hF in hypoExpr) {
      testGroup <- testGroup + 1L
      hEstimates <- behEstimates %>%
        filter(grepl(hF, Effect_of_Interest)) %>%
        mutate(
          Effect_of_Interest = paste0("H_", Effect_of_Interest),
          t_group = testGroup
        )
      behEstimates <- rbind(behEstimates, hEstimates)

    }
    Estimates <- rbind(Estimates, behEstimates)
  }




  #########################################################
  # (6) Correct for Multiple Comparisons
  #########################################################

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
