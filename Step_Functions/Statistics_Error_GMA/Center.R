Center = function(input = NULL, choice = NULL) {
  StepName = "Center"
  Choices = c("Centered", "None")
  Order = 12
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:

  # Handles all Choices listed above 
  # Normalizes the predictors (e.g. personality) data within all conditions
  # (1) Center Personality Variables
  
  if (choice == "Centered")  {
    #########################################################
    # (1) Center Personality Variables
    #########################################################
    
    # Center Covariates
    if (input$stephistory["Covariate"] != "None" & !grepl("Gender", input$stephistory["Covariate"])) {
    # this is done across all subjects and there should be only one value per Subject when normalizing
    Relevant_Collumns =  names(output)[grep(c("Covariate_"), names(output))]
    Personality = output[,c("ID", Relevant_Collumns )] %>% distinct
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
    
    # [Elisa 17/01/25] Center Personality Variables
    Predictors <- output %>%
      group_by(ID) %>% 
      summarise_at(vars(Personality_MPS_PersonalStandards, Personality_MPS_ConcernOverMistakes), list(~first(.))) %>% 
      ungroup() %>% 
      mutate_at(vars(Personality_MPS_PersonalStandards, Personality_MPS_ConcernOverMistakes),
                list("z" = ~as.numeric(scale(., T, F))))
    
    # [Elisa 17/01/25] Merge  with output
    output =  merge(output,  Predictors[,c("ID","Personality_MPS_PersonalStandards_z", "Personality_MPS_ConcernOverMistakes_z")], by = "ID")
    
  }
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
