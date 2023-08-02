Trials_MinNumber = function(input = NULL, choice = NULL) {
  StepName = "Trials_MinNumber"
  Choices = c("10", "6")
  Order = 3.1
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by: CK 5/23
  
  # Since This is single Trial Data, min Trial Number still needs to be handled
  not_enough_trials = output$Epochs < as.numeric(choice)
  if (sum(not_enough_trials)>0) {
  output$EEG_Signal[not_enough_trials] = NA 
  output$RT[output$component == "Behav" && not_enough_trials] = NA # Also for RT, what about ACC?
  }
  
  
  # No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
