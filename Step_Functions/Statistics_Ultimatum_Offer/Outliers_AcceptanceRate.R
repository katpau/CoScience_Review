Outliers_AcceptanceRate = function(input = NULL, choice = NULL) {
  StepName = "Outliers_AcceptanceRate"
  Choices = c("Applied", "None")
  Order = 9.4
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:

  # if ACC is used as a predictor/DV, scan for outliers per Condition
  # identifies and removes outliers based on previous criteria (thresholds)
  # (1) Get previous choices about threshold and prepare function
  # (2) Identify outlier
  # (3) Treat outliers
  
  
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
    # for ACC, only one value per Task and Subject should be used [checked across conditions]
    # select only relevant columns and drop duplicates
    output_ACC = output[,c("ID",  "Offer", "Response", "Behav_AcceptanceRate")]
    output_ACC = output_ACC[!duplicated(output_ACC),]
    outliers_ACC = output_ACC %>%
      group_by(Offer, Response)%>%
      summarise(Outliers_ACC = outlierfunction(Threshold, Behav_AcceptanceRate,0),
                ID = ID) %>%
      ungroup()
    
    
    # merge with full dataset
    output =  merge(    output, 
                        outliers_ACC,
                        by = c("ID", "Offer", "Response" ),
                        all.x = TRUE,    all.y = FALSE )
    
    #########################################################
    # (3) Treat Outliers ACC
    #########################################################
    if (Treatment == "Replace" ){
      # Save Min/Max in collumn for later
      MinMax = output_ACC %>%
        group_by(Offer, Response)%>%
        do(outlierfunction(Threshold, .$Behav_AcceptanceRate, 1))%>%
        ungroup()
      
      
      # merge with output
      output =  merge(output,    
                      MinMax,
                      by = c( "Offer", "Response" ),
                      all.x = TRUE,    all.y = FALSE )
      
      ExceedMin = which(output$Behav_AcceptanceRate<output$Min)
      ExceedMax = which(output$Behav_AcceptanceRate>output$Max)
      output$Behav_AcceptanceRate[ExceedMin] =   output$Min[ExceedMin]
      output$Behav_AcceptanceRate[ExceedMax] =   output$Max[ExceedMax]
      
      # Exclude Value
    } else {
      output$Behav_AcceptanceRate[as.logical(output$Outliers_ACC)] = NA  }
    
    
    # Remove collumns
    output = output[,!names(output) %in% c("Outliers_ACC",  "Min", "Max")]
    
    
  }
  
  
  
  
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
