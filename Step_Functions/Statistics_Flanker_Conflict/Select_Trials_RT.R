Select_Trials_RT = function(input = NULL, choice = NULL) {
  StepName = "Select_Trials_RT"
  Choices = c("RT_ACC", "ACC")
  Order = 9.1
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by: CK 5/23
  
  # Handles which Trials are included to calculate RTs
  #########################################################
  # (1) Preparations 
  #########################################################
  # Collect all Choices
  Select_Trials_RT = choice
  
  
  # Read Behavioural Data
  BehavFile = paste0(input$stephistory["Root_Behavior"], "task_Flanker_beh.csv")
  BehavData = read.csv(BehavFile, header = TRUE)
  
  
  #########################################################
  # (2) Drop Trials 
  #########################################################
  # only without experimenter
  BehavData = BehavData[BehavData$ExperimenterPresence %in% "absent",]
  # only Trials with Response # CK: for GLMM (Accuracy) these might be treated as incorrect
  # Alternative: set ACC to NA if no Response?
  BehavData$Accuracy[is.na(BehavData$RT)] = NA
  
  
  # only correct Trials     
  # Do not remove here but exclude it later in Determine Sign
  # BehavData = BehavData[BehavData$Accuracy %in% 1,]

  # if RT also used as criteria
  if (Select_Trials_RT == "RT_ACC") {
    BehavData$RT[which(BehavData$RT >= 0.8)] = NA
    BehavData$RT[which(BehavData$RT <= 0.1)] = NA
  }
  
  
  
  #########################################################
  # (4) Export [Add as new Rows]
  #########################################################
  BehavData$Component = "Behav"
  BehavData$ACC = BehavData$Accuracy
  BehavData = BehavData %>%
    group_by(ID) %>%
    mutate(Trial = 1:length(RT)) %>%
    group_by(ID, Congruency) %>%
    mutate(Epochs = sum(ACC)) # counts only correct responses 
  
  Data_to_ADD = output[,c("ID", "Lab", "Experimenter")]
  RT_Data = merge(
    BehavData[, c("ID", "Congruency", "Trial", "Epochs", "RT", "ACC", "Component")], 
    Data_to_ADD[!duplicated(Data_to_ADD),],
    by =  c("ID"),
    all.x = FALSE,
    all.y = FALSE
  )
  
  # Merge with data
  output = bind_rows(output, RT_Data)
  
  
  # No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}