Treat_Outliers = function(input = NULL, choice = NULL) {
StepName = "Treat_Outliers"
Choices = c("Exclude", "Replace")
Order = 10
output = input$data

# Handles all Choices listed above 
# Replace only applicable for Outliers if EEG is out of range. 
# For other reasons (ACC, Dataquality, MinEpochs etc) ERP must be excluded
# (1) Find Values that exceed Value and replace with Min/Max
# (2) Replace All Other Outliers



#########################################################
# (1) Replace EEG Signal that exceeds thresholds
#########################################################
if (input$stephistory["Outliers_EEG"] != "none") {
  if (choice == "Replace")  {
  ExceedMin = which(output$EEG_Signal<output$Min)
  ExceedMax = which(output$EEG_Signal>output$Max)
  output$EEG_Signal[ExceedMin] =   output$Min[ExceedMin]
  output$EEG_Signal[ExceedMax] =   output$Min[ExceedMax]
    } else if (choice == "Exclude") {
    output$EEG_Signal[as.logical(output$Outliers_EEG)] = NA
    }}


#########################################################
# (2) Replace All Other Outliers with NA
#########################################################

# All other Outlier Criteria cause exclusion of value
  output$EEG_Signal[as.logical(output$Outliers_SME)] = NA
  if ("Outliers_ACC" %in% names(output)) {   
    output$EEG_Signal[as.logical(output$Outliers_ACC)] = NA }
  
  # Drop columns
  output = output[,!names(output) %in% c("Outliers_EEG", "Outliers_SME", "Outliers_ACC", "Min", "Max")]



# no Change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
