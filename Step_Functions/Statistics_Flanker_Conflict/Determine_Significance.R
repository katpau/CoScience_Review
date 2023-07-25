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
  
  
  # CK: covariates to be added to the LMM (in the following way)see test_Hypotheses)
  
  
  # Get possible additional factors to be included in the GLM (depends on the forking
  # these have been determined at earlier step (Covariate) when determining the grouping variables)
  additional_Factors_Name = input$stephistory[["additional_Factors_Name"]]
  additional_Factor_Formula = input$stephistory[["additional_Factor_Formula"]]
  
  
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
                                                                    "SME", "EEG_Signal", columns_to_keep)])
    
    # Run Test
    ModelResult = test_Hypothesis_CK( Name_Test,lm_formula, Subset, Effect_of_Interest, SaveUseModel, ModelProvided, lmFamily)
    
    # Test Direction
    if (!SaveUseModel == "exportModel") {
      if(!is.character(ModelResult) &&  any(!grepl( "Error", ModelResult))) {
        if(!is.na(ModelResult$value_EffectSize)){
          ModelResult = test_DirectionEffect(DirectionEffect, Subset, ModelResult) 
        }}}
    
    return(ModelResult)
  }
  
  
  Estimates = data.frame()
  #########################################################
  # (3) Test Hypothesis set 1 for Behavior: RT/ACC     ####
  # Dispositional CEI relates to behavioral indices    ####
  # Above and beyond Intelligence                      ####
  #########################################################
  for (control_IST in c("", "_withIST")) {
    for (BehavDV in c("RT", "ACC")) {
 
    print(paste("Test Effect on ", BehavDV))
      if (control_IST == "_withIST") {
        lm_formula =   paste( BehavDV, " ~ (( Congruency * Personality_CEI) + IST ) ", Covariate_Formula)
        columns_to_keep = c("Congruency", "Personality_CEI", Covariate_Name, BehavDV, "Congruency_notCentered", 
                            "Block", "Trial", "IST")        
      } else {
    lm_formula =   paste( BehavDV, " ~ (( Congruency * Personality_CEI) ) ", Covariate_Formula)
    columns_to_keep = c("Congruency", "Personality_CEI", Covariate_Name, BehavDV, "Congruency_notCentered", 
                        "Block", "Trial")
      }
    Effect_of_Interest = c("Personality_CEI")
    Effect_of_Interest_IA = c("Personality_CEI", "Congruency")
    DirectionEffect = list("Effect" = "correlation",
                           "Personality" = "Personality_CEI",
                           "DV" = BehavDV)
    DirectionEffect_IA = list("Effect" = "interaction_correlation",
                              "Larger" = c("Congruency_notCentered", "0"),
                              "Smaller" = c("Congruency_notCentered", "1"),
                              "Personality" = "Personality_CEI",
                              "DV" = BehavDV)
    
    if (BehavDV == "ACC") { lmFamily  = "binominal"} else {lmFamily = "standard" }
    H_1_Model = wrap_test_Hypothesis("",lm_formula, output,
                                     "",  "", 
                                     columns_to_keep, "Behav",
                                     "exportModel", "", lmFamily )
    # Test main Effect of CEI  
    Name_Test = paste0(BehavDV,"_CEI", control_IST)
    Estimates = rbind(Estimates, wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                                      DirectionEffect, columns_to_keep, "Behav",
                                                      "previousModel", H_1_Model))
    
    # Test IA with CEI and Demand Level
    Name_Test = paste0(BehavDV, "_CEI_Congruency", control_IST)
    Estimates = rbind(Estimates,wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest_IA,
                                                     DirectionEffect_IA, columns_to_keep, "Behav",
                                                     "previousModel", H_1_Model)  )
  }}
 
  
  
  #########################################################
  # (4) Test Hypothesis set 1 for EEG                  ####
  # Dispositional CEI relates to neurophysiological indices#
  # Above and beyond Intelligence                      ####
  #########################################################

  DirectionEffect = list("Effect" = "correlation",
                         "Personality" = "Personality_CEI")
  DirectionEffect_IA = list("Effect" = "interaction_correlation",
                            "Larger" = c("Congruency_notCentered", "0"),
                            "Smaller" = c("Congruency_notCentered", "1"),
                            "Personality" = "Personality_CEI")
  for (control_IST in c("", "_withIST")) {  
    if (control_IST == "_withIST") {
      lm_formula =   paste( "EEG_Signal ~ ((( Congruency * Personality_CEI) ", 
                            additional_Factor_Formula, ")", Covariate_Formula, "+ IST )")
      columns_to_keep = c("Congruency", "Personality_CEI", "Congruency_notCentered",
                          Covariate_Name, additional_Factors_Name, "IST") 
      
    } else {
      lm_formula =   paste( "EEG_Signal ~ (( Congruency * Personality_CEI) ", 
                            additional_Factor_Formula, ")", Covariate_Formula)
      columns_to_keep = c("Congruency", "Personality_CEI", "Congruency_notCentered",
                          Covariate_Name, additional_Factors_Name) 
      
    }
  for (DV in c("N2", "P3", "FMT")) {
    print(paste("Test Effect on ", DV))
    H_4_Model = wrap_test_Hypothesis("",lm_formula, output,
                                     "",  "", 
                                     columns_to_keep, DV,
                                     "exportModel")
    
    
    # Test main Effect of CEI  
    Name_Test = paste0(DV, "_CEI", control_IST)
    Estimates = rbind(Estimates, wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                                      DirectionEffect, columns_to_keep, DV,
                                                      "previousModel", H_4_Model))
    
    # Test IA with CEI and Demand Level
    Name_Test = paste0(DV, "_CEI_Congruency", control_IST)
    Estimates = rbind(Estimates, wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest_IA,
                                                      DirectionEffect_IA, columns_to_keep, DV,
                                                      "previousModel", H_4_Model)  )
  }}
  
  
  
  # TO DO??????
  # CK: additionally both models can be compared by criterions like (R², AIC)
  # or by model comparison with test for deviances via ANOVA
  #anova(m1., m2)
  # m1 = model of Hypothesis 1+2
  # m2 = model with fluid intelligence as additional predictor Hypothesis 3
  # the smaller the deviance the better fits the model
  # significance examination  
  
  
  
  # TO DO??????
  ## 1 Null model to calculate intra-class correlation
  #m0 <- lmer(EEG_Signal ~ 1 + (1 | ID), data = Subset)  
    # criterion = RT, FMT, N2, P3 
    # data = data frame for each criterion containing the respective trial by trial data (cf. test_Hypothesis.R) as subset of main data frame
  
  # intraclass correlation (ICC) = random intercept variance / (random intercept variance + residual variance)
  #var_m0 <- as.data.frame(VarCorr(m0))
  #var_m0$vcov[1] / (var_m0$vcov[1] + var_m0$vcov[2])
  

  # TO DO?????
  ## Exploratory: controlling for block and nesting in lab
  #m1e <- lmer(criterion ~ demand.cwc * CEI.cgm + electrode.cwc + block.cwc
  #            # + fluidIntelligence.cgm                                     # for m2e
  #            + (demand.cwc | labID / ID), data = sub.df)
  
  
  
  
  ############################
  # Hypthesis 4: Correlations
  ############################
  Subset = output[,c("ID", "Personality_LE_Positiv", "Personality_NFC_NeedForCognition",  "Personality_CEI" )]
  Subset = Subset[!duplicated(Subset),]
  Subset = Subset[,-1]
  # psych::corr.test(x, y = NULL, use = "pairwise",method="pearson",adjust="holm", alpha=.05,ci=TRUE,minlength=5,normal=TRUE)
  if (!choice == "None") {
    Cors  = psych::corr.test(Subset, adjust = tolower(choice)) 
    p_s = Cors$p.adj
  } else {
    Cors  = psych::corr.test(Subset) 
    p_s = Cors$ci$p
  }
  
  Cors_Estimates = cbind(
    c("Correlation_LE_NFC", "Correlation_LE_CEI", "Correlation_CEI_NFC")  ,
    "pearsonR", "r",
    Cors$ci$r,Cors$ci$lower, Cors$ci$upper, p_s,
    matrix(data=NA,nrow=3,ncol=7),
    nrow(Subset),
    matrix(data=NA,nrow=3,ncol=7))
  colnames(Cors_Estimates) = colnames(Estimates)
  Estimates = rbind(Estimates,Cors_Estimates)
                 
  
  ############################
  # Hypthesis 5: Exploratory ESC and COM?
  ############################
  #????? TO DO????
  
 
  #########################################################
  # (5) Correct for Multiple Comparisons for Hypothesis 1 
  #########################################################
  if (!choice == "None") {
    for( Subtests in c("RT|ACC", "FMT|N2|P3")) {
      nrTests = length(str_split_1(Subtests,  "\\|"))
      for (Test_of_interest in c("_CEI", "_Congruency", "CEI_Congruency")) {
        for (withIST in c("", "_withIST")) {
        Idx =  grepl(Subtests, Estimates$Effect_of_Interest) &
          endsWith(Estimates$Effect_of_Interest, paste0(Test_of_interest,withIST ))
        Idx1 = Idx & is.na(Estimates$pvalue) # one from std coefficients
        Idx2 = Idx & is.na(Estimates$p_value) # one from anova
        
        Estimates$pvalue[Idx1] = p.adjust(Estimates$pvalue[Idx1],
                                                    method = tolower(choice), n = nrTests)
        Estimates$pvalue[Idx2] = p.adjust(Estimates$pvalue[Idx2],
                                          method = tolower(choice), n = nrTests)
        }
      }
    }
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
