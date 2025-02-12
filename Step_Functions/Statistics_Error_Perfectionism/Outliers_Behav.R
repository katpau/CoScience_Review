Outliers_Behav = function(input = NULL, choice = NULL) {
  StepName = "Outliers_Behav"
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
    # select only relevant rows
    output_Behav = output[output$Component == "RTDiff"| output$Component == "post_ACC",
                       c("ID", "Condition", "Task", "Behav", "Component",
                         "Experimenter", "Lab", "TaskPerf",
                         names(output)[grepl("Covariate_|Personality", names(output))])] 

    
    # Define outliers separately for Task, Condition and Component
    output_Behav_outlier = output_Behav %>%
      group_by(Condition, Task, Component) %>%
      summarise(Outliers_Behav = outlierfunction(Threshold, Behav, 0),
                ID = ID) %>%
      ungroup()
    
    # merge with behavior table
    output_Behav =  merge(output_Behav,    
                          output_Behav_outlier,
                          by = c("Condition", "Task", "ID", "Condition", "Component"),   
                          all.x = TRUE,    all.y = FALSE )
    
    
    #########################################################
    # (3) Treat Outliers 
    #########################################################
    if (Treatment == "Replace" ){
      # Save Min/Max in collumn for later
      MinMax = output_Behav %>%
        group_by(Condition, Task, Component)%>%
        do(outlierfunction(Threshold, .$Behav, 1))%>%
        ungroup()
      
      
      # merge with output
      output_Behav =  merge(output_Behav,    
                      MinMax,
                      by = c("Condition", "Task", "Component"),   
                      all.x = TRUE,    all.y = FALSE )
      
      ExceedMin = which(output_Behav$Behav<output_Behav$Min)
      ExceedMax = which(output_Behav$Behav>output_Behav$Max)
      output_Behav$Behav[ExceedMin] =   output_Behav$Min[ExceedMin]
      output_Behav$Behav[ExceedMax] =   output_Behav$Max[ExceedMax]
      
      # Exclude Value
    } else {
      output_Behav$Behav[as.logical(output_Behav$Outliers_Behav)] = NA
      output_Behav$Behav[as.logical(output_Behav$Outliers_Behav)] = NA 
      }
    
    # Merge with EEG Dataframe
    output = bind_rows (output[!(output$Component == "RTDiff"| output$Component == "post_ACC"),],
              output_Behav[, names(output_Behav) %in% names(output)])
    
  }
  
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
