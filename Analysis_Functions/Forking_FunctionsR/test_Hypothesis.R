test_Hypothesis = function (Name_Test,lm_formula, Subset, Effect_of_Interest, SaveUseModel, ModelProvided) {
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
  StopModel = 0
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # GetName of all relevant columns
  keptcolumns = colnames(Subset)
  # Drop Localisation and Electrode if both of them are given (only Relevant for Alpha Asymmetry)
  if (any(grepl("Localisation ", keptcolumns)) & any(grepl("Electrode", keptcolumns)) ) {
    keptcolumns = keptcolumns[!keptcolumns == "Localisation"]  }
  
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
  
  # CK: necessary data format is long, and trial-by-trial 
  # (for RT and accuracy it could be shorter, i.e. without repetition for electrodes)
  
  # ID  CEI trial demand  electrode RT  correct FMT N2  P3
  # 1   1   1     1       1         x1  x1 [0,1]x1  x1  x1
  # 1   1   1     1       2         x1  x1      x2  x2  x2
  # 1   1   1     1       ...       ... ...     ... ... ...  
  # 1   1   2     2       1         x2  x2      x1  x1  x1    
  # 1   1   2     2       2         x2  x2      x2  x2  x2
  # 1   1   2     2       ...       ... ...     ... ... ...
  # 1   1   ...   ...     ...       ... ...     ... ... ...
  # 2   2   1     1       1         x1  x1      x1  x1  x1
  # ... ... ...   ...     ...       ... ...     ... ... ...
  # n   x   n     4       x         x   x       x   x   x
  
  # *error trials are needed for accuracy analysis/ error rate
  # ID and electrode as factor
  # additionally block number and lab ID (as factor) in additional columns
  
  ## 1. change global coding in order to get meaningful results
  # to orthogonal sum-to-zero contrast 
  options(contrasts = c("contr.sum", "contr.poly"))
  
  ## 2. get subset for each criterion
  # TODO @ Kat adjust variable naming
  sub.rt <- droplevels(subset(df.rt[c("ID", "RT", "demand", "CEI", "COM", "ESC",
                                       fluidIntelligence, electrode)],  # include all necessary variables, like covariates *block, lab ID
                              subset = !is.na(RT)))    # remove missing data rows
  
    # TODO MINIMUM OF INCLUDED DATA: Condition values will be marked as outlier if 
    # after artefact correction, subjects have less than
    # (1) 20 trials (per condition).
  
  ## 3. center predictors
  # level 1 predictors: centering within cluster (CWC) = group mean centering
  # demand
  sub.rt$demand.cwc <- sub.rt$demand - ave(sub.rt$demand, sub.rt$ID, 
                                           FUN = function(x) mean(x, na.rm = T))
  # same for electrode * if as factor, centering might not be needed
  sub.rt$electrode.cwc <- sub.rt$electrode - ave(sub.rt$electrode, sub.rt$ID,
                                                 FUN = function(x) mean(x, na.rm = T))
  # block
  sub.rt$block.cwc <- sub.rt$block - ave(sub.rt$block, sub.rt$ID, 
                                         FUN = function(x) mean(x, na.rm = T))
  
  
  # level 2 predictor: centering at the grand mean (CGM) 
  # CEI, COM, ESC
  sub.rt$CEI.cgm <- scale(sub.rt$CEI, scale = F)
  sub.rt$COM.cgm <- scale(sub.rt$COM, scale = F)
  sub.rt$ESC.cgm <- scale(sub.rt$ESC, scale = F)
  # fluid Intelligence
  sub.rt$fluidI.cgm <- scale(sub.rt$FluidI, scale = F)
  
  ## 4. calculate models
  # use lmerTest 
  library(lmerTest)         # version  3.1.3            for LMM

  ## 5. add covariates as follows
  # gender (as factor or even better centered)
    sub.rt$gender.cgm <- scale(sub.rt$gender, scale = F)
    # add as main effect only     + gender.cgm
    # add total effect            * gender.cgm
  # age 
    sub.rt$age.cgm <- scale(sub.rt$age, scale = F)
    # add as main effect only     + age.cgm
    # add total effect            * age.cgm
  # depression, anxiety, O, C, A, E, N
    sub.rt$X.cgm <- scale(sub.rt$X, scale = F)
    # add as main effect only     + X.cgm
    # add total effect            * X.cgm
  
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Prepare and Calculate LMer Model
  if (!SaveUseModel == "previousModel"){ 
    # check if data has been processed, otherwise don't proceed
    if (length(unique(Subset$ID))<5) { # Change for final analysis
      Model_Result = "Error_data_seems_incomplete"
      
    } else {
      
      print("Calculating LMER")
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
        lm_formula_noAdd_Random = lm_formula
        
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
          for  (iPredictor in AddPredictors) {
            lm_formula = paste0(lm_formula, "+ (1|", iPredictor, ":ID)")
          }
      } 
      
      #####################################################################################
      # Calculate LM Model
      if (noRandomFactor == 1) {
        Model_Result = tryCatch({
          Model_Result = lm(as.formula(lm_formula), 
                            Subset)
          Model_Result = 3
          
        }, error = function(e) {
          print("Error with Model")
          Model_Result = "Error_when_computing_Model"
          return(Model_Result)
        })
        
        
      } else {
        Model_Result = tryCatch({
          Model_Result = lmer(as.formula(lm_formula), 
                              Subset) 
          Model_Result
        }, error = function(e) {
          print("Error in Model")
          Model_Result = "Error_when_computing_Model"
          return(Model_Result)
        })
      
        if (is.character(Model_Result) &&  grepl( "Error", Model_Result)) {
          # Try again with less random predictors
          Model_Result = tryCatch({
            Model_Result = lmer(as.formula(lm_formula_noAdd_Random), 
                                Subset) 
            print("Error in Model fixed by dropping random predictors")
            Model_Result
          }, error = function(e) {
            print("Error in Model even after dropping random predictors")
            Model_Result = "Error_when_computing_Model"
            return(Model_Result)
          })
          
          
        }
        
        
        }
      
      # If Model is provided, get it here
    }} else {  
      print("Using existing LMER")
      Model_Result = ModelProvided }
  
  #----
  # CK: there are several outcomes when estimating the models
  # if there is a warning message - it can mostly be ignored (after checking covariance matrix: summary(model)$varcor)
  # the optimization algorithm can be adjusted in order to prevent fitting error / singular fit or any other difficulty
  m1 <- lmer(criterion ~ demand.cwc * CEI.cgm + electrode 
             + (demand.cwc | ID), data = sub.df,
             control = lmerControl(optimizer = "bobyqa")) # in most cases this optimizer works
  # there is also a time consuming method to try all optimizers 
  
  
  
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
    if (is.character(Model_Result) &&  grepl( "Error", Model_Result)) {
      print("no Estimates since Error with Model ")
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
      if ("Hemisphere" %in% keptcolumns) {
        Effect_of_Interest = c(Effect_of_Interest, "Hemisphere")  }
      if ("Localisation" %in% keptcolumns) {
        Effect_of_Interest = c(Effect_of_Interest, "Localisation")  }
      # Add Electrode to effect of interest only if frontal/paripartial_Etal
      if ("Electrode" %in% keptcolumns) {
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
      
      #-----
      # CK: 
      # TODO @ Kat adjust variable names
      ## for the whole model
      rt.r2_total <- r.squaredGLMM(m1.rt.final, pj2014 = T)
      #            R2m       R2c
      # [1,] 0.1526714 0.3793343


      # semi-partial (marginal) R squared for fixed effects
      rt.r2_fixef <- r2beta(m1.rt.final, method = "nsj")
      #----
      

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
      # CK: the direction is expressed in the positive or negative value of the estimate
      # however, if interactions are significant, we might want to explore this interaction effect
      # that would be possible with a simple slope analysis
      # plot interactions
      library(interactions)
      # produce a plot
      rt_ia.plot <- interact_plot(model, pred = demand.cwc, modx = CEI.cgm, centered = "none", 
                                  x.label = "Demand", y.label = "Reaction Time in ms",
                                  legend.main = "Cognitive \nEffort \nInvestment",
                                  interval = F,
                                  colors = c("black", "black", "black", "black")) + ylim(335, 650) + theme_apa(legend.use.title = T) 
      
      # perform simple slopes analysis
      rt.ss.d <- sim_slopes(model, pred = demand.cwc, modx = CEI.cgm, centered = "none",
                            cond.int = T,                   # print conditional intercepts
                            johnson_neyman = T,             # calculate Johnson Neyman intervals,
                            jnplot = T, control.fdr = T,    # create plot, adjust false discovery rate
                            confint = T)                    # get confidence intervals
      
      
      # is there a way to extract estimates when more than 2 levels?
      # effectsize::standardize_parameters(Model_Result)
    } 
    colnames(Estimates) = c("Effect_of_Interest", "Statistical_Test", "EffectSizeType" ,"value_EffectSize", "CI_low", "CI90_high", "p_Value",  "n_participants", "av_epochs", "sd_epochs", "Singularity")
    
  
    return (Estimates)
  }
}


