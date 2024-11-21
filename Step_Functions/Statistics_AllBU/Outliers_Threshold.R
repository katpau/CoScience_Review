Outliers_Threshold = function(input = NULL, choice = NULL) {
StepName = "Outliers_Threshold"
Choices = c("3.29 SD", "3.29 IQ", "2.5 SD", "2.5 IQ", "None")
Order = 5
output = input$data

## Contributors
# Last checked by KP 12/22
# Planned/Completed Review by:



# Handles how outliers in EEG, behavior, SME etc should be identified
# No Action here, will be carried out in function "Treat_Outliers"



#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
