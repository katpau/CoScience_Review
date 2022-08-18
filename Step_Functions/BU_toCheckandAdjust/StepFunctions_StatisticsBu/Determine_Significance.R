Determine_Significance = function(input = NULL, choice = NULL) {
    StepName = "Determine_Significance"
Choices = c("Holm", "Bonferroni", "None")

#Adjust here below: make sure the script handles all choices (/choice/) defined above. Data is accessible via input$data

# 


## Restructure Input so multiple Conditions!
dataset = input$data
dataset$Condition = as.factor(dataset$Condition)
dataset = dataset %>% separate(Condition, c("Accuracy", "Experimenter"), sep ="_")
dataset$Accuracy = as.factor(dataset$Accuracy)
dataset$Experimenter = as.factor(dataset$Experimenter)
if (input$stephistory$Covariate == "None"){
Model_Result = lm(ERP ~ Accuracy*Experimenter*Personality_Variable, data = dataset)
} else if (input$stephistory$Covariate == "Age_MF") {
Model_Result = lm(ERP ~ Accuracy*Experimenter*Personality_Variable + Age, data = dataset)
} else {
  Model_Result = lm(ERP ~ Accuracy*Experimenter*Personality_Variable*Covariate, data = dataset)  
}

Estimates =  cbind(standardize_parameters(Model_Result), summary(Model_Result)$coefficients[,4])
Estimates = Estimates[-1,-3]
colnames(Estimates)[5] = "p_Value"


comparisons = length(Estimates) # or set
if (choice == "Holmes"){
  Estimates$p_Value = p.adjust(Estimates$p_Value, method = "holm", n = comparisons)
}  else if (choice == "Bonferroni"){
  Estimates$p_Value = p.adjust(Estimates$p_Value, method = "bonferroni", n = comparisons)
}

#  save as txt
input$stephistory$Final_File_Name
write.csv(Estimates,paste0(input$stephistory$Final_File_Name, ".csv"), row.names = FALSE)

#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = Estimates,
    stephistory = stephistory
  ))
}
