ExtremeEEG_Outliers = function(input = NULL, choice = NULL) {
StepName = "ExtremeEEG_Outliers"
Choices = c("3.29 SD", "3.29 IQ", "2.5 SD", "2.5 IQ", "none")

#Adjust here below: make sure the script handles all choices (/choice/) defined above. Data is accessible via input$data
output = input$data
output$Outlier_ExtremeEEG = 0
if (choice != "none"){
  # Determine Outliers based on Data Quality Per Condition
  ERP_Data = unique(output[,c("ID", "ERP", "Condition", "Electrode", "TimeWindow")])
  ERP_Data = ERP_Data [!is.na(ERP_Data$ERP),]
  
  # Calculate central tendencies
  if (grepl("SD", choice)) {
    Center = aggregate(ERP_Data$ERP, list(ERP_Data$Condition, ERP_Data$Electrode, ERP_Data$TimeWindow), mean)
    Width = aggregate(ERP_Data$ERP, list(ERP_Data$Condition, ERP_Data$Electrode, ERP_Data$TimeWindow), sd)
  } else {
    Center = aggregate(ERP_Data$ERP, list(ERP_Data$Condition, ERP_Data$Electrode, ERP_Data$TimeWindow), median)
    Width = aggregate(ERP_Data$ERP, list(ERP_Data$Condition, ERP_Data$Electrode, ERP_Data$TimeWindow), IQR)
  }
  # Calculate Min/Max acceptable numbers
  Distance = as.numeric(str_split(choice, " ")[[1]][1])
  SummaryTable = Center
  SummaryTable$Min_ERP = Center$x -  Distance*Width$x  
  SummaryTable$Max_ERP = Center$x +  Distance*Width$x  
  SummaryTable = subset(SummaryTable, select = -x)
  names(SummaryTable)[1:3] = c("Condition", "Electrode", "TimeWindow")
  
  
  # Merge with output file to identify outliers
  output = merge(output, SummaryTable, by = c("Condition", "Electrode", "TimeWindow"),
                 all.x = TRUE,
                 all.y = TRUE)
  Outlier_indx = !is.na(output$ERP) & (output$ERP < output$Min_ERP |output$ERP > output$Max_ERP)
  output$Outlier_ExtremeEEG[Outlier_indx] = 1
  
  # Remove collumns as not needed
  output = subset(output, select = -c(Min_ERP, Max_ERP))
  
  
}


#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
return(list(
  data = output,
  stephistory = stephistory
))
}
