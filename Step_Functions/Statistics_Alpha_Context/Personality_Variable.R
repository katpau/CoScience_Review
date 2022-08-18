Personality_Variable = function(input = NULL, choice = NULL) {
StepName = "Personality_Variable"
Choices = c("BISBAS_BAS", "RSTPQ_BAS", "Z_Score_MPQ", "Z_Score_BFI",  "Z_Score_notWeighted", "Z_Score_ItemNr", "Z_Score_Reliability", "PCA_FirstFactor", "Factor_Analysis")
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
