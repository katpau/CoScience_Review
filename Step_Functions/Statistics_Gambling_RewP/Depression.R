Depression = function(input = NULL, choice = NULL) {
  StepName = "Depression"
  Choices = c("BDI_Depression", "WHO5_Depression","Z_sum_Depression","Z_AV_notweighted_Depression","Z_AV_ItemNr_Depression","Z_AV_Reliability_Depression")
  Order = 3.1
  output = input$data
 
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:
  
  # Handles how Personality Data is defined (different Scores calculated outside)
  # No Action here, will be carried out in function "Covariate"
  

  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
