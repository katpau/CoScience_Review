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
  
  # Load Relevant Libraries
list.of.packages <- c("scales")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,  repos='http://cran.us.r-project.org')
suppress = lapply(list.of.packages, require, character.only = TRUE)

   
  
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
    Covariate_Name = paste0("Covariate_", input$stephistory["Covariate"])
    Covariate_Formula = paste( "*", Covariate_Name)
  }
  
  
  ########################################################################################
  # Calculate Simple Model split for (1) Subset, (2), Present/Absent, (3) PSWQ Original/SortMin/SortAv
  Estimates = data.frame()
  AllQuestLevels = c("_Orig",
                     paste0("_sortedMin", seq(10, 70, 5)),
                     paste0("_sortedAV", seq(10, 70, 5)),
                     paste0("_sortedAVnoCSD", seq(10, 70, 5)))
  
  AllQuestLevels = c(paste0("_sortedAV", c(10, 20, 70)),
                     paste0("_sortedAVnoCSD", c(10, 20, 70)))
  
  
  for (iQuest in AllQuestLevels) {
    use_Personality = paste0("Personality_PSWQ_Concerns", iQuest)
    if (input$stephistory["Covariate"] == "None") { 
      use_Covariate_Formula =""
      use_Covariate_Name =vector()
    } else {
      use_Covariate_Name = paste0(Covariate_Name, iQuest)
      use_Covariate_Formula = paste0(Covariate_Formula, iQuest)
      
    }
    

    
    lm_formula = paste("EEG_Signal ~ ", use_Personality, " * Condition", additional_Factor_Formula, use_Covariate_Formula)
    Effect_of_Interest = c("Condition", use_Personality)
    
    DirectionEffect = list("Effect" = "correlation",
                           "Personality" = use_Personality)
    
    #for (iSubset in 1:2) {
      iSubset = 1 
     # for (iCondition in c("Present", "Absent")) {
        iCondition = "Absent" 
        
        Name_Test = paste(iQuest, "_PSWQ_", iCondition, "inSubset", iSubset)
        
        
        
        Subset = output[grepl(iCondition, output$Condition) & output$Subset == iSubset, 
                        c("Condition", "EEG_Signal", use_Personality, use_Covariate_Name, additional_Factors_Name,
                          "ID", "Lab", "Epochs")]
        
    
        ModelResult = test_Hypothesis( Name_Test,lm_formula, Subset, Effect_of_Interest)
        Subset$Condition = as.character( Subset$Condition)
        Subset$Condition[grepl("Error", Subset$Condition)] = "Error"
        Subset$Condition[grepl("Correct", Subset$Condition)] = "Correct"
        
        Subset = Subset[!is.na(Subset$Condition),]
        Subset = Subset[!is.na(Subset$EEG_Signal),]
        
        Subset =  Subset %>%
          group_by(ID, Condition) %>%
          select(-Lab, Epochs) %>%
          summarise (EEG_Signal = mean(EEG_Signal),
                     Personality = get(use_Personality)[1]) %>%
          select(ID, Condition, EEG_Signal, Personality) %>%
          ungroup %>%
          spread(Condition, EEG_Signal) %>%
          mutate(Diff = Error - Correct,
                 Personality = Personality) %>%
   	      mutate(Diff = rescale(scale(Diff)))
          

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

