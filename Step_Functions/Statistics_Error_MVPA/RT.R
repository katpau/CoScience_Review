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
  Select_Trials_RT = unlist(input$stephistory["Select_Trials_RT"])
  
  
  # Read Behavioural Data Flanker
  BehavFile = paste0(input$stephistory["Root_Behavior"], "task_Flanker_beh.csv")
  BehavData = read.csv(BehavFile, header = TRUE)
  BehavData = BehavData[BehavData$ExperimenterPresence %in% "absent",]
  BehavData = BehavData[,c("ID","Accuracy", "RT")]
  BehavData$Task = "Flanker"
  
  # Read Behavioural Data GoNoGo
  BehavFile = paste0(input$stephistory["Root_Behavior"], "task_GoNoGo_beh.csv")
  BehavData2 = read.csv(BehavFile, header = TRUE)
  BehavData2 = BehavData[BehavData2$InstructionCondition %in% "Speed",]
  BehavData2 = BehavData2[,c("ID",  "Accuracy", "RT")]
  BehavData2$Task = "GoNoGo"
  
  BehavData = rbind(BehavData, BehavData2)
  BehavData = BehavData[!is.na(BehavData$RT),]
  
  #########################################################
  # (2) Drop Trials 
  #########################################################
  # only Trials with Response
  if (Select_Trials_RT == "RTs") {
    BehavData = BehavData[BehavData$RT <= 0.8,] 
    BehavData = BehavData[BehavData$RT >= 0.1,] 
  }
  
  #########################################################
  # (3) Calculate RT
  #########################################################
  
  if (choice == "AV") {
  RT_Data = BehavData %>%
    group_by(ID, Task, Accuracy) %>%
    summarise(Behav_RT = mean(RT)) 
  
  } else if (choice == "trimmedAV") {
    RT_Data = BehavData %>%
      group_by(ID, Task, Accuracy) %>%
      summarise(Behav_RT = mean(RT, trim = 0.05))# lowest and highest 5 %
                
    
  } else if (choice == "Median") {
    RT_Data = BehavData %>%
      group_by(ID, Task, Accuracy) %>%
      summarise(Behav_RT = median(RT))
                
  }
  
  RT_Data$Component = "RTs"
  RT_Data$Condition = NA
  RT_Data$Condition[RT_Data$Accuracy == 0] = "Error"
  RT_Data$Condition[RT_Data$Accuracy == 1] = "Correct"
  
  #########################################################
  # (4) Export [Add as new Rows]
  #########################################################


  Data_to_ADD = output[,c("ID", "Lab", "Task", "Condition","Experimenter", "ACC", colnames(output)[grepl("Covariate_", colnames(output))])]
  RT_Data = merge(
    RT_Data[,c("ID", "Condition", "Task", "Behav_RT", "Component")], 
    Data_to_ADD[!duplicated(Data_to_ADD),],
    by =  c("ID", "Task", "Condition"),
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
