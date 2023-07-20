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
    # CEI, COM, ESC, fluidIntelligence, age, gender, depression, anxiety, O, C, E, A, N
    # scale(sub.rt$CEI, scale = F)
    
    Personality = input$stephistory$output_Personality 
    Relevant_Collumns =  colnames(Personality)[grep(c("Personality_|Covariate_|IST"), names(Personality))] 
    
    
    # Center
    Personality[,Relevant_Collumns] = lapply(Personality[,Relevant_Collumns], function(col) scale(col, scale = FALSE))
    
    # Merge with output
    output =  merge(output,  Personality, by = c("ID"),
                    all.x = TRUE,  all.y = FALSE )
    
    
    #########################################################
    # (2) Center Within Participant
    #########################################################
    # Create Variable for Block
    output$Block = NA
    output$Block[output$Trial < 96] = 1 
    output$Block[output$Trial >= 96 & output$Trial < 192] = 2 
    output$Block[output$Trial >= 192 & output$Trial < 288] = 3 
    output$Block[output$Trial >= 288 & output$Trial < 384] = 1
    output$Block[output$Trial >= 384 & output$Trial < 480] = 2 
    output$Block[output$Trial >= 480 ] = 3  
    # Should be real blocks or block used in analyses? Some have Experimenter Presence First, others Second half of block??
    
    # (2) center level 1 predictors within cluster (CWC), i.e. group mean centering
    #  demand, electrode, block
    # sub.rt$demand - ave(sub.rt$demand, sub.rt$id_t2, FUN = function(x) mean(x, na.rm = T))
    
    output = output %>% 
      group_by(ID) %>%
      mutate(Congruency_notCentered = Congruency,
             Congruency = scale(Congruency, scale = F),
             Trial = scale(Trial, scale = F),
             Block = scale(Block, scale = F))
    
  }
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