### CK: added functions for reporting LMM and SSA results as table

# function for creating a table displaying MLM results of the random slopes model
mlm.table <- function(x, type = c("mlm", "glmm"), demand.only = F, model.no = c(1,2,3)) {
  # get random and fixed effects
  ranef <- as.data.frame(summary(x)$varcor)
  fixef <- summary(x)$coefficients
  
  # prepare table
    if(model.no == 1) {
      rtable <- as.data.frame(cbind(c("Intercept", "demand", "CEI", "CEI:demand"),
                                    fixef[-c(4:5),c(1, 2, 5)]))
    }
    else if (model.no == 2) {
      rtable <- as.data.frame(cbind(c("Intercept", "demand", "COM", "COM:demand"),
                                    fixef[-c(4:5),c(1, 2, 5)])) 
    }
    else if (model.no == 3) {
      rtable <- as.data.frame(cbind(c("Intercept", "demand", "ESC", "ESC:demand"),
                                    fixef[-c(4:5),c(1, 2, 5)]))
    }
    
    rtable$ranef.sd <- NA
    rtable$ranef.sd[1:2] <- ranef$sdcor[1:2]
    rtable$ranef.sd[which(is.na(rtable$ranef.sd))] <- ""
  
  rtable[2:5] <- lapply(rtable[2:5], as.numeric)
  rtable[c(2,3,5)] <- round(rtable[c(2,3,5)], digits = 2)
  rtable[4] <- round(rtable[4], digits = 3)
  
  rtable[,4][which(rtable[,4] <.01)] <- paste0(rtable[,4][which(rtable[,4]<.01)],"*")
  rtable[,4][which(rtable[,4]<.05)] <- paste0(rtable[,4][which(rtable[,4]<.05)],"*")
  rtable[,4][which(rtable[,4]<.001)] <- paste0("<.001***")
  
  rtable$ranef.sd[which(is.na(rtable$ranef.sd))] <- ""
  colnames(rtable) <- c("Parameter", "Beta", "SE", "p-value", "Random Effects (SD)")
  row.names(rtable) <- NULL
  rtable[2:3] <- lapply(rtable[2:3], as.character)
  
  return(list(rtable = rtable))
}



