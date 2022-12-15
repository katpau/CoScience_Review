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
    # for RT, only one value per Task and Subject should be used
    # select only relevant columns and drop duplicates
    output_ACC = output[,c("ID", "ACC")]
    output_ACC = output_ACC[!duplicated(output_ACC),]
    output_ACC = output_ACC %>%
      summarise(Outliers_ACC = outlierfunction(Threshold, ACC),
                ID = ID) %>%
      ungroup()
    
    
    
    # merge with full dataset
    output =  merge(    output, 
                        output_ACC,
                        by = c("ID" ),
                        all.x = TRUE,    all.y = FALSE )
    
    # Remove ACC, RT, and EEG data if overall Accuracy is too low
    output$ACC[as.logical(output$Outliers_ACC)] = NA
    output$EEG_Signal[as.logical(output$Outliers_ACC)] = NA
    output$Behav_RT[as.logical(output$Outliers_ACC)] = NA
    
  }
  
  
  
  
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
