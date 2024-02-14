Center = function(input = NULL, choice = NULL) {
  StepName = "Center"
  Choices = c("Centered", "None")
  Order = 12
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by: CK 05/23

  # Handles all Choices listed above 
  # Normalizes the predictors (e.g. behavioral and personality) data within all conditions
  

  # (1) Center Personality Variables
  if (choice == "Centered")  {
    
    #########################################################
    # (1) Center Personality Variables
    #########################################################
    # (1) center level 2 predictors at the grand mean (CGM)
    
    Personality = input$stephistory$output_Personality 
    Relevant_Collumns =  colnames(Personality)[grep(c("Personality_|Covariate_"), names(Personality))] 
    
    
    # Center
    Personality[,Relevant_Collumns] = lapply(Personality[,Relevant_Collumns], function(col) scale(col, scale = FALSE))
    
    # Merge with output
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
