Outliers_ACC = function(input = NULL, choice = NULL) {
  StepName = "Outliers_ACC"
  Choices = c("Applied", "None")
  Order = 9.4
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:

  # if ACC is used as a predictor/DV, scan for outliers per Condition
  # otherwise scan for outliers across all Conditions
  # identifies and removes outliers based on previous criteria (thresholds)
  # (1) Get previous choices about threshold and prepare function
  # (2) Identify and Remove outlier
  
  
  #########################################################
  # (1) Preparations 
  #########################################################
  # Get ACC from Behaviour 
  # Read Behavioural Data Flanker
  BehavFile = paste0(input$stephistory["Root_Behavior"], "task_Flanker_beh.csv")
  BehavData = read.csv(BehavFile, header = TRUE)
  BehavData = BehavData[BehavData$ExperimenterPresence %in% "absent",]
  BehavData = BehavData[,c("ID","TaskPerf")]
  BehavData = BehavData[!duplicated(BehavData),]
  BehavData$Task = "Flanker"
  
  # Read Behavioural Data GoNoGo
  BehavFile = paste0(input$stephistory["Root_Behavior"], "task_GoNoGo_beh.csv")
  BehavData2 = read.csv(BehavFile, header = TRUE)
  BehavData2 = BehavData[BehavData2$InstructionCondition %in% "Speed",]
  BehavData2 = BehavData2[,c("ID",  "TaskPerf")]
  BehavData2 = BehavData2[!duplicated(BehavData2),]
  BehavData2$Task = "GoNoGo"
  BehavData = rbind(BehavData, BehavData2)
  colnames(BehavData)[2] = "ACC"
  
  
  # Get choices from Earlier
  Threshold = input$stephistory[["Outliers_Threshold"]]

  
  if (choice == "Applied"){
    
    # Set up outlier function based on Choice on Thresholds, takes the corresponding values (central tendency, width),
    # returns 0&1, 1 for the values exceeding the acceptable range
    outlierfunction = function(Threshold, data) {
      if (grepl("SD", Threshold)) {
        Center = mean(data, na.rm = TRUE)
        Width = sd(data, na.rm = TRUE)
      } else if (grepl("IQ", Threshold)) {
        Center = median(data,  na.rm = TRUE)
        Width = IQR(data, na.rm = TRUE)
      }
      Distance = as.numeric(str_split(Threshold, " ")[[1]][1])
      
      Min = Center-Distance*Width
      Max = Center+Distance*Width
      Outliers = numeric(length(data))
      Outliers[!is.na(data) & (data < Min | data > Max)] = 1
      return(Outliers)
    }
    
    
    #########################################################
    # (2) Identify Outliers 
    #########################################################
    BehavData = BehavData %>%
      group_by(Task) %>%
      summarise(Outliers_ACC = outlierfunction(Threshold, ACC),
                ID = ID) %>%
      ungroup()
    
    
    # merge with full dataset
    output =  merge(    output, 
                        BehavData,
                        by = c("ID", "Task"),
                        all.x = TRUE,    all.y = FALSE )
    
    # Remove ACC, RT, and EEG data if overall Accuracy is too low
    output$ACC[as.logical(output$Outliers_ACC)] = NA
    output$EEG_Signal[as.logical(output$Outliers_ACC)] = NA

    
  } else {
    # merge with full dataset
    output =  merge(    output, 
                        BehavData,
                        by = c("ID", "Task"),
                        all.x = TRUE,    all.y = FALSE )
  }
  
  
  
  
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
