Normalize = function(input = NULL, choice = NULL) {
  StepName = "Normalize"
  Choices = c("Rankit", "Log", "None")
  Order = 11
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:

  # Handles all Choices listed above 
  # Tests if Data should be normalized or not (is grouped for Analyses, Tasks, Condition, etc.)
  # (1) Initialize Normalizing Functions
  # (2) Apply Normalization to Personality Data/IQ (only one value per Subject!)
  # (3) Apply Normalization to EEG Data
  # (4) Apply Normalization to RTs/ACCs
  
  
  if (choice != "None") {
    #########################################################
    # (1) Initialize
    #########################################################
    
    # Test if Array is not normally distributed
    check_normality = function (x) {
      NotNormal = ks.test(x, "pnorm")$p.value < 0.01
      return(NotNormal)
    }
    
    # Normalize Array depending on Choice above
    normalize_data = function(data, choice) {
      # Check if not normally distributed
      # Apply Rankit
      if (choice == "Rankit")  {
        data = unlist(data)
        r = rank(data, na.last = "keep", ties.method = ("average"))
        n = sum(!is.na(r))
        x = (r - 1 / 2)/n
        normal = qnorm(x, mean = mean(data,na.rm = TRUE), sd = sd(data,na.rm = TRUE), lower.tail = TRUE, log.p = FALSE)
        
        # Apply Log
      } else if (choice == "Log")  {
        # Add Constant to each collum to make all values > 0
        Min = min(data, na.rm = TRUE)
        if (Min<=0) { data = data + abs(Min) +1 }
        normal = log(data)
      } 
      return (normal)
    }
    
    #########################################################
    # (2) Normalize Personality Variables 
    #########################################################
    # this is done across subjects and there should be only one value per Subject when normalizing
    Relevant_Collumns =  colnames(output)[grep(c("Covariate_|Personality_"), names(output))]
    Relevant_Collumns = Relevant_Collumns[!grepl("Covariate_Gender",Relevant_Collumns)]
    Personality = output[,c("ID", Relevant_Collumns )] %>% distinct 
    # Remove from output file
    output = output[,-which(names(output) %in% Relevant_Collumns)]
    
    # Check Which ones need to be normalized
    if (length(Relevant_Collumns)>1) {
      Not_Normal = sapply(Personality[,Relevant_Collumns], function(col) check_normality(col)) 
      Not_Normal_CollumnNames = Relevant_Collumns[as.logical(Not_Normal)]
    } else {
      Not_Normal = check_normality(Personality[,Relevant_Collumns])
      Not_Normal_CollumnNames = Relevant_Collumns[as.logical(Not_Normal)]
    }
    
    
    # Apply Normalization
    if (length(Not_Normal_CollumnNames)>1) {
      Personality[,Not_Normal_CollumnNames] = lapply(Personality[,Not_Normal_CollumnNames], function(col) normalize_data(col, choice))
    } else {
      Personality[,Not_Normal_CollumnNames] = normalize_data(Personality[,Not_Normal_CollumnNames], choice)
    }
    
    # Merge again with output
    output =  merge(output,  Personality, by = c("ID"),
                    all.x = TRUE,  all.y = FALSE )
    
    
    #########################################################
    # (3) Normalize EEG data per Task and Measure
    #########################################################
    # Get Grouping Variables from previous step
    output_EEG = output[output$Component == "Ne/c",]
    ChecknotNormal =   output_EEG %>%
      filter(!is.na("EEG_Signal")) %>%
      group_by(Task, Condition, GMA_Measure) %>%
      summarise(notNormal = check_normality(EEG_Signal)) %>%
      group_by(Task,  GMA_Measure) %>%
      summarise(notNormal = any(notNormal)) %>%
      filter(notNormal)
    
    # Normalize always only within Task, Component, GMA_Measure, but across Electrodes/Condition
    for (inn in 1:nrow(ChecknotNormal)) {
      idx =  output_EEG$Task == ChecknotNormal$Task[inn] &
        output_EEG$GMA_Measure == ChecknotNormal$GMA_Measure[inn] 
      output_EEG$EEG_Signal[idx] = normalize_data(output_EEG$EEG_Signal[idx], choice)
    }
    
    
    
    #########################################################
    # (3) Normalize Behav data per Task and Component
    #########################################################
    # Get Grouping Variables from previous step
    output_Behav = output[output$Component == "RTDiff" |output$Component == "post_ACC",]
    ChecknotNormal =   output_Behav %>%
      filter(!is.na("Behav")) %>%
      group_by(Task, Condition, Component) %>%
      summarise(notNormal = check_normality(Behav)) %>%
      group_by(Task, Component) %>%
      summarise(notNormal = any(notNormal)) %>%
      filter(notNormal)
    
    # Normalize always only within Task, Component, GMA_Measure, but across Electrodes/Condition
    for (inn in 1:nrow(ChecknotNormal)) {
      idx =  output_Behav$Task == ChecknotNormal$Task[inn] &
        output_Behav$Component == ChecknotNormal$Component[inn] 
      output_Behav$Behav[idx] = normalize_data(output_Behav$Behav[idx], choice)
    }
    
    
  # Combine again
    output = bind_rows(output_EEG, output_Behav)
    
  }
  
  
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}