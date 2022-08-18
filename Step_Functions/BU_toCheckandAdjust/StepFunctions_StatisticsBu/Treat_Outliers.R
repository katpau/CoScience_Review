Treat_Outliers = function(input = NULL, choice = NULL) {
StepName = "Treat_Outliers"
Choices = c("exclude", "replace")

#Adjust here below: make sure the script handles all choices (/choice/) defined above. Data is accessible via input$data
output = input$data

# Replace only applicable for Outliers if EEG is out of range. For other reasons (ACC, Dataquality, MinEpochs etc) ERP must be excluded
if (choice == "replace")  {
  output$ERP[output$ERP<output$Min_ERP & output$Outlier_ExtremeEEG ==1] =   output$Min_ERP[output$ERP<output$Min_ERP & output$Outlier_ExtremeEEG ==1]
  output$ERP[output$ERP<output$Max_ERP & output$Outlier_ExtremeEEG ==1] =   output$Min_ERP[output$ERP<output$Max_ERP & output$Outlier_ExtremeEEG ==1]
    } else if (choice == "exclude") {
    output$ERP[as.logical(output$Outlier_ExtremeEEG)] = NA
    }

  output$ERP[as.logical(output$Outlier)] = NA


# no Change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
