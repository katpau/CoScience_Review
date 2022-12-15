Personality_Variable = function(input = NULL, choice = NULL) {
  StepName = "Personality_Variable"
  Choices = c("BISBAS_BIS","PSWQ_Concerns","RSTPQ_BIS","BFI_Anxiety","Z_AV_notweighted","Z_AV_ItemNr","Z_AV_Reliability","PCA","FactorAnalysis")
  Order = 3
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
