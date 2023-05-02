Select_Trials_RT = function(input = NULL, choice = NULL) {
  StepName = "Select_Trials_RT"
  Choices = c("RT_ACC", "ACC")
  Order = 9.1
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by: CK 5/23
  
  # Handles which Trials are included to calculate RTs
  # No Action here, will be carried out in function "RT"
  
  
  # No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
