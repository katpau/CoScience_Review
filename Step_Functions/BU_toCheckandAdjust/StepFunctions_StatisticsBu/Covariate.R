Covariate = function(input = NULL, choice = NULL) {
StepName = "Covariate"
Choices = c("None", "Age_MF", "Age", "Experimenter_Sex", "Attractiveness", "Likeability", "Perfectionism", "Sociability", "Depression", 
            "Openness", "Conscientiousness", "Agreeableness", "Extraversion", "Big5_OCAE")

#Adjust here below: make sure the script handles all choices (/choice/) defined above. Data is accessible via input$data
output = input$data

#Adjust here below: make sure the script handles all choices (/choice/) defined above. Data is accessible via input$data
output = input$data

if (choice != "None"){
output$Covariate= output[,choice]
} else {output$Covariate = NA}

if (length(which(names(output) %in% Choices)) > 0) { output = output[,-which(names(output) %in% Choices)]}

#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
