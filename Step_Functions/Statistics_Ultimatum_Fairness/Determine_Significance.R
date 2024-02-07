Determine_Significance = function(input = NULL, choice = NULL) {
  StepName = "Determine_Significance"
  Choices = c("Holm", "Bonferroni", "None")
  Order = 13
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by: CK 4/23
  
  # Handles all Choices listed above 
  # Runs the statistical Test, corrects for multiple comparisons and 
  # Prepares Output Table
  
  # (1) Get Names and Formulas of Variable Predictors
  # (2) Initiate Functions for Hypothesis Testing
  # (3) Prepare Averages across Conditions and Correlations
  # (4) Test State Hypothesis (H1)
  # (5) Correct for Multiple Comparisons for Hypothesis 1 and Combine all Estimates
  # (6) Export as CSV file
  
  
  
  
  #########################################################
  # (1) Get Names and Formulas of Variable Predictors  ####
  #########################################################
  # Names are used to select relevant columns
  # Formula (parts) are used to be put together and parsed to the lm() function,
  # that's why they have to be added by a * or +
  
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
  additional_Factors_Name = input$stephistory[["additional_Factors_Name"]]
  additional_Factor_Formula = input$stephistory[["additional_Factor_Formula"]]
  
  # Drop no Choices
  output = output[!output$Choice == "None",]
  
  #########################################################
  # (2) Initiate Functions for Hypothesis Testing      ####
  #########################################################
  wrap_test_Hypothesis = function (Name_Test,lm_formula,  Data, Effect_of_Interest, DirectionEffect,
                                   columns_to_keep, Component, SaveUseModel, ModelProvided, lmFamily ) {
    
    # wrapping function to parse specific Information to the test_Hypothesis Function
    # Does three things: 
    # (1) Selects Subset depending on Conditions and Tasks and Analysis Phase
    # (2) Tests the Hypothesis/Calculate Model and 
    # (3) Checks the direction of the effects
    # Inputs:
    # Name_Test is the Name that will be added as first column, to identify tests across forks, str (next to the actual interaction term)
    # lm_formula contains the formula that should be given to the lm, str
    # Data contains data (that will be filtered), df
    # Effect_of_Interest is used to identify which estimate should be exported, array of str.
    #             the effect is extended by any potential additional factors (hemisphere, electrode...)
    # DirectionEffect is a list with the following named elements:
    #               Effect - char to determine what kind of test, either main, interaction, correlation, interaction_correlation, interaction2_correlation
    #               Personality - char name of personality column
    #               Larger - array of 2 chars: first name of column coding condition, second name of factor with larger effect
    #               Smaller - array of 2 chars: first name of column coding condition, second name of factor with smaller effect
    #               Interaction - array of 3 chars: first name of column coding condition additional to Larger/Smaller, second name of factor with smaller effect, third with larger effect
    # columns_to_keep lists all columns that should be checked for completeness, array of str
    # Component lists the Component included in this test, array of str
    # SaveUseModel, can be added or left out, options are 
    #           "default" (Model is calculated), 
    #           "exportModel", then model (not estimates) are returned (and Effect of interest and Name_Test are not used)
    #           "previousModel", then model is not recalculated but the provided one is used
    
    # ModelProvided only needed if SaveUseModel is set to "previousModel", output of lm()
    if(missing(SaveUseModel)) { SaveUseModel = "default"  }
    if(missing(ModelProvided)) { ModelProvided = "none"  }
    if(missing(lmFamily)) {lmFamily = "standard"}
    
    
    # Create Subset
    Subset = as.data.frame(Data[Data$Component %in% Component, names(Data) %in% c("ID", "Lab", "Epochs", 
                                                                                  "EEG_Signal", columns_to_keep)]) #"SME",
    
    # Run Test
    ModelResult = test_Hypothesis_V3( Name_Test,lm_formula, Subset, Effect_of_Interest, SaveUseModel, ModelProvided, lmFamily)
    
    # Test Direction ??? 
    if (!SaveUseModel == "exportModel") {
      if(!is.character(ModelResult)  &&  any(!grepl( "Error", ModelResult))) {
        if(!is.na(ModelResult$value_EffectSize)){
          ModelResult = test_DirectionEffect(DirectionEffect, Subset, ModelResult) 
        }}}
    
    return(ModelResult)
  }
  
  
  Estimates = data.frame()
  
  
  for (Component in c("FRN", "FMT")) {
    ##########################################################################
    # Hypothesis 1.1: Offer modulates FRN/FMT
    ##########################################################################
    Name_Test = paste0(Component, "_MainOffer")
    Effect_of_Interest = c("Offer")
    DirectionEffect = list("Effect" = "main",
                           "Larger" = c("Offer", "5"),
                           "Smaller" = c("Offer", "1"))
    
    lm_formula =   paste( "EEG_Signal ~ ( Offer + Trial ) ", 
                          Covariate_Formula, additional_Factor_Formula)
    columns_to_keep = c("Offer", Covariate_Name, "EEG_Signal", "Electrode", "Trial")
    
    
    Estimates = rbind(Estimates,
                      wrap_test_Hypothesis(Name_Test,lm_formula, output,
                                           Effect_of_Interest,
                                           DirectionEffect, 
                                           columns_to_keep, Component))
    
    ##########################################################################
    # Hypothesis 2.1: Personality modulates offer effect on FRN/FMT
    ##########################################################################
    for (iPersonality in colnames(output)[grepl("Personality", colnames(output))]) {
    Name_Test = paste0(Component, "_Offer_x_", iPersonality)
    Effect_of_Interest = c("Offer", iPersonality)
    DirectionEffect = list("Effect" = "interaction_correlation",
                           "Larger" = c("Offer", "5"),
                           "Smaller" = c("Offer", "1"),
                           "Personality" = iPersonality)
    

    
    if (length(Covariate_Name)>1 & grepl("Age", iPersonality) && grepl("Age", Covariate_Name)) {
      appliedCovariate_Formula = ""
    } else {appliedCovariate_Formula = Covariate_Formula }
                                           
    lm_formula =   paste( "EEG_Signal ~ ( Offer *", iPersonality, "+ Trial) ", 
                          appliedCovariate_Formula, additional_Factor_Formula)
    columns_to_keep = c("Offer", Covariate_Name, "EEG_Signal", "Electrode", iPersonality, "Trial")
    
    
    Estimates = rbind(Estimates,
                      wrap_test_Hypothesis(Name_Test,lm_formula, output,
                                           Effect_of_Interest,
                                           DirectionEffect, 
                                           columns_to_keep, Component))
  }}
    
    
    
  ##########################################################################
  # Hypothesis 3: Offer and choice modulate RT
  ##########################################################################
  lm_formula =   paste( "RT ~ ( Offer * Choice  + Trial ) ", 
                        Covariate_Formula)
  columns_to_keep = c("Offer", Covariate_Name, "RT", "Choice", "Trial")
  
  H_3_Model = wrap_test_Hypothesis("",lm_formula, output,
                                   "",  "", 
                                   columns_to_keep, "Behav",
                                   "exportModel")
  
  Name_Test = "Behav_MainOffer"
  Effect_of_Interest = c("Offer")
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Offer", "5"),
                         "Smaller" = c("Offer", "1"),
                         "DV" = "RT")
  Estimates = rbind(Estimates, wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                                    DirectionEffect, columns_to_keep, "Behav",
                                                    "previousModel", H_3_Model))
  
 
  Name_Test = "Behav_MainChoice"
  Effect_of_Interest = c("Choice")
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Choice", "Reject"),
                         "Smaller" = c("Choice", "Accept"),
                         "DV" = "RT")
  Estimates = rbind(Estimates, wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                                    DirectionEffect, columns_to_keep, "Behav",
                                                    "previousModel", H_3_Model)) 
  
  
  

  ##########################################################################
  # Hypothesis 1.2: Offer modulate Choice
  ##########################################################################
  output$Choice = as.numeric(as.factor(output$Choice))-1
  Name_Test = "Choice_MainOffer"
  Effect_of_Interest = c("Offer")
  DirectionEffect = list("Effect" = "main",
                         "Larger" = c("Offer", "5"),
                         "Smaller" = c("Offer", "1"),
                         "DV" = "Choice")
  
  lm_formula =   paste( "Choice ~ ( Offer +  Trial ) ", 
                        Covariate_Formula)
  columns_to_keep = c("Offer", Covariate_Name, "Choice", "Trial")
  
  
  Estimates = rbind(Estimates,
                    wrap_test_Hypothesis(Name_Test,lm_formula, output,
                                         Effect_of_Interest,
                                         DirectionEffect, 
                                         columns_to_keep, "Behav",  "", "", "binominal"))

  
  ##########################################################################
  # Hypothesis 2.1: Personality modulate Offer effect on Acceptance
  ##########################################################################  
  for (iPersonality in colnames(output)[grepl("Personality", colnames(output))]) {
    Name_Test = paste0("Choice_Offer_x_", iPersonality)
    Effect_of_Interest = c("Offer", iPersonality)
    DirectionEffect = list("Effect" = "interaction_correlation",
                           "Larger" = c("Offer", "5"),
                           "Smaller" = c("Offer", "1"),
                           "Personality" = iPersonality)
    
    
    
    if (length(Covariate_Name)>1 & grepl("Age", iPersonality) && grepl("Age", Covariate_Name)) {
      appliedCovariate_Formula = ""
    } else {appliedCovariate_Formula = Covariate_Formula }
    
    lm_formula =   paste( "Choice ~ ( Offer *", iPersonality, "+ Trial) ", 
                          appliedCovariate_Formula)
    columns_to_keep = c("Offer", Covariate_Name, "Choice", "Trial", iPersonality)
    
    
    Estimates = rbind(Estimates,
                      wrap_test_Hypothesis(Name_Test,lm_formula, output,
                                           Effect_of_Interest,
                                           DirectionEffect, 
                                           columns_to_keep, "Behav",  "", "", "binominal"))
  }
  
  ##########################################################################
  # Hypothesis 4.1/2: FNR/FMT modulate Acceptance
  ##########################################################################  
  for (Component in c("FRN", "FMT")) {
    Name_Test = paste0("Choice_Main", Component)
    Effect_of_Interest = c("EEG_Signal")
    DirectionEffect = list("Effect" = "correlation",
                           "Personality" = "EEG_Signal",
                           "DV" = "Choice")
    
    lm_formula =   paste( "Choice ~ ( Offer + Trial) ", 
                          Covariate_Formula, additional_Factor_Formula)
    columns_to_keep = c("Offer", Covariate_Name, "EEG_Signal", "Choice", "Electrode", "Trial")
    
    
    Estimates = rbind(Estimates,
                      wrap_test_Hypothesis(Name_Test,lm_formula, output,
                                           Effect_of_Interest,
                                           DirectionEffect, 
                                           columns_to_keep, "Behav",  "", "", "binominal"))
    
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
