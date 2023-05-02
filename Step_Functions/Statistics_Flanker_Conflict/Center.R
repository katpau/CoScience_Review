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
  
  # CK: we might have two conditions here
    # (1) center level 1 predictors within cluster (CWC), i.e. group mean centering
          #  demand, electrode, block
    sub.rt$demand.cwc <- sub.rt$demand - ave(sub.rt$demand, sub.rt$id_t2, FUN = function(x) mean(x, na.rm = T))
    # (2) center level 2 predictors at the grand mean (CGM)
          # CEI, COM, ESC, fluidIntelligence, age, gender, depression, anxiety, O, C, E, A, N
    sub.rt$CEI.cgm <- scale(sub.rt$CEI, scale = F)
  
    
  
  # (1) Center Personality Variables
  
  if (choice == "Centered")  {
    
    #########################################################
    # (1) Center Personality Variables
    #########################################################
    
    # this is done across all subjects and there should be only one value per Subject when normalizing
    Relevant_Collumns =  names(output)[grep(c("Personality_|Covariate_|IST"), names(output))]
    Relevant_Collumns = Relevant_Collumns[!grepl("Covariate_Gender",Relevant_Collumns)]
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
