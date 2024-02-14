RT = function(input = NULL, choice = NULL) {
  StepName = "RT"
  Choices = c("AV", "trimmedAV", "Median")
  Order = 9.2
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:

  # Handles how RTs are defined
  # Handles all Choices listed above as well as choices from previous Step (StateAnxiety)
  # (1) Get Choices abotu which Trials to be included, from previous Steps and load Data
  # (2) Drop Trials based on selection criteria
  # (3) Calculate RT based on choice
  # (4) Merge for Export
  
  
  #########################################################
  # (1) Preparations 
  #########################################################
  # Collect all Choices
  Select_Trials_RT = unlist(input$stephistory["SelectTrialsRT"])
  
  
  # Read Behavioural Data
  BehavFile = paste0(input$stephistory["Root_Behavior"], "task_GoNoGo_beh.csv")
  BehavData = read.csv(BehavFile, header = TRUE)
  # Rename
  colnames(BehavData)[colnames(BehavData) == "InstructionCondition"] = "Condition_Instruction"
  
  #########################################################
  # (2) Drop Trials 
  #########################################################
  # only correct Trials
  BehavData = BehavData[BehavData$Accuracy %in% 1,]
  BehavData = BehavData[!is.na(BehavData$RT),]
  # only Trials with Response
  if (Select_Trials_RT == "RT_ACC") {
    BehavData = BehavData[BehavData$RT <= 0.8,] 
    BehavData = BehavData[BehavData$RT >= 0.1,] 
  }
  
  #########################################################
  # (3) Calculate RT
  #########################################################
  
  if (choice == "AV") {
  RT_Data = BehavData %>%
    group_by(ID, Condition_Instruction) %>%
    summarise(Behav_RT = mean(RT),
              OrderInstr = Order_Instruction[1]) 
  
  } else if (choice == "trimmedAV") {
    RT_Data = BehavData %>%
      group_by(ID, Condition_Instruction) %>%
      summarise(Behav_RT = mean(RT, trim = 0.05),# lowest and highest 5 %
                OrderInstr = Order_Instruction[1]) 
    
  } else if (choice == "Median") {
    RT_Data = BehavData %>%
      group_by(ID, Condition_Instruction) %>%
      summarise(Behav_RT = median(RT),
                OrderInstr = Order_Instruction[1]) 
  }
  
  #########################################################
  # (4) Export [Add as new Rows]
  #########################################################
  
  RT_Data$Component = "RT"
  RT_Data$Condition_Type = "Go"
  
  Data_to_ADD = output[,c("ID", "Condition_Instruction", "Lab", "Experimenter", "ACC", colnames(output)[grepl("Covariate_|Personality_", colnames(output))])]
  RT_Data = merge(
    RT_Data, 
    Data_to_ADD[!duplicated(Data_to_ADD),],
    by =  c("ID", "Condition_Instruction"),
    all.x = FALSE,
    all.y = FALSE
  )
  
  # Merge with data
  output = bind_rows(output, RT_Data)
  

  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
