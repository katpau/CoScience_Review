Outliers_Personality = function(input = NULL, choice = NULL) {
StepName = "Outliers_Personality"
Choices = c("None", "Excluded")
Order = 2
output = input$data

## Contributors
# Last checked by KP 12/22
# Planned/Completed Review by:

# Handles if Personality Data should be screened for outliers
# based on Mahalanobis Distance
# No Action here, will be carried out in function "Covariate"

#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
