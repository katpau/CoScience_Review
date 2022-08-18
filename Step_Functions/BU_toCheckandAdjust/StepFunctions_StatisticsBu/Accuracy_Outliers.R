Accuracy_Outliers = function(input = NULL, choice = NULL) {
StepName = "Accuracy_Outliers"
Choices = c("3.29 SD", "3.29 IQ", "2.5 SD", "2.5 IQ", "none")

#Adjust here below: make sure the script handles all choices (/choice/) defined above. Data is accessible via input$data
output = input$data
output$Outlier = 0

if (choice != "none"){
# Determine Outliers based on Accuracy
AccuracyData = unique(output[,c("ID", "ACC")])
AccuracyData = AccuracyData [!is.na(AccuracyData$ACC),]

if (grepl("SD", choice)) {
Center = mean(AccuracyData$ACC)
Width = sd(AccuracyData$ACC)
  } else if (grepl("IQ", choice)) {
  Center = median(AccuracyData$ACC)
  Width = IQR(AccuracyData$ACC)
}
Distance = as.numeric(str_split(choice, " ")[[1]][1])

Min_ACC = Center-Distance*Width
Max_ACC = Center+Distance*Width
output$Outlier[!is.na(output$AC) & (output$ACC < Min_ACC | output$ACC > Max_ACC)] = 1

}

#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
