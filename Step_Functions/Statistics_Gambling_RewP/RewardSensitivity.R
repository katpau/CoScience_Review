RewardSensitivity = function(input = NULL, choice = NULL) {
StepName = "RewardSensitivity"
Choices = c("PCA", "RSTPQ_RewardInterest","MPQPE_PositiveEmotionality","BISBAS_BAS","Z_sum_RewardSensitivity", "Z_AV_notweighted_RewardSensitivity","Z_AV_ItemNr_RewardSensitivity","Z_AV_Reliability_RewardSensitivity", "FactorAnalysis")

## Contributors
# Last checked by KP 12/22
# Planned/Completed Review by:

Order = 3.2
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
