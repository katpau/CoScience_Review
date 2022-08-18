Center = function(input = NULL, choice = NULL) {
StepName = "Center"
Choices = c("Centered", "None")

#Adjust here below: make sure the script handles all choices (/choice/) defined above. Data is accessible via input$data
output = input$data
Numeric_Collunms = unlist(sapply(output, is.numeric))
if (choice == "Centered")  {
  output[,Numeric_Collunms] = lapply(output[,Numeric_Collunms], function(col) col-mean(col, na.rm=TRUE))
}

#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
