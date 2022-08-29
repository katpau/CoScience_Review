Outliers_Threshold = function(input = NULL, choice = NULL) {
StepName = "Outliers_Threshold"
Choices = c("3.29 SD", "3.29 IQ", "2.5 SD", "2.5 IQ", "None")
Order = 7
output = input$data


# Handles how outliers in EEG, behavior, SME etc should be identified
# No Action here, will be carried out in function "Outliers_EEG"



# Handles all Choices listed above as well as choices from previous Steps 
# (Outliers_SME (Data quality), Outliers_ACC (Behavior))
# (1) Prepare Inputs, get Grouping Variables (different Tasks, Analysis Phases, Conditions), 
#     initiate outlier function based on input
# (2) Identify Outliers
# (3) Get Min/Max acceptable Range for EEG data (for later)



#########################################################
# (1) Preparations 
#########################################################
Threshold = choice
output$Outliers_EEG = 0
output$Outliers_SME = 0
output$Outliers_ACC = 0

if (Threshold != "None") {
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
  # (2) Find Outliers 
  #########################################################  
  # Outliers SME
  if (input$stephistory["Outliers_SME"] != "None") {
    output = output %>%
      group_by(across(all_of(GroupingVariables ) )) %>%
      mutate(Outliers_SME = outlierfunction(Threshold, SME,  0))   %>%
      ungroup()
  }
  
  # Outliers EEG
  if (input$stephistory["Outliers_EEG"] != "None") {
    output = output %>%
      group_by(across(all_of(GroupingVariables ) ))%>%
      mutate(Outliers_EEG = outlierfunction(Threshold, EEG_Signal,  0))  %>%
      ungroup()
  }
  
  # Outliers ACC
  if ("Outliers_ACC" %in% input$stephistory) {
    if (input$stephistory["Outliers_ACC"] != "None") {
      # for Accuracy, only one value per Task and Subject should be used
      # select only relevant columns and drop duplicates
      output_ACC = output[,c("ID", "Task", "ACC")]
      output_ACC = output_ACC[!duplicated(output_ACC),]
      output_ACC = output_ACC %>%
        group_by(across(all_of("Task" ) ))%>%
        mutate(Outliers_ACC = outlierfunction(Threshold, ACC,  0)) %>%
        ungroup()
      
      # merge with full dataset
      output =  merge(    subset(output, select=-c(Outliers_ACC, ACC)),    output_ACC,
                          by = c("ID", "Task" ),
                          all.x = TRUE,    all.y = FALSE )
      
    }}
  
  
  #########################################################
  # (3) Export Min/Max 
  #########################################################
  
  # Save Min/Max in collumn for later
  MinMax = output %>%
    group_by(across(all_of(GroupingVariables ) ))%>%
    do(outlierfunction(Threshold, .$EEG_Signal, 1))%>%
    ungroup()
  

  # merge with output
  output =  merge(    output,    MinMax,
                      by = GroupingVariables,    all.x = TRUE,    all.y = FALSE )
  
  # Add ID as first Variable again
  output = output %>%  dplyr::select("ID", everything())
}


#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
