Outliers_IQ = function(input = NULL, choice = NULL) {
  StepName = "Outliers_IQ"
  Choices = c("Applied", "None")
  Order = 10
  output = input$data

  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by: CK 5/23
  
  # Adds IQ Data but no change here. Outliers detected in outliers_Threshold
  # (1) Get previous choices about threshold and prepare function, get Data
  # (2) Identify outlier
  # (3) Treat outlier
  # (4) Merge with data
  
  
  
  
  #########################################################
  # (1) Preparations 
  #########################################################
  
  # Read Behavioural Data
  BehavFile = paste0(input$stephistory["Root_Behavior"], "task-IST_beh.csv")
  output_IQ = read.csv(BehavFile, header = TRUE)
  # Rename
  output_IQ$IST = output_IQ$IST_Fluid_Sum
  output_IQ = output_IQ[,c("ID", "IST")]
  
  if (choice == "Applied"){ 
    # Get choices from Earlier
    Threshold = input$stephistory[["Outliers_Threshold"]]
    Treatment = input$stephistory[["Outliers_Treatment"]]
    
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
    
    outliers_IQ = output_IQ %>%
      mutate(Outliers_IQ = outlierfunction(Threshold, IST, 0)) %>%
      ungroup()
    
    
    
    #########################################################
    # (3) Treat Outliers IQ
    #########################################################
    if (Treatment == "Replace" ){
      # Save Min/Max in column for later
      MinMax = output_IQ %>%
        do(outlierfunction(Threshold, .$IST, 1))%>%
        ungroup()
      
      
      # merge with data
      output_IQ =  merge(output_IQ,    
                         MinMax,   
                         all.x = TRUE,    all.y = FALSE )
      
      ExceedMin = which(output_IQ$IST<output_IQ$Min)
      ExceedMax = which(output_IQ$IST>output_IQ$Max)
      output_IQ$IST[ExceedMin] =   output_IQ$Min[ExceedMin]
      output_IQ$IST[ExceedMax] =   output_IQ$Max[ExceedMax]
      
      # Exclude Value
    } else {
      output_IQ$IST[as.logical(output_IQ$Outliers_IQ)] = NA  }
    
    
    # Remove columns
    output_IQ = output_IQ[,!names(output_IQ) %in% c("Outliers_IQ",  "Min", "Max")]
    
  }
  
  #########################################################
  # (4) Merge with Data
  #########################################################
  # Merge with data
  output =  merge(
    output,
    output_IQ[,c("ID", "IST")],
    by = "ID",
    all.x = TRUE,
    all.y = FALSE
  )
  
  
  
  
  
  # No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
