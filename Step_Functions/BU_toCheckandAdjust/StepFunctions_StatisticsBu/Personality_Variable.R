Personality_Variable = function(input = NULL, choice = NULL) {
StepName = "Personality_Variable"
Choices = c("PSWQ_Concerns", "BISBAS_BIS", "RSTPQ_BIS", "SANB5_Social_Phobia", "BFI_Anxiety", "z_Score_noWeight", "z_Score_ItemNr", "z_Score_Reliability", "PCA_FirstFactor")
#Adjust here below: make sure the script handles all choices (/choice/) defined above. Data is accessible via input$data
output = input$data

output$Personality_Variable = NA
output$Personality_Variable = output[,choice]
output = output[,-which(names(output) %in% Choices)]


#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
