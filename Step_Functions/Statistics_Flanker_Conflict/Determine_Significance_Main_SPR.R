output = read.csv("C:/Users/Paul/Documents/Work/PersonalityEEG/Manuscripts/Flanker_Conflict/Data_before_Stats.txt")
source("C:/Users/Paul/Documents/Work/PersonalityEEG/FINAL_RDF/HUMMEL/home/ForCompiling/Analysis_Functions/Forking_FunctionsR/test_Hypothesis_CK_formula.R", echo=TRUE)

ExportPath = '/work/bay2875/Flanker_Conflict/Stat_Results/'
  Covariate_Formula = ""
  Covariate_Name = vector()
  additional_Factors_Name = "Electrode"
  additional_Factor_Formula = "+ Electrode"
  
  
  
  #########################################################
  # (2) Initiate Functions for Hypothesis Testing      ####
  #########################################################
  wrap_test_Hypothesis = function (Name_Test,lm_formula,  Data, Effect_of_Interest, DirectionEffect,
                                   columns_to_keep, Component, SaveUseModel, ModelProvided, lmFamily , Nullmodel) {
    
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
    if(missing(Nullmodel)) {Nullmodel = "standard"}
    
    
    # Create Subset
    Subset = as.data.frame(Data[Data$Component %in% Component, names(Data) %in% c("ID", "Lab", "Epochs", 
                                                                                  columns_to_keep)])
    
    # Run Test
    ModelResult = test_Hypothesis_CK_formula( Name_Test,lm_formula, Subset, columns_to_keep, Effect_of_Interest, SaveUseModel, ModelProvided, lmFamily, Nullmodel)
    
    # Test Direction ??? 
    if (!SaveUseModel == "exportModel") {
      if(!is.character(ModelResult)  &&  any(!grepl( "Error", ModelResult))  && all((!is.na(DirectionEffect)))) {
        if(!is.na(ModelResult$value_EffectSize)){
          ModelResult = test_DirectionEffect(DirectionEffect, Subset, ModelResult) 
        }}}
    
    return(ModelResult)
  }
  
  
  
  
  itest = 0
  
    for (DV in c("RT", "ACC", "N2", "P3", "FMT")) {
      for (Personality in c("Personality_CEI", "Personality_COM", "Personality_ESC")) {
        for (control_IST in c("", "_withIST")) {
          for (control_Block in c("", "_withBlock")) {
      for (control_Lab in c("", "_withLabRand")) {
        for (test_Lab in c("", "_withLabFix")) {
          Estimates = data.frame()
   

              tryCatch({
                
                if(control_IST=="_withIST" && !Personality == "Personality_CEI") next
                
              
                if(test_Lab == "_withLabFix" && !control_Lab == "") next
                if(test_Lab == "_withLabFix" && !Personality == "Personality_CEI") next
                if(control_Lab == "_withLabRand" && !Personality == "Personality_CEI") next
                
                if(test_Lab == "_withLabFix" && control_Block == "_withBlock") next
                if(control_Lab == "_withLabRand" && control_Block == "_withBlock") next
                
                if(control_IST=="_withIST"  && test_Lab == "_withLabFix") next
                if(control_IST=="_withIST"  && control_Lab == "_withLabRand") next
                
     
                itest = itest +1 
                print(paste("Test Effect of ", Personality, "on", DV, control_IST, control_Block, test_Lab, control_Lab))
                
                
                
                
                columns_to_keep = c("Congruency", Personality, Covariate_Name, "Congruency_notCentered")
                Nullmodel = ""
                
                if (DV %in% c("N2", "P3", "FMT")) {
                  DV_formula = "EEG_Signal"
                  Component = DV
                  lm_formula =  paste( "EEG_Signal ~  Congruency * ", Personality,  Covariate_Formula,
                                       additional_Factor_Formula)
                  columns_to_keep = c(columns_to_keep, additional_Factors_Name, DV_formula)
                  lmFamily = "standard"
                  
                } else {
                  DV_formula = DV
                  Component = "Behav"
                  columns_to_keep = c(columns_to_keep,  DV_formula)
                  lm_formula =  paste( DV_formula, " ~ Congruency * ", Personality,  Covariate_Formula)
                  if (DV == "ACC") { lmFamily  = "binominal"} else {lmFamily = "standard" }
                }
                
                
                
                
                if (control_IST == "_withIST") {
                  lm_formula =   paste( lm_formula, " + IST  ")
                  columns_to_keep = c(columns_to_keep, "IST")      
                  Nullmodel = "\\+ IST"
                  
                }
                
                if (control_Block == "_withBlock") {
                  columns_to_keep = c(columns_to_keep, "Block" )
                  lm_formula = paste(lm_formula, "+ Block")
                  Nullmodel = paste0(Nullmodel,"|\\+ Block")
                }
                
                if (test_Lab == "_withLabFix") {
                  columns_to_keep = c(columns_to_keep, "Block", "Lab")
                  Nullmodel = paste0(lm_formula)
                  lm_formula = paste(lm_formula, "+ Lab")
                   }
                
                
                if (control_Lab == "_withLabRand") {
                  columns_to_keep = c(columns_to_keep, "Lab")                 
                  Nullmodel = lm_formula # without lab
                  lm_formula = paste(lm_formula,"+ (Congruency|Lab / ID)" )
                  
                } else {
                  lm_formula = paste(lm_formula,"+ (Congruency|ID)" )
                  Nullmodel = gsub(paste("\\* ", Personality), "", lm_formula ) # without Personality
                  
                }
                
                
                Effect_of_Interest = c(Personality)
                Effect_of_Interest_IA = c(Personality, "Congruency")
                DirectionEffect = list("Effect" = "correlation",
                                       "Personality" = Personality,
                                       "DV" = DV_formula)
                DirectionEffect_IA = list("Effect" = "interaction_correlation",
                                          "Larger" = c("Congruency_notCentered", "0"),
                                          "Smaller" = c("Congruency_notCentered", "1"),
                                          "Personality" = Personality,
                                          "DV" = DV_formula)
                
                
                
                
                print(lm_formula)
                H_1_Model = wrap_test_Hypothesis("",lm_formula, output,
                                                 "",  "",
                                                 columns_to_keep, Component,
                                                 "exportModel", "", lmFamily, Nullmodel )


                # Test main Effect of CEI
                Name_Test = paste0(DV,gsub("Personality", "", Personality), control_IST, control_Block, test_Lab, control_Lab)
                Estimates = rbind(Estimates, wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest,
                                                                  DirectionEffect, columns_to_keep, Component,
                                                                  "previousModel", H_1_Model, lmFamily, Nullmodel))

                # Test IA with Personality and Demand Level
                Name_Test = paste0(DV, gsub("Personality", "", Personality),"_Congruency", control_IST, control_Block, test_Lab, control_Lab)
                Estimates = rbind(Estimates,wrap_test_Hypothesis(Name_Test,lm_formula, output, Effect_of_Interest_IA,
                                                                 DirectionEffect_IA, columns_to_keep, Component,
                                                                 "previousModel", H_1_Model, lmFamily, Nullmodel)  )


                if (test_Lab == "_withLabFix") {
              

                  Name_Test = paste0(DV, "_Lab", control_IST, control_Block, gsub("Personality", "", Personality))
                  Estimates = rbind(Estimates,wrap_test_Hypothesis(Name_Test,lm_formula, output, "Lab",
                                                                   NA, columns_to_keep, Component,
                                                                   "previousModel", H_1_Model, lmFamily, Nullmodel)  )

                  #Name_Test = paste0(DV, "_Lab_Congruency", control_IST, control_Block, gsub("Personality", "", Personality))
                  #Estimates = rbind(Estimates,wrap_test_Hypothesis(Name_Test,lm_formula, output, c("Lab", "Congruency"),
                  #                                                 NA, columns_to_keep, Component,
                  #                                                 "previousModel", H_1_Model, lmFamily, Nullmodel)  )




                  }
                FileName= paste0(ExportPath, 'Main_AllTests_Final_', itest, '.csv')
                write.csv(Estimates,FileName, row.names = FALSE)
                })
              }}
        }}
      
      
    }}
  
  
  
  #########################################################
  # (4) Correct for Multiple Comparisons for Hypothesis 1 - 3
  #########################################################
  
  
  if (!choice == "None") {
    for( Subtests in c("RT|ACC", "FMT|N2|P3")) {
      nrTests = length(str_split_1(Subtests,  "\\|"))
      for (Test_of_interest in c("_CEI", "_Congruency", "CEI_Congruency")) {
        
        for (control_Lab in c("", "_withLabRand")) {
          for (test_Lab in c("", "_withLabFix")) {
            for (control_Block in c("", "_withBlock")) {
              for (control_IST in c("", "_withIST")) {
                
                Idx =  grepl(Subtests, Estimates$Effect_of_Interest) &
                  endsWith(Estimates$Effect_of_Interest, paste0(Test_of_interest, control_IST, control_Block, test_Lab,control_Lab ))
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
      }
    }
  }
  FileName= paste0(ExportPath, 'Main_AllTests_Final_pCorrected.csv')
  write.csv(Estimates,FileName, row.names = FALSE)
  
  
  ############################
  # (5) Hypthesis 4: Correlations
  ############################
  Personality = "Personality_CEI"
  Subset = output[,c("ID", "Personality_LE_Positiv", "Personality_NFC_NeedForCognition",  Personality)]
  Subset = Subset[!duplicated(Subset),]
  Subset = Subset[,-1]
  
  Cors  = psych::corr.test(Subset)
  p_s = Cors$ci$p[1:2]
  
  
  if (!choice == "None") {
    p_s = p.adjust(p_s,
                   method = tolower(choice), n = 2)
  }
  
  
  Cors_Estimates = cbind(
    c("Correlation_LE_NFC",
      "Correlation_LE_CEI")  ,
    "pearsonR", "r",
    Cors$ci$r[1:2], Cors$ci$lower[1:2], Cors$ci$upper[1:2], p_s,
    nrow(Subset),
    matrix(data=NA,nrow=2,ncol=30))
  colnames(Cors_Estimates) = colnames(Estimates)
  Estimates = rbind(Estimates,Cors_Estimates)
  
  
  
  #########################################################
  # (6) Export as CSV file
  #########################################################
  FileName= paste0(ExportPath, 'Main_AllTests_Final_complete.csv')
  write.csv(Estimates,FileName, row.names = FALSE)
  
  
  
  #No change needed below here - just for bookkeeping
#  stephistory = input$stephistory
#  stephistory[StepName] = choice
#  return(list(
#    data = Estimates,
#    stephistory = stephistory
#  ))
#}
