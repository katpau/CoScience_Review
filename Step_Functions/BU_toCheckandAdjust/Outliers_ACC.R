Outliers_ACC = function(input = NULL, choice = NULL) {
StepName = "Outliers_ACC"
Choices = c("applied", "none")
Order = 6

#Adjust here below: make sure the script handles all choices (/choice/) defined above. Data is accessible via input$data
output = input$data

# Dont Do anything here, but do it then in Outliers_EEG


#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
