Outliers_Treatment = function(input = NULL, choice = NULL) {
  StepName = "Outliers_Treatment"
  Choices = c("Exclude", "Replace", "None")
  Order = 6
  output = input$data
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:

  # Nothing done here, used in Outliers_EEG and Outliers_RT
  
  # no Change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
