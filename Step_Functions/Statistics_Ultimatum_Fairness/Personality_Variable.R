Personality_Variable = function(input = NULL, choice = NULL) {
StepName = "Personality_Variable"
Choices = c("AVBIS", "RSTPQ_BIS","BISBAS_BIS","BFI_Anxiety","PSWQ_Concerns","Z_sum","Z_AV_notweighted","Z_AV_ItemNr","Z_AV_Reliability","PCA","Factor_Analysis")


## Contributors
# Last checked by KP 12/22
# Planned/Completed Review by:

Order = 3
output = input$data

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
