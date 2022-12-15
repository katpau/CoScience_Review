Outliers_RT = function(input = NULL, choice = NULL) {
  StepName = "Outliers_RT"
  Choices = c("Applied", "None")
  Order = 9.3
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:

  # if RT is used as a predictor/DV, scan for outliers
  # identifies and removes outliers based on previous criteria (thresholds)
  # (1) Get previous choices about threshold and prepare function
  # (2) Identify outliers based on RT
  # (3) Treat outliers (exclude/replace)
  
  
  #########################################################
  # (1) Preparations 
  #########################################################
  
  # Get choices from Earlier
  Threshold = input$stephistory[["Outliers_Threshold"]]
  Treatment = input$stephistory[["Outliers_Treatment"]]
  
  if (choice == "Applied"){
    
    # Set up outlier function based on Choice on Thresholds, takes the corresponding values (central tendency, width),
    # returns 0&1, 1 for the values exceeding the acceptable range
    outlierfunction = function(Threshold, data,  ExportMinMax) {
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
      if (ExportMinMax == 1) {
        return(data.frame(Min,Max))
      }  else { return(Outliers)}
    }
    
    
    #########################################################
    # (2) Identify Outliers 
    #########################################################
    # for RT, only one value per Task and Subject should be used
    # select only relevant columns and drop duplicates
    output_RT = output[,c("ID", "Condition", "Task", "Behav_RT")] 
    output_RT = output_RT[!is.na(output_RT$Behav_RT), ]
    output_RT = output_RT[!duplicated(output_RT), ]
    
    
    output_RT_outlier = output_RT %>%
      group_by(Condition, Task) %>%
      summarise(Outliers_RT = outlierfunction(Threshold, Behav_RT, 0),
                ID = ID) %>%
      ungroup()
    
    
    # merge with full dataset
    output =  merge(    output, 
                        output_RT_outlier,
                        by = c("ID", "Condition", "Task" ),
                        all.x = TRUE,    all.y = FALSE )
    
    
    
    
    #########################################################
    # (3) Treat Outliers RT
    #########################################################
    if (Treatment == "Replace" ){
      # Save Min/Max in collumn for later
      MinMax = output_RT %>%
        group_by(Condition, Task)%>%
        do(outlierfunction(Threshold, .$Behav_RT, 1))%>%
        ungroup()
      
      
      # merge with output
      output =  merge(output,    
                      MinMax,
                      by = c("Condition", "Task"),   
                      all.x = TRUE,    all.y = FALSE )
      
      ExceedMin = which(output$Behav_RT<output$Min)
      ExceedMax = which(output$Behav_RT>output$Max)
      output$Behav_RT[ExceedMin] =   output$Min[ExceedMin]
      output$Behav_RT[ExceedMax] =   output$Max[ExceedMax]
      
      # Exclude Value
    } else {
      output$Behav_RT[as.logical(output$Outliers_RT)] = NA  }
    
    
    # Remove collumns
    output = output[,!names(output) %in% c("Outliers_RT",  "Min", "Max")]
    
  }
  
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
