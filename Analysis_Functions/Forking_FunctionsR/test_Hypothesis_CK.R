test_Hypothesis_CK = function (Name_Test,lm_formula, Subset, columns_to_keep, Effect_of_Interest, SaveUseModel, ModelProvided, lmFamily, Nullmodel) {
  # this function is used to export the relevant estimates from the tested model or the model (determined by SaveUseModel)
  # Name_Test is the Name that will be added as first column, to identify tests across forks, str (next to the actual interaction term)
  # lm_formula contains the formula that should be given to the lm, str
  # output contains (subset) of the data, df
  # Effect_of_Interest is used to identify which estimate should be exported, array of str.
  #             the effect is extended by any potential additional factors (hemisphere, electrode...)
  # SaveUseModel, can be added or left out, options are 
  #           "default" (Model is calculated), 
  #           "exportModel", then model (not estimates) are returned (and Effect of interest and Name_Test are not used)
  #           "previousModel", then model is not recalculated but the provided one is used
  # ModelProvided only needed if SaveUseModel is set to "previousModel", output of lm()
  
  # Set relevant Input if not given
  if(missing(SaveUseModel)) { SaveUseModel = "default"  }
  if(missing(ModelProvided)) { ModelProvided = "none"  }
  if(missing(lmFamily)) {lmFamily = "standard"}
  if(missing(Nullmodel)) {Nullmodel = ""}
  StopModel = 0
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # GetName of all relevant columns
  keptcolumns = colnames(Subset)

  # Select relevant data and make sure its complete
  colNames_all = names(Subset)
  # Get DV
  DV = gsub(" ", "", str_split(lm_formula, "~")[[1]][1])
  # Second select columns based
  relevant_columns = c(DV, colNames_all[grepl("Personality_", colNames_all)],  colNames_all[grepl("Covariate_", colNames_all)])
  # Third make sure cases are complete
  Subset = Subset[complete.cases(Subset[,colnames(Subset) %in% relevant_columns]), ]
  
  classes_df = lapply(Subset[names(Subset)], class)
  make_Factor = names(classes_df[classes_df == "character"])
  Subset[make_Factor] = lapply(Subset[make_Factor], as.factor)
  
  

  
 
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Prepare and Calculate LMer Model
  if (!SaveUseModel == "previousModel"){ 
    # check if data has been processed, otherwise don't proceed
    if (length(unique(Subset$ID))<10) { # Change for final analysis
      Model_Result = c("Error_when_computing_Model", lm_formula, lmFamily, "To Few Subs" )
      
    } else {
      
      print("Calculating LMER")
      
      ## 1. change global coding in order to get meaningful results
      # to orthogonal sum-to-zero contrast 
      options(contrasts = c("contr.sum", "contr.poly"))
      
      #?? Update Formula if levels singular?
      for (iCol in keptcolumns) {
        if(length(unique(as.character((as.data.frame(Subset)[,iCol]))))<2) {
          if (grepl(iCol, lm_formula)) {
            print("Dropped Factor")
            print(iCol)
            lm_formula = gsub(paste0("\\* ", iCol), "", lm_formula)
          }}
      }
      
 
     
      

      
      #####################################################################################
      # Do NOT Add Lab Predictor
      # lm_formula = paste(lm_formula, "+ (1|Lab)") 
      
      # check how many levels per sub
      EntriesPerSub = Subset %>% count(ID) %>% summarise(max(n))

      noRandomFactor = 0 # Next does not work if TRIAL is included
      lm_formula = paste(lm_formula, "+ (Congruency|ID)")  
      lm_formula_noAdd_Random = lm_formula

      # Also run 0 Model => DV can vary!
      if (Nullmodel == "") {
        formula_NULL = paste(DV, " ~ 1 + (1|ID)")
      } else {
        formula_NULL = gsub(Nullmodel, "", lm_formula)
      }
      
      # Remove Nas
      Subset = Subset[,c(columns_to_keep, "ID", "Lab", "Epochs", DV)]
      Subset = Subset[complete.cases(Subset),]
      
      
      #####################################################################################
      # Calculate LM Model
      if (noRandomFactor == 1) {
        Model_Result = tryCatch({
          if (is.factor(Subset$Lab)) {Subset$Lab = as.numeric(Subset$Lab)}
          if (is.factor(Subset$ID)) {Subset$ID = as.numeric(Subset$ID)}

          if (lmFamily == "standard") {
            Model_Result = lm(as.formula(lm_formula), 
                            Subset)
          } else if(lmFamily == "binominal") {
            Model_Result = glm(as.formula(lm_formula), 
                              Subset,
                              family = binomial(link = "logit") )
        }
          
          Model_Result$formula = lm_formula
          Model_Result$lmFamily = lmFamily 
          Model_Result
          
        }, error = function(e) {
          print("Error with Model")
          Model_Result = c("Error_when_computing_Model", lm_formula,lmFamily, Error_Message)
          return(Model_Result)
        })
        
        
      } else {
        Model_Result = tryCatch({
          if (is.factor(Subset$Lab)) {Subset$Lab = as.numeric(Subset$Lab)}
          if (is.factor(Subset$ID)) {Subset$ID = as.numeric(Subset$ID)}
          if (lmFamily == "standard") {
          Model_Result = lmer(as.formula(lm_formula), 
                              Subset,
                              control = lmerControl(optimizer = "bobyqa")) 
          NullModel = lmer(as.formula(formula_NULL), 
                              Subset,
                              control = lmerControl(optimizer = "bobyqa")) 
          } else if(lmFamily == "binominal") {
            Model_Result = glmer(as.formula(lm_formula), 
                                Subset,
                                family = binomial(link = "logit"),
                                control = glmerControl(optimizer = "bobyqa")) 
            NullModel = glmer(as.formula(formula_NULL), 
                                 Subset,
                                 family = binomial(link = "logit"),
                                 control = glmerControl(optimizer = "bobyqa")) 
          }
          attributes(Model_Result)$formula = lm_formula
          attributes(Model_Result)$lmFamily = lmFamily
          attributes(Model_Result)$NullModel =  NullModel
          attributes(Model_Result)$formula_NULL = formula_NULL
          Model_Result
        }, error = function(e) {
          print("Error in Model")
          Error_Message = conditionMessage(e)
          Model_Result = c("Error_when_computing_Model", lm_formula,lmFamily, Error_Message)
          return(Model_Result)
        })
        
        
        # only relevant if next to random ID also random IA with ID given 
        # if (is.character(Model_Result) &&  grepl( "Error", Model_Result)) {
        #   # Try again with less random predictors
        #   Model_Result = tryCatch({
        #     Model_Result = lmer(as.formula(lm_formula_noAdd_Random), 
        #                         Subset) 
        #     print("Error in Model fixed by dropping random predictors")
        #     attributes(Model_Result)$formula = lm_formula_noAdd_Random
        #     Model_Result
        #   }, error = function(e) {
        #     print("Error in Model even after dropping random predictors")
        #     Model_Result = c("Error_when_computing_Model", lm_formula_noAdd_Random)
        #     return(Model_Result)
        #   })
        #   
        #   
        # }
        
        
      }
      
    } # If Model is provided, get it here
  } else {  
    print("Using existing LMER")
    Model_Result = ModelProvided
    if ((is.character(Model_Result) &&  grepl( "Error", Model_Result[1])) ) {
      lm_formula = Model_Result[2]
      lmFamily = Model_Result[3]
      Error_Message = Model_Result[4]
      Model_Result = Model_Result[1]
      
      
    } else {
      if (class(Model_Result) == "lm") {
        lm_formula = Model_Result$formula
        lmFamily = Model_Result$lmFamily
        NullModel = Model_Result$NullModel
        
      } else {
        lm_formula = Model_Result@formula
        lmFamily = Model_Result@lmFamily
        NullModel = Model_Result@NullModel
        formula_NULL = Model_Result@formula_NULL
        }
      
    }}
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # if only model is exported, stop here
  if (SaveUseModel == "exportModel")  {
    print("only Export Model")
    return(Model_Result)
    break
    # prepare export of parameters
  } else { 
    print("Prepare Estimates")
    # Check if Model was calculated successfully
    #  If there were Problems with the Model, extract NAs
    if (is.character(Model_Result) &&  grepl( "Error", Model_Result[1])) {
      print("no Estimates since Error with Model ")
      if (SaveUseModel == "default") {        Error_Message = Model_Result[4]       }
      Estimates = cbind.data.frame(Name_Test, "Error with Model", t(rep(NA, 11)), lm_formula, t(rep(NA, 26)), Error_Message )
      
    
    } else {
      
      # Extract Epochs per Sub and Cond
      Epochs = Subset[,c("ID", "Epochs", "Congruency_notCentered")] %>%
        group_by(ID, Congruency_notCentered) %>%
        summarise(Epochs = mean(Epochs, na.rm =TRUE))
      
      # Compare against Nullmodel
      ModelComp = anova(Model_Result, NullModel )
      ModelComp = c(ModelComp$`Pr(>Chisq)`[2] , ModelComp$AIC[1], ModelComp$AIC[2], ModelComp$BIC[1], ModelComp$BIC[2], ModelComp$deviance[1], ModelComp$deviance[2] )
      
      var_Nullmodell = as.data.frame(VarCorr(NullModel))
      ICC = var_Nullmodell $vcov[1] / (var_Nullmodell $vcov[1] + var_Nullmodell $vcov[2])
      
      
      # get Anova from model
      AnovaModel = anova(Model_Result)
      
      # Check Type of Model
      if(class(Model_Result) == "lm" ) {
        noRandomFactor = 1
        Singularity = NA
      } else {
        noRandomFactor = 0
        Singularity = isSingular(Model_Result)
      }
      

      Effect_of_Interest = unique(Effect_of_Interest)

      
      # Find index of effect of interest (and the indicated Conditions)
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
      if (lmFamily == "binominal") {
        partial_Eta = t(c(NA, NA, NA, NA))
        # Get p value
        p_Value = NA # why no p-value here?
      } else {
      partial_Eta = effectsize::eta_squared(Model_Result,  alternative = "two.sided") # partial = FALSE does only partial
      partial_Eta = partial_Eta[Idx_Effect_of_Interest,]
      if (is.null(partial_Eta$Eta2_partial)) { partial_Eta$Eta2_partial = partial_Eta$Eta2} # For one-way between subjects designs, partial eta squared is equivalent to eta squared.
      partial_Eta = cbind.data.frame( "partial_Eta", partial_Eta$Eta2_partial, partial_Eta$CI_low, partial_Eta$CI_high) 
      # Get p value
      p_Value = AnovaModel$`Pr(>F)`[Idx_Effect_of_Interest]
      }
      
      # Get standardized parameter
      std_param = tryCatch(
        {std_param = effectsize::standardize_parameters(Model_Result)
        std_param = std_param[Idx_Effect_of_Interest,]
        std_param = c( std_param$Std_Coefficient, std_param$CI_low, std_param$CI_high) 
        },
        
        error=function(cond) {
          std_param = c(NA, NA, NA)
          return(std_param)
        })
      
      
      
      
      # Get Name of Test
      StatTest = rownames(AnovaModel)[Idx_Effect_of_Interest]
      
      
      # semi-partial (marginal) R squared for fixed effects
      R2 = tryCatch(
        {R2 = r2glmm::r2beta(Model_Result, method = "nsj")
        PredicNames = R2$Effect
        # Get Regressors including all Elements
        PosIdx = which(rowSums(sapply(Effect_of_Interest, function(x) grepl(x, PredicNames))) == length(Effect_of_Interest))
        # Remove Regressors with more Elements
        PosIdx = PosIdx[which(sapply(PredicNames[PosIdx], function(x) {A = strsplit(x, ":"); length(unlist(A))}) == length(Effect_of_Interest))]
        # Get last index (assuming that pne is the highest level most different from reference level
        PosIdx = tail(PosIdx,1)
        R2 = R2[PosIdx,]
        R2 = unlist(R2)[6:8]
        },
        
        error=function(cond) {
          R2 = c(NA, NA, NA)
          return(R2)
        })
      
      
      # Get classic MLM infos (not Anova, but separate regressors)
      SumModel = summary(Model_Result)
      PredicNames = SumModel[["vcov"]]@Dimnames[[1]]
      # Get Regressors including all Elements
      PosIdx = which(rowSums(sapply(Effect_of_Interest, function(x) grepl(x, PredicNames))) == length(Effect_of_Interest))
      # Remove Regressors with more Elements
      PosIdx = PosIdx[which(sapply(PredicNames[PosIdx], function(x) {A = strsplit(x, ":"); length(unlist(A))}) == length(Effect_of_Interest))]
      # Get last index (assuming that pne is the highest level most different from reference level
      PosIdx = tail(PosIdx,1)
      SumModel = SumModel$coefficients[PosIdx,]
      if(length(SumModel)<5) {SumModel = c(SumModel[1:2], NA, SumModel[3:4])} # when binominal dfs are missing?
      PredicNames = PredicNames[PosIdx]
      
    
      ## for the whole model
      # r2_total <- MuMIn::r.squaredGLMM(Model_Result, pj2014 = T)
      
      # Get Results from Corinnas Function
      MLM_Result = mlm.table(Model_Result, Effect_of_Interest) 
      # ssa.table(Model_Result, Effect_of_Interest) does not work?

      
      # get subject nr
      if (noRandomFactor == 0) { 
        Nr_Subs = min(summary(Model_Result)$ngrps)
      } else {
        Nr_Subs = length(unique(Subset$ID))
      }
      
      # Get FStatistics
      if (lmFamily == "binominal") {
        FStatInfo = cbind(anova(Model_Result)[Idx_Effect_of_Interest,c("F value")], NA, NA) # What are the Degrees of Freedom?
      } else  {
      if (noRandomFactor == 0) { 
        FStatInfo = anova(Model_Result)[Idx_Effect_of_Interest,c("F value", "NumDF", "DenDF")]
      } else {
        ForAccessing = anova(Model_Result)
        FStatInfo = c(ForAccessing$"F value"[Idx_Effect_of_Interest], 
                      ForAccessing$Df[Idx_Effect_of_Interest],
                      last(ForAccessing$Df))
      } }
    
      
     # prepare export
      if (length(Idx_Effect_of_Interest)>0) {
      Estimates = cbind.data.frame(Name_Test, StatTest, partial_Eta, p_Value,  
                                   Nr_Subs, mean(Epochs$Epochs), sd(Epochs$Epochs), Singularity,
                                   lm_formula, FStatInfo,
                                   PredicNames, t(SumModel),
                                   t(std_param),
                                   t(MLM_Result),
                                   t(R2),
                                   formula_NULL,
                                   t(ModelComp),
                                   t(ICC),
                                   
                                   NA)
      } else {
      print("Effect not found in Model")
      Estimates = cbind.data.frame(Name_Test, "Effect not found in Model", t(rep(NA, 11)), lm_formula, t(rep(NA, 26)), "Effect Not Found in Model" )
      
                                   
        
      }
      
    } }
    colnames(Estimates) = c("Effect_of_Interest", "Statistical_Test", 
                            "EffectSizeType" ,  "value_EffectSize", "CI_low", "CI90_high", "p_anova",  
                            "n_participants", "av_epochs", "sd_epochs", "Singularity",
                            "formula", "F_value", "dfN", "dfD",
                            "RegressorName", 
                            "Estimate_summary", "Std.Error_summary", "df_summary", "t_z_summary", "p_summary",
                            "coefficient_std", "CI_low_std", "CI90_high_std",
                            "Beta", "SE", "p_MLM", "Rand_Eff_SD", 
                            "Rsq", "CI_low_Rsq", "CI_high_Rsq", 
                            "formula_0", "ModelComparison_p", "AIC_0", "AIC_A", "BIC_0", "BIC_A", "deviance_0", "deviance_A", "ICC", "ErrorMessage")
  
    return (Estimates)
  }