# function for creating a table displaying simple slopes analysis results (CEI only)
ssa.table <- function(x, predictor) {
  rtable <- data.frame("V1" = c("- 1 SD", "Mean", "+ 1 SD"),
                       round(x$slopes[2:6], digits = 2), x$slopes[7], round(x$ints[2:3], digits = 2))
  rtable$sig <- NA
  rtable$sig[which(rtable$p <.01)] <- "*"
  rtable$sig[which(rtable$p <.05)] <- "**"
  rtable$sig[which(rtable$p <.001)] <- "***"
  rtable$sig[which(is.na(rtable$sig))] <- ""
  
  rtable$slope <- paste0(rtable$Est., " (", rtable$S.E., ")", rtable$sig)
  rtable$CI <- paste0("[", rtable$X2.5., ", ", rtable$X97.5., "]")
  rtable$int <- paste0(rtable$Est..1, " (", rtable$S.E..1, ")")
  
  if (predictor == "payoff") {
    rtable <- rbind(c("Value of CEI", "Slope of Payoff", "", "Conditional Intercept"),
                    c("", "Beta (SE)", "95% CI", "Beta (SE)"), 
                    rtable[,c(1, 11:13)])
    rtable <- cbind("V0" = c("", "","", "Payoff", ""), rtable)
    
  } else if (predictor == "demand") {
    rtable <- rbind(c("Value of CEI", "Slope of Demand", "", "Conditional Intercept"),
                    c("", "Beta (SE)", "95% CI", "Beta (SE)"), 
                    rtable[,c(1, 11:13)])
    rtable <- cbind("V0" = c("", "","", "Demand", ""), rtable)
  }
  colnames(rtable) <- c("V0", "V1", "V2", "V3", "V4")
  
  return(rtable = rtable)
}
