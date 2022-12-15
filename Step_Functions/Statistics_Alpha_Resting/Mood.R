Mood = function(input = NULL, choice = NULL) {
  StepName = "Mood"
  Choices = c("AV", "Diff")
  Order = 4.1
  output = input$data

  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:
  
  # Handles how Mood Score is defined
  # (1) Preparations: loading File and selecting Data
  # (2) Scoring: Depending on choice
  # (3) Export: Combine with data
  
  
  
  #########################################################
  # (1) Preparations 
  #########################################################
  # Read Behavioural Data
  BehavFile = paste0(input$stephistory["Root_Behavior"], "task_SR_beh.csv")
  BehavData = read.csv(BehavFile, header = TRUE, sep = ";")
  
  # keep only Ratings of Experimenter
  BehavData = BehavData[BehavData$Run == "1",]
  
  #########################################################
  # (2) Scoring 
  #########################################################
  positive_items = c("peppy", "happy", "relaxed", "calm")
  negative_items = c("anxious", "peeved", "tired", "sad", "exhausted", "irritated")
  if (choice == "AV") {
    #Average score on positive moods.
    BehavData$Behav_Mood = rowMeans(BehavData[,positive_items])
    
  } else if (choice == "Diff") {
    #Difference of average score on positive moods minus average score on negative moods
    BehavData$Behav_Mood = rowMeans(BehavData[,positive_items]) -
                     rowMeans(BehavData[,negative_items])
  }
  
  
  #########################################################
  # (3) Export 
  #########################################################
  # Merge with data
  output =  merge(
    output,
    BehavData[,c("ID", "Behav_Mood")],
    by = c("ID"),
    all.x = TRUE,
    all.y = FALSE
  )
  
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
