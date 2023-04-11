Center = function(input = NULL, choice = NULL) {
StepName = "Center"
Choices = c("Centered", "None")
Order = 12
output = input$data

## Contributors
# Last checked by KP 12/22
# Planned/Completed Review by: Cassie (CAS) 4/23

# Handles all Choices listed above 
# Normalizes the predictors (e.g. behavioral and personality) data within all conditions
# (1) Center Personality Variables
# (1) Center Behavioural Predictors

if (choice == "Centered")  {
  
  
  #########################################################
  # (1) Center Personality Variables, Mood Ratings and Attractiveness Ratings
  #########################################################

# this is done across all subjects and there should be only one value per Subject when normalizing
Relevant_Collumns =  c(names(output)[grep(c("Personality_|Covariate_|Behav_"), colnames(output))])
Personality = unique(output[,c("ID", Relevant_Collumns )])
# Remove from output file
output = output[,-which(names(output) %in% Relevant_Collumns)]

# Center
if (length(Relevant_Collumns)>1) {
Personality[,Relevant_Collumns] = lapply(Personality[,Relevant_Collumns], function(col) scale(col, scale = FALSE))
} else {
  Personality[,Relevant_Collumns] = scale(Personality[,Relevant_Collumns], scale =FALSE)
}

# Merge again with output
output =  merge(output,  Personality, by = c("ID"),
                all.x = TRUE,  all.y = FALSE )
}


#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
