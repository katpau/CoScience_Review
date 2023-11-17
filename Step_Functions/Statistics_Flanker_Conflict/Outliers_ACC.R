Outliers_ACC = function(input = NULL, choice = NULL) {
  StepName = "Outliers_ACC"
  Choices = c("Applied", "None")
  Order = 9.4
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by: CK 5/23

  # if ACC is used as a predictor/DV, scan for outliers per Condition
  # otherwise scan for outliers across all Conditions
  # identifies and removes outliers based on previous criteria (thresholds)
  # (1) Get previous choices about threshold and prepare function
  # (2) Identify and Remove outlier
  
  
  #########################################################
  # (1) Preparations 
  #########################################################
  
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
    # for ACC, only one value per Task and Subject should be used [checked across conditions]
    # Calculate Global Task Accuracy based on BehavData
    output_Behav = output[output$Component == "Behav",] 
    output_ACC = output_Behav %>%
      group_by(ID) %>%
      summarise(ACC_Task = sum(ACC)/length(ACC)*100) %>% 
      ungroup %>%
      summarise(ID = ID,
                Outliers_ACC = outlierfunction(Threshold, ACC_Task))
        
    # merge with full dataset
    output =  merge(    output, 
                        output_ACC,
                        by = c("ID" ),
                        all.x = TRUE,    all.y = FALSE )
    
    # Remove ACC, RT, and EEG data if overall Accuracy is too low
    output$EEG_Signal[as.logical(output$Outliers_ACC)] = NA
    output$RT[as.logical(output$Outliers_ACC)] = NA
    output$ACC[as.logical(output$Outliers_ACC)] = NA    
    
    # Remove columns
    output = output[,!names(output) %in% c("Outliers_ACC")]
    
  }
  
  
  
  
  
  # No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
