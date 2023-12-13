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
  Select_Trials_RT = unlist(input$stephistory["Select_TrialsRT"])
  
  
  # Read Behavioural Data Flanker
  BehavFile = paste0(input$stephistory["Root_Behavior"], "task_Flanker_beh.csv")
  BehavData = read.csv(BehavFile, header = TRUE)
  BehavData = BehavData[BehavData$ExperimenterPresence %in% "absent",]
  BehavData = BehavData[,c("ID","Accuracy", "RT", "Post_Trial", "TaskPerf")]
  BehavData$Task = "Flanker"
  
  # Read Behavioural Data GoNoGo
  BehavFile = paste0(input$stephistory["Root_Behavior"], "task_GoNoGo_beh.csv")
  BehavData2 = read.csv(BehavFile, header = TRUE)
  BehavData2 = BehavData2[BehavData2$InstructionCondition %in% "Speed",]
  BehavData2 = BehavData2[,c("ID",  "Accuracy", "RT", "Post_Trial", "TaskPerf")]
  BehavData2$Task = "GoNoGo"
  
  BehavData = rbind(BehavData, BehavData2)
  BehavData = BehavData[!is.na(BehavData$RT),]
  
  
  #########################################################
  # (2) Calculate RT Diff
  #########################################################
  # only Trials with Response
  if (Select_Trials_RT == "RTs") {
    BehavData$RT[BehavData$RT >= 0.8] = NA 
    BehavData$RT[BehavData$RT <= 0.1] = NA 
  }
  
  # Calculate Difference to NEXT trial: negative means becoming slower
  BehavData$RTDiff = c(BehavData$RT[1:(nrow(BehavData)-1)] -
                        BehavData$RT[2:nrow(BehavData)],
                     NA)
  
  # Remove Difference to "non trials" (breaks, ends, last Trial..)
  BehavData$RTDiff[which(BehavData$Task =="Flanker" &
    !grepl("post_correct|post_error", BehavData$Post_Trial))-1] = NA
  BehavData$RTDiff[which(BehavData$Task =="GoNoGo" &
                         !grepl("post_correct_resp|post_error_resp", BehavData$Post_Trial))-1] = NA
  
  
  if (choice == "AV") {
    RT_Data = BehavData %>%
      filter(!is.na(RTDiff)) %>%
      group_by(ID, Task, Accuracy) %>%
      summarise(Behav = mean(RTDiff)) 
    

  } else if (choice == "trimmedAV") {
    RT_Data = BehavData %>%
      filter(!is.na(RTDiff)) %>%
      group_by(ID, Task, Accuracy) %>%
      summarise(Behav = mean(RTDiff, trim = 0.05))# lowest and highest 5 %
    
    
  } else if (choice == "Median") {
    RT_Data = BehavData %>%
      filter(!is.na(RTDiff)) %>%
      group_by(ID, Task, Accuracy) %>%
      summarise(Behav = median(RTDiff))
    
  }
  
  RT_Data$Component = "RTDiff"
  RT_Data$Condition = NA
  RT_Data$Condition[RT_Data$Accuracy == 0] = "error"
  RT_Data$Condition[RT_Data$Accuracy == 1] = "correct"
  RT_Data = select(RT_Data, -c(Accuracy))
  
  

  #########################################################
  # (3) Calculate Post Accuracy
  #########################################################
  # only response not inhibition conditions
  BehavData$Post_Trial[BehavData$Post_Trial == "post_correct_resp"] = "post_correct"
  BehavData$Post_Trial[BehavData$Post_Trial == "post_error_resp"] = "post_error"
  
  ACC_Data = BehavData %>%
    filter(Post_Trial == "post_correct" | Post_Trial == "post_error" ) %>%
    group_by(ID, Task, Post_Trial ) %>%
    summarise(Behav = sum(Accuracy)/length(Accuracy)*100  )
  ACC_Data$Condition = gsub("post_", "", ACC_Data$Post_Trial)
  ACC_Data = select(ACC_Data, -c(Post_Trial))
  
  ACC_Data$Component = "post_ACC"
  
  TaskPerf = BehavData[,c("ID", "Task", "TaskPerf")]
  TaskPerf = TaskPerf[!duplicated(TaskPerf),]
  

  
  #########################################################
  # (4) Export [Add as new Rows]
  #########################################################
  
  # Merge Behav Data together with import info
  Data_to_ADD = output[,c("ID", "Lab", "Task", "Condition","Experimenter", colnames(output)[grepl("Covariate_|Personality_", colnames(output))])]
  output_Behav = bind_rows(ACC_Data, RT_Data)
  output_Behav = merge(
    output_Behav, 
    Data_to_ADD[!duplicated(Data_to_ADD),],
    by =  c("ID", "Task", "Condition"),
    all.x = FALSE,
    all.y = FALSE
  )
  
  # Merge with EEG data
  output = bind_rows(output, output_Behav)
 
  # Add Task Performance everywhere
  output = merge(output, 
                 TaskPerf,
                 by =  c("ID", "Task"),
                 all.x = T,
                 all.y = F)

  
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
