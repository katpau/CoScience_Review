Normalize = function(input = NULL, choice = NULL) {
StepName = "Normalize"
Choices = c("Rankit", "Log", "None")

#Adjust here below: make sure the script handles all choices (/choice/) defined above. Data is accessible via input$data
output = input$data

Numeric_Collunms = unlist(sapply(output, is.numeric))
if (choice == "Rankit")  {
  output[,Numeric_Collunms] = lapply(output[,Numeric_Collunms], function(col) blom(col, method ="rankit"))
}
if (choice == "Log")  {
  # Add Constant to each collum including values <= 0
  Negative_Collumns = unname(Numeric_Collunms) &  as.numeric(apply(output, 2, min, na.rm = TRUE)) <= 0
  output[,Negative_Collumns] =  sapply(output[,Negative_Collumns], function(col) col - floor(min(col, na.rm =TRUE))-1)
  # Take Log
  output[,Numeric_Collunms] = log(output[,Numeric_Collunms])
}


#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
return(list(
  data = output,
  stephistory = stephistory
))
}