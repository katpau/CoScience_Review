Trials_MinNumber = function(input = NULL, choice = NULL) {
  StepName = "Trials_MinNumber"
  Choices = c("18", "9")
  Order = 1
  output = input$data
  
  ## Contributors
  # Last checked by KP 01/23
  # Planned/Completed Review by: 
  
  # Since This is single Trial Data, min Trial Number still needs to be handled
 

  
  TrialCount = output %>%
    group_by(ID, Offer, Component, Electrode ) %>%
    summarise(Epochs = length(ID))
  
  output = merge(output, TrialCount,
                 by = c("ID", "Offer", "Component", "Electrode"))
  
  output = output[output$Epochs >= as.numeric(choice),]
  
  
  
  # No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
