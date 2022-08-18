Attention_Checks_Personality = function(input = NULL, choice = NULL) {
StepName = "Attention_Checks_Personality"
Choices = c("Applied", "None")
Order = 1
output = input$data

# Handles if Personality Data should be screened for reliable data 
# (i.e. correct answers to attention checks and reasonable RTs)
# No Action here, will be carried out in function "Covariate"


#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
