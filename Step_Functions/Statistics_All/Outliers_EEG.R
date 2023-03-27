Outliers_EEG = function(input = NULL, choice = NULL) {
  StepName = "Outliers_EEG"
  Choices = c("Applied", "None")
  Order = 8
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:

  # Handles if outliers based on EEG should be identified or not
  # Handles all Choices listed above as well as for Outliers in terms of EEG & SME 
  # (1) Prepare Inputs, get Grouping Variables (different Tasks, Analysis Phases, Conditions...), 
  #     initiate outlier function based on input
  # (2) Identify Outliers in EEG/SME
  # (3) Replace/Exclude Outliers in EEG/SME
  
  
  
  #########################################################
  # (1) Preparations 
  #########################################################
  Threshold = input$stephistory[["Outliers_Threshold"]]
  Treatment = input$stephistory[["Outliers_Treatment"]]
  EEG_Outlier = choice
  SME_Outlier = input$stephistory["Outliers_SME"] 
  output$Outliers_EEG = 0
  output$Outliers_SME = 0
  
  if (EEG_Outlier == "Applied" | SME_Outlier == "Applied" ) {
    GroupingVariables = input$stephistory[["GroupingVariables"]]
    
    # Set up outlier function based on Choice on Thresholds, takes the corresponding values (central tendency, width),
    # returns 0&1, 1 for the values exceeding the acceptable range
    # can then be used quickly below in piping
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
    # (2) Find Outliers EEG
    #########################################################  
    # Outliers SME
    if (SME_Outlier == "Applied") {
      output = output %>%
        group_by(across(all_of(GroupingVariables ) )) %>%
        mutate(Outliers_SME = outlierfunction(Threshold, SME,  0))   %>%
        ungroup()
    }
    
    # Outliers EEG
    if (EEG_Outlier == "Applied") {
      output = output %>%
        group_by(across(all_of(GroupingVariables ) ))%>%
        mutate(Outliers_EEG = outlierfunction(Threshold, EEG_Signal,  0))  %>%
        ungroup()
    } 
    
    
    #########################################################
    # (3) Treat Outliers EEG + SME
    #########################################################
    if (Treatment == "Replace" & EEG_Outlier == "Applied"){
      # Save Min/Max in collumn for later
      MinMax = output %>%
        group_by(across(all_of(GroupingVariables ) ))%>%
        do(outlierfunction(Threshold, .$EEG_Signal, 1))%>%
        ungroup()
      
      
      # merge with output
      output =  merge(output,    
                      MinMax,
                      by = GroupingVariables,   
                      all.x = TRUE,    all.y = FALSE )
      
      ExceedMin = which(output$EEG_Signal<output$Min)
      ExceedMax = which(output$EEG_Signal>output$Max)
      output$EEG_Signal[ExceedMin] =   output$Min[ExceedMin]
      output$EEG_Signal[ExceedMax] =   output$Max[ExceedMax]
      
      # Exclude Value
    } else if (Treatment == "Exclude" & EEG_Outlier == "Applied") {
      output$EEG_Signal[as.logical(output$Outliers_EEG)] = NA  }
    
    
    if (SME_Outlier == "Applied") {
      ## Remove EEG if SME out of Range
      output$EEG_Signal[as.logical(output$Outliers_SME)] = NA 
    }
    
    
  
  
  # Remove collumns
  output = output[,!names(output) %in% c("Outliers_EEG", "Outliers_SME", "Min", "Max")]
  
}


#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
return(list(
  data = output,
  stephistory = stephistory
))
}
