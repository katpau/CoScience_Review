Personality_Variable = function(input = NULL, choice = NULL) {
StepName = "Personality_Variable"
Choices = c("AVBIS", "RSTPQ_BIS","BISBAS_BIS","BFI_Anxiety","PSWQ_Concerns","Z_AV_notweighted","Z_AV_ItemNr","Z_AV_Reliability","PCA","FactorAnalysis")
Order = 3
output = input$data

## Contributors
# Last checked by KP 12/22
# Planned/Completed Review by:

# Handles how Personality Data is defined (different Scores calculated outside)
# No Action here, will be carried out in function "Covariate"

# NFC, Anger and Altruism is not Forked "AGG_Anger","NFC_NeedForCognition", "PTM_Altruism", Age

#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
