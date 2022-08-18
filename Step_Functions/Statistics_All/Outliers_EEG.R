Outliers_EEG = function(input = NULL, choice = NULL) {
StepName = "Outliers_EEG"
Choices = c("Applied", "None")
Order = 5.1
output = input$data


# Handles if outliers based on EEG should be identified or not
# No Action here, will be carried out in function "Outliers_Threshold"


#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
