Personality_Variable = function(input = NULL, choice = NULL) {
StepName = "Personality_Variable"
Choices = c("BISBAS_BAS","RSTPQ_BAS","Z_sum_MPQ","Z_sum_BFI","Z_AV_notweighted_BAS","Z_AV_ItemNr_BAS","Z_AV_Reliability_BAS","PCA_BAS","FactorAnalysis_BAS")
Order = 3
output = input$data

## Contributors
# Last checked by KP 12/22
# Planned/Completed Review by: Cassie (CAS) 4/23

# Handles how Personality Data is defined (different Scores calculated outside)
# No Action here, will be carried out in function "Covariate"

# Just assign Variable for BIS here too, given that they are Not considered in same model, they
# do not need to be forked independently (maybe even better if not)
# could not find where Z_sum_BFI is defined, to check that it comprises assertiveness and energy level

if (choice == "BISBAS_BAS") {
  choiceBIS = "BISBAS_BIS" 
} else if (choice == "RSTPQ_BAS") {
 choiceBIS = "RSTPQ_BIS" 
} else if (choice == "Z_sum_MPQ") {
  choiceBIS = "PSWQ_Concerns" 
} else if (choice == "Z_sum_BFI") {
  choiceBIS = "BFI_Anxiety" 
} else if (choice == "Z_AV_notweighted_BAS") {
  choiceBIS = "Z_AV_notweighted_BIS" 
} else if (choice == "Z_AV_ItemNr_BAS") {
  choiceBIS = "Z_AV_ItemNr_BIS" 
} else if (choice == "Z_AV_Reliability_BAS") {
  choiceBIS = "Z_AV_Reliability_BIS" 
} else if (choice == "PCA_BAS") {
  choiceBIS = "PCA_BIS" 
} else if (choice == "FactorAnalysis_BAS") {
  choiceBIS = "FactorAnalysis_BIS" 
}
print(choiceBIS)


#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
stephistory["Personality_Variable_BIS"] = choiceBIS
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
