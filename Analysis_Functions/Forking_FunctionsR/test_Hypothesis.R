test_Hypothesis = function (Name_Test,lm_formula, Subset, Effect_of_Interest, SaveUseModel, ModelProvided) {
  # this function is used to export the relevant estimates from the tested model or the model (determined by SaveUseModel)
  # Name_Test is the Name that will be added as first collumn, to identify tests across forks, str (next to the actual interaction term)
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
  StopModel = 0
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # GetName of all relevant collumns
  keptcollumns = colnames(Subset)
  # Drop Localisation and Electrode if both of them are given (only Relevant for Alpha Asymmetry)
  if (any(grepl("Localisation ", keptcollumns)) & any(grepl("Electrode", keptcollumns)) ) {
    keptcollumns = keptcollumns[!keptcollumns == "Localisation"]  }
  
  # Select relevant data and make sure its complete
  colNames_all = names(Subset)
  # Get DV
  DV = gsub(" ", "", str_split(lm_formula, "~")[[1]][1])
  # Second select columns based
  relevant_collumns = c(DV, colNames_all[grepl("Personality_", colNames_all)],  colNames_all[grepl("Covariate_", colNames_all)])
  # Third make sure cases are complete
  Subset = Subset[complete.cases(Subset[,colnames(Subset) %in% relevant_collumns]), ]
  
  classes_df = lapply(Subset[names(Subset)], class)
  make_Factor = names(classes_df[classes_df == "character"])
  Subset[make_Factor] = lapply(Subset[make_Factor], as.factor)
  
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Prepare and Calculate LMer Model
  if (!SaveUseModel == "previousModel"){ 
    # check if data has been processed, otherwise don't proceed
    if (length(unique(Subset$ID))<5) { # Change for final analysis
      Model_Result = "Error_data_seems_incomplete"
      
    } else {
      
      print("Calculating LMER")
      #?? Update Formula if levels singular?
      for (iCol in keptcollumns) {
        if(length(unique(as.character((as.data.frame(Subset)[,iCol]))))<2) {
          if (grepl(iCol, lm_formula)) {
            print("Dropped Factor")
            print(iCol)
            lm_formula = gsub(paste0("\\* ", iCol), "", lm_formula)
          }}
      }
      
      
      #####################################################################################
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
      
      # check how many levels per sub
      EntriesPerSub = Subset %>% count(ID) %>% summarise(MaxperSub = max(n)) %>% unlist
      if ((EntriesPerSub)>1) {
        noRandomFactor = 0
        lm_formula = paste(lm_formula, "+ (1|ID)")  
        
        # check how many levels per predictor 
        if (length(Predictors)>1) {
          Levels = sapply(Subset[,Predictors], function(x) length(unique(x))) # nlevels counts also dropped levels
        } else {
          Levels = length(unique(Subset[,Predictors]))
        }
        AddPredictors = Predictors[Levels>1 &  Levels < EntriesPerSub ]
        
      } else {
        noRandomFactor = 1
      }
     
      
      if (length(AddPredictors)>0) { 
        noRandomFactor = 0
        lm_formula = paste(lm_formula, "+ (1|ID)")  
          for  (iPredictor in AddPredictors) {
            lm_formula = paste0(lm_formula, "+ (1|", iPredictor, ":ID)")
          }
      } 
      
      #####################################################################################
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
    }} else {  
      print("Using existing LMER")
      Model_Result = ModelProvided }
  
  
  
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
      Estimates = cbind.data.frame(Name_Test, Model_Result, NA, NA, NA, NA, NA, length(unique(as.character(Subset$ID))),NA, NA, NA)
      
    } else {
      # get Anova from model
      AnovaModel = anova(Model_Result)
      
      # Check Type of Model
      if(class(Model_Result) == "lm") {
        noRandomFactor = 1
        Singularity = NA
      } else {
        noRandomFactor = 0
        Singularity = isSingular(Model_Result)
      }
      

      
      
      
      # Expand Effect of Interest by additional factors
      if ("Hemisphere" %in% keptcollumns) {
        Effect_of_Interest = c(Effect_of_Interest, "Hemisphere")  }
      if ("Localisation" %in% keptcollumns) {
        Effect_of_Interest = c(Effect_of_Interest, "Localisation")  }
      # Add Electrode to effect of interest only if frontal/paripartial_Etal
      if ("Electrode" %in% keptcollumns) {
        if (length(unlist(unique(Subset$Electrode))) == 6) {
          Effect_of_Interest = c(Effect_of_Interest, "Electrode")  }}
      
      Effect_of_Interest = unique(Effect_of_Interest)
      # Do not add other factors (Frequency Band)
      # These are different hypotheses. We are only focused 
      # on frontal alpha asymmetry.)
      
      
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
      partial_Eta = effectsize::eta_squared(Model_Result,  alternative = "two.sided") # partial = FALSE does only partial
      partial_Eta = partial_Eta[Idx_Effect_of_Interest,]
      if (is.null(partial_Eta$Eta2_partial)) { partial_Eta$Eta2_partial = partial_Eta$Eta2} # For one-way between subjects designs, partial eta squared is equivalent to eta squared.
      partial_Eta = cbind( partial_Eta$Eta2_partial, partial_Eta$CI_low, partial_Eta$CI_high)
      # Get p value
      p_Value = AnovaModel$`Pr(>F)`[Idx_Effect_of_Interest]
      
      # Get Name of Test
      StatTest = rownames(AnovaModel)[Idx_Effect_of_Interest]
      
      
      # Get Standardized effects
      #effectsize::standardize_parameters(Model_Result)
      

      # get subject nr
      if (noRandomFactor == 0) { 
        Nr_Subs = min(summary(Model_Result)$ngrps)
      } else {
        Nr_Subs = length(unique(Subset$ID))
        }
      
     # prepare export
      if (length(Idx_Effect_of_Interest)>0) {
      Estimates = cbind.data.frame(Name_Test, StatTest, "partial_Eta", partial_Eta, p_Value,  Nr_Subs, mean(Subset$Epochs), sd(Subset$Epochs), Singularity)
      } else {
      print("Effect not found in Model")
      Estimates = cbind.data.frame(Name_Test, NA, "partial_Eta", NA, NA, NA, NA,  NA, NA, NA, NA)
        
      }
      
      
      # is there a way to test the direction simply?
      # is there a way to extract estimates when more than 2 levels?
      # effectsize::standardize_parameters(Model_Result)
    } 
    colnames(Estimates) = c("Effect_of_Interest", "Statistical_Test", "EffectSizeType" ,"value_EffectSize", "CI_low", "CI90_high", "p_Value",  "n_participants", "av_epochs", "sd_epochs", "Singularity")
    
  
    return (Estimates)
  }
}


