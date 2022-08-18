DataQuality_Outliers = function(input = NULL, choice = NULL) {
StepName = "DataQuality_Outliers"
Choices = c("3.29 SD", "3.29 IQ", "2.5 SD", "2.5 IQ", "none")

#Adjust here below: make sure the script handles all choices (/choice/) defined above. Data is accessible via input$data
output = input$data
if (choice != "none"){
  # Determine Outliers based on Data Quality Per Condition
  SME_Data = unique(output[,c("ID", "SME", "Condition", "Electrode", "TimeWindow")])
  SME_Data = SME_Data [!is.na(SME_Data$SME),]
  
  # Calculate central tendencies
  if (grepl("SD", choice)) {
    Center = aggregate(SME_Data$SME, list(SME_Data$Condition, SME_Data$Electrode, SME_Data$TimeWindow), mean)
    Width = aggregate(SME_Data$SME, list(SME_Data$Condition, SME_Data$Electrode, SME_Data$TimeWindow), sd)
  } else {
    Center = aggregate(SME_Data$SME, list(SME_Data$Condition, SME_Data$Electrode, SME_Data$TimeWindow), median)
    Width = aggregate(SME_Data$SME, list(SME_Data$Condition, SME_Data$Electrode, SME_Data$TimeWindow), IQR)
    }
  # Calculate Min/Max acceptable numbers
  Distance = as.numeric(str_split(choice, " ")[[1]][1])
  SummaryTable = Center
  SummaryTable$Min_SME = Center$x -  Distance*Width$x  
  SummaryTable$Max_SME = Center$x +  Distance*Width$x  
  SummaryTable = subset(SummaryTable, select = -x)
  names(SummaryTable)[1:3] = c("Condition", "Electrode", "TimeWindow")

  
  # Merge with output file to identify outliers
  output = merge(output, SummaryTable, by = c("Condition", "Electrode", "TimeWindow"),
        all.x = TRUE,
        all.y = TRUE)
  Outlier_indx = !is.na(output$SME) & (output$SME < output$Min_SME |output$SME > output$Max_SME)
  output$Outlier[Outlier_indx] = 1
  
  # Remove collumns as not needed
  output = subset(output, select = -c(Min_SME, Max_SME))
  
  
}


#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
