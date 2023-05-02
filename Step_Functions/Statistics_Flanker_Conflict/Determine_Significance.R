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
  # if e.g. no difference scores were calculated, then hemisphere should be added.
  # these have been determined at earlier step (Covariate) when determining the grouping variables)
  additional_Factors_Name = input$stephistory[["additional_Factors_Name"]]
  additional_Factor_Formula = input$stephistory[["additional_Factor_Formula"]]
  
  
  #########################################################
  # (2) Initiate Functions for Hypothesis Testing      ####
  #########################################################
  wrap_test_Hypothesis = function (Name_Test,lm_formula,  Data, Effect_of_Interest, DirectionEffect,
                                   columns_to_keep, Component, SaveUseModel, ModelProvided) {
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
    
    
    # Create Subset
    Subset = Data[Data$Component %in% Component, names(Data) %in% c("ID", "Epochs", "SME", "EEG_Signal", columns_to_keep)]
    
    # Run Test
    ModelResult = test_Hypothesis( Name_Test,lm_formula, Subset, Effect_of_Interest, SaveUseModel, ModelProvided)
    
    # Test Direction
    if (!SaveUseModel == "exportModel") {
      ModelResult = test_DirectionEffect(DirectionEffect, Subset, ModelResult) 
    }
    
    return(ModelResult)
  }
  
  
  
  #########################################################
  # (4) Test Hypothesis set 1 for Behavior             ####
  #########################################################
  Estimates = data.frame()
  for (DV in c("Behav_RT", "ACC")) {
    print(paste("Test Effect on ", DV))
    lm_formula =   paste( DV,  " ~ (( Congruency * Personality_CEI) ) ", Covariate_Formula)
    columns_to_keep = c("Congruency", "Personality_CEI", Covariate_Name, DV) 
    
    Effect_of_Interest = c("Personality_CEI")
    Effect_of_Interest_IA = c("Personality_CEI", "Congruency")
    DirectionEffect = list("Effect" = "correlation",
                           "Personality" = "Personality_CEI",
                           "DV" = DV)
    DirectionEffect_IA = list("Effect" = "interaction_correlation",
                              "Larger" = c("Congruency", "Cong_000"),
                              "Smaller" = c("Congruency", "Cong_100"),
                              "Personality" = "Personality_CEI",
                              "DV" = DV)
    
    
    H_1_Model = wrap_test_Hypothesis("",lm_formula, output,
                                     "",  "", 
                                     columns_to_keep, "RT",
                                     "exportModel")
    # Test main Effect of CEI  
    Name_Test = paste0(DV, "_CEI")
    Estimates = rbind(Estimates, wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                                      DirectionEffect, columns_to_keep, "RT",
                                                      "previousModel", H_1_Model))
    
    # Test IA with CEI and Demand Level
    Name_Test = paste0(DV, "_CEI_Congruency")
    Estimates = rbind(Estimates,wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest_IA,
                                                     DirectionEffect_IA, columns_to_keep, "RT",
                                                     "previousModel", H_1_Model)  )
  }
  
  # FIXME @Kat CK: added LMM and GLM
  
  ## 1 Null model to calculate intra-class correlation
  m0 <- lmer(criterion ~ 1 + (1 | ID), data = sub.df)  
    # criterion = RT, FMT, N2, P3 
    # data = data frame for each criterion containing the respective trial by trial data (cf. test_Hypothesis.R) as subset of main data frame
  
  # intraclass correlation (ICC) = random intercept variance / (random intercept variance + residual variance)
  var_m0 <- as.data.frame(VarCorr(m0))
  var_m0$vcov[1] / (var_m0$vcov[1] + var_m0$vcov[2])
  
  
  ## 2 set up LMM (Hypothesis 1+2)
  m1 <- lmer(criterion ~ demand.cwc * CEI.cgm + electrode.cwc 
             + (demand.cwc | ID), data = sub.df)
    # predictors need to be centered (cf. test_Hypothesis.R)
  
  
  ## 3 set up LMM, additional predictor: fluid intelligence (Hypothesis 3)
  m2 <- lmer(criterion ~ demand.cwc * CEI.cgm + electrode.cwc + fluidIntelligence.cgm 
             + (demand.cwc | ID), data = sub.df)
  
  ## 4 set up GLMM for error rate / accuracy as is has a binomial distribution (Hypothesis 1+2)
  m1.ac <- glmer(correct ~ demand.cwc * CEI.cgm + electrode.cwc
                 + (demand.cwc | ID), data = sub.ac,
                 family = binomial(link = "logit"))
  
  ## 5 set up GLMM for error rate / accuracy as is has a binomial distribution, additional predictor: fluid intelligence (Hypothesis 3)
  m2.ac <- glmer(correct ~ demand.cwc * CEI.cgm + electrode.cwc + fluidIntelligence.cgm
                 + (demand.cwc | ID), data = sub.ac,
                 family = binomial(link = "logit"))
  
  ## Exploratory: controlling for block and nesting in lab
  m1e <- lmer(criterion ~ demand.cwc * CEI.cgm + electrode.cwc + block.cwc
              # + fluidIntelligence.cgm                                     # for m2e
              + (demand.cwc | labID / ID), data = sub.df)
  
  
  
  #########################################################
  # (4) Test Hypothesis set 1 for EEG
  #########################################################
  lm_formula =   paste( "EEG_Signal ~ (( Congruency * Personality_CEI) ", 
                        additional_Factor_Formula, ")", Covariate_Formula)
  columns_to_keep = c("Congruency", "Personality_CEI", Covariate_Name, additional_Factors_Name) 
  
  DirectionEffect = list("Effect" = "correlation",
                         "Personality" = "Personality_CEI")
  DirectionEffect_IA = list("Effect" = "interaction_correlation",
                            "Larger" = c("Congruency", "Cong_000"),
                            "Smaller" = c("Congruency", "Cong_100"),
                            "Personality" = "Personality_CEI")
  
  for (DV in c("N2", "P3", "FMT")) {
    print(paste("Test Effect on ", DV))
    H_4_Model = wrap_test_Hypothesis("",lm_formula, output,
                                     "",  "", 
                                     columns_to_keep, DV,
                                     "exportModel")
    
    
    # Test main Effect of CEI  
    Name_Test = paste0(DV, "_CEI")
    Estimates = rbind(Estimates, wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                                      DirectionEffect, columns_to_keep, "N2",
                                                      "previousModel", H_4_Model))
    
    # Test IA with CEI and Demand Level
    Name_Test = paste0(DV, "_CEI_Congruency")
    Estimates = rbind(Estimates, wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest_IA,
                                                      DirectionEffect_IA, columns_to_keep, "N2",
                                                      "previousModel", H_4_Model)  )
  }
  
  
  #######################
  #  and Hypothesis 3 
  # reaction times, error rates, FM?? power, N2 and P3 amplitude (x.1. - x.5.) are
  # predicted in a hierarchical regression. First, (1) Demand levels, (2) CEI, (3) Electrode is included, then
  # (4) fluid intelligence.
  # Hypotheses 3 is tested when the main effect and interaction of CEI remains significant when fluid
  # intelligence is entered.
  
  # CK: additionally both models can be compared by criterions like (R², AIC)
  # or by model comparison with test for deviances via ANOVA
  anova(m1., m2)
    # m1 = model of Hypothesis 1+2
    # m2 = model with fluid intelligence as additional predictor Hypothesis 3
  # the smaller the deviance the better fits the model
  # significance examination  
  
  
  ############################
  # Hypthesis 4: Correlations
  ############################
  Subset = output[,c("ID", "Personality_LE_Positiv", "Personality_NFC_NeedForCognition",  "Personality_CEI" )]
  Subset = Subset[!duplicated(Subset),]
  C1 = cor.test(Subset$Personality_LE_Positiv, Subset$Personality_NFC_NeedForCognition, method = "pearson")
  C2 = cor.test(Subset$Personality_LE_Positiv, Subset$Personality_CEI, method = "pearson")
  C3 = cor.test(Subset$Personality_CEI, Subset$Personality_NFC_NeedForCognition, method = "pearson")
  # CK: why just do one correlation test (correlations would be automatically adjusted - but maybe that's the problem?)
    # psych::corr.test(x, y = NULL, use = "pairwise",method="pearson",adjust="holm", alpha=.05,ci=TRUE,minlength=5,normal=TRUE)
  C  = corr.test(c(Subset$Personality_LE_Positiv, Subset$Personality_NFC_NeedForCognition, Subset$Personality_CEI))
    # save correlation matrix: round(C$r, 2)
    # save p-values: round(C$p, 4)       
  
  Estimates = rbind(Estimates,
                    c("Correlation_LE_NFC", "pearsonR", "r", C1$estimate, C1$conf.int[1], C1$conf.int[2], C1$p.value, nrow(Subset),NA, NA, NA ),
                    c("Correlation_LE_CEI" ,"pearsonR", "r", C2$estimate, C2$conf.int[1], C2$conf.int[2], C2$p.value, nrow(Subset),NA, NA, NA),
                    c("Correlation_CEI_NFC","pearsonR", "r", C3$estimate, C3$conf.int[1], C3$conf.int[2], C3$p.value, nrow(Subset),NA, NA, NA))
  
  
  #########################################################
  # (5) Correct for Multiple Comparisons for Hypothesis 1 #### # CK: 1,2,3
  #########################################################
  
  Estimates_to_Correct = as.data.frame(rbind(H1_4, H1_5)) # redo also for Behavioral, add FMT - make a loop? since many blocked!
  comparisons = sum(!is.na(Estimates_to_Correct$p_Value))
  
  if (choice == "Holmes"){
    Estimates_to_Correct$p_Value = p.adjust(Estimates_to_Correct$p_Value, method = "holm", n = comparisons)
  }  else if (choice == "Bonferroni"){
    Estimates_to_Correct$p_Value = p.adjust(Estimates_to_Correct$p_Value, method = "bonferroni", n = comparisons)
  }
  
  Estimates = rbind(Estimates_to_Correct,
                    H1_1  ) # Add other estimates here
  
  
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
