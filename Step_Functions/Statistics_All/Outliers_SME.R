Outliers_SME = function(input = NULL, choice = NULL) {
StepName = "Outliers_SME"
Choices = c("Applied", "None")
Order = 7
output = input$data

## Contributors
# Last checked by KP 12/22
# Planned/Completed Review by:


# Handles if outliers based on SME should be identified or not
# No Action here, will be carried out in function "Outliers_EEG"



#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
