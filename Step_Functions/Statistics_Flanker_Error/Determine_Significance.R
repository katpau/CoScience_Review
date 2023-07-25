Determine_Significance = function(input = NULL, choice = NULL) {
  StepName = "Determine_Significance"
  Choices = c("Holm", "Bonferroni", "None")
  Order = 13
  output = input$data
  
  
  
  # Get possible additional factors to be included in the GLM (depends on the forking
  # if e.g. no difference scores were calculated, then hemisphere should be added.
  # these have been determined at earlier step (Covariate) when determining the grouping variables)
  additional_Factors_Name = input$stephistory[["additional_Factors_Name"]]
  additional_Factor_Formula = input$stephistory[["additional_Factor_Formula"]]
  
  
  
  
  
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
    
    Covariate_Formula_min = ""
    Covariate_Name_min = vector()
    
    Covariate_Formula_av = ""
    Covariate_Name_av = vector()
    
  } else if (input$stephistory["Covariate"] == "Gender_MF") { 
    Covariate_Formula = "+ Covariate_Gender"
    Covariate_Name = "Covariate_Gender"
    
    Covariate_Formula_min = "+ Covariate_Gender_sortedMin"
    Covariate_Name_min = "Covariate_Gender_sortedMin"
    
    Covariate_Formula_av = "+ Covariate_Gender_sortedAV"
    Covariate_Name_av = "Covariate_Gender_sortedAV"
    
  } else if (input$stephistory["Covariate"] == "Age_MF") { 
    Covariate_Formula = "+ Covariate_Age"
    Covariate_Name = "Covariate_Age"
    
    Covariate_Formula_min = "+ Covariate_Age_sortedMin"
    Covariate_Name_min = "Covariate_Age_sortedMin"
    
    Covariate_Formula_av = "+ Covariate_Age_sortedAV"
    Covariate_Name_av = "Covariate_Age_sortedAV"
    
  } else { 
    Covariate_Name = names(output)[names(output) %like% "Covariate_"]
    Covariate_Name = Covariate_Name[!grepl("_sorted", Covariate_Name)]
    if (length(Covariate_Name)  > 1) {
      Covariate_Formula = paste("*(", paste(Covariate_Name, collapse = " + "), ")")
      Covariate_Formula_av = paste("*(", paste(paste0(Covariate_Name, "_sortedAV"), collapse = " + "), ")")
      Covariate_Formula_min = paste("*(", paste(paste0(Covariate_Name, "_sortedMin"), collapse = " + "), ")")
      Covariate_Name_av =  paste0(Covariate_Name, "_sortedAV")
      Covariate_Name_min = paste0(Covariate_Name, "_sortedMin")
      
    } else {
      Covariate_Formula = paste( "*", Covariate_Name)
      Covariate_Formula_av = paste( "*", paste0(Covariate_Name, "_sortedAV"))
      Covariate_Formula_min = paste( "*", paste0(Covariate_Name, "_sortedMin"))
      Covariate_Name_av =  paste0(Covariate_Name, "_sortedAV")
      Covariate_Name_min = paste0(Covariate_Name, "_sortedMin")
    }
  }
  
  
  ########################################################################################
  # Calculate Simple Model split for (1) Subset, (2), Present/Absent, (3) PSWQ Original/SortMin/SortAv
  Estimates = data.frame()
  for (iQuest in c("", "_sortedAV", "_sortedMin", "Perfectionism")) {
    
    if (iQuest == "") {
      use_Covariate_Formula = Covariate_Formula
      use_Covariate_Name = Covariate_Name
      use_Personality = "Personality_PSWQ_Concerns"
    } else if (iQuest == "_sortedMin") {
      use_Covariate_Formula = Covariate_Formula_min
      use_Covariate_Name = Covariate_Name_min
      use_Personality = "Personality_PSWQ_Concerns_sortedMin"
    } else if (iQuest == "_sortedAV"){
      use_Covariate_Formula = Covariate_Formula_av
      use_Covariate_Name = Covariate_Name_av
      use_Personality = "Personality_PSWQ_Concerns_sortedAV"
    } else if (iQuest == "Perfectionism") {
      use_Covariate_Formula = Covariate_Formula
      use_Covariate_Name = Covariate_Name
      use_Personality = "Personality_MPS_TotalPerfectionism"
    }
    
    lm_formula = paste("EEG_Signal ~ ", use_Personality, " * Condition", additional_Factor_Formula, use_Covariate_Formula)
    Effect_of_Interest = c("Condition", use_Personality)
    
    DirectionEffect = list("Effect" = "correlation",
                           "Personality" = use_Personality)
    
    for (iSubset in 1:2) {
      for (iCondition in c("Present", "Absent")) {
        
        Name_Test = paste(iCondition, paste0("PSWQ_",iQuest),  "inSubset", iSubset)
        
        
        
        Subset = output[grepl(iCondition, output$Condition) & output$Subset == iSubset, 
                        c("Condition", "EEG_Signal", use_Personality, use_Covariate_Name, additional_Factors_Name,
                          "ID", "Lab", "Epochs")]
        
        
        ModelResult = test_Hypothesis( Name_Test,lm_formula, Subset, Effect_of_Interest)
        Subset$Condition = as.character( Subset$Condition)
        Subset$Condition[grepl("Error", Subset$Condition)] = "Error"
        Subset$Condition[grepl("Correct", Subset$Condition)] = "Correct"
        
        Subset =  Subset %>%
          group_by(ID, Condition) %>%
          summarise (EEG_Signal = mean(EEG_Signal), na.rm = T,
                     Personality = get(use_Personality)[1]) %>%
          ungroup %>%
          spread(Condition, EEG_Signal) %>%
          mutate(Diff = Error - Correct,
                 Personality = Personality) 
          
        Subset = Subset[!is.na(Subset$Diff),]
        Korrelation = cor.test(Subset$Diff, Subset$Personality, method="pearson")
        
        
        ModelResult = rbind(ModelResult,
                            c(ModelResult[1,1], paste("Corr", ModelResult[1,2]), "r", Korrelation$estimate, 
                              Korrelation$conf.int[1],Korrelation$conf.int[2], Korrelation$p.value, nrow(Subset), ModelResult[1,9], ModelResult[1,10], "NA",  "NA", "NA", "NA", "NA"))
        
        
        if (as.numeric(ModelResult[2,4])<0) {
          ModelResult[1,4] = as.numeric(ModelResult[1,4])*-1
          Low =as.numeric( ModelResult[1,5])
          ModelResult[1,5] = as.numeric(ModelResult[1,6])*-1
          ModelResult[1,6] = Low*-1
        }
        
        
        Estimates = rbind(Estimates, ModelResult)
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

