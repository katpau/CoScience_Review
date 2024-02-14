Normalize = function(input = NULL, choice = NULL) {
  StepName = "Normalize"
  Choices = c("Rankit", "Log", "None")
  Order = 11
  output = input$data

  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by: CK 5/23
  
  # Handles all Choices listed above 
  # Tests if Data should be normalized or not (is grouped for Analyses, Tasks, Condition, etc.)
  # (1) Initialize Normalizing Functions
  # (2) Apply Normalization to Personality Data/IQ (only one value per Subject!)
  # (3) Apply Normalization to EEG Data
  # (4) Apply Normalization to RTs
  
  
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
        # Add Constant to each column to make all values > 0
        Min = min(data, na.rm = TRUE)
        if (Min<=0) { data = data + abs(Min) +1 }
        normal = log(data)
      } 
      return (normal)
    }
    
    #########################################################
    # (2) Normalize Personality Variables 
    #########################################################
    Personality = input$stephistory$output_Personality 
    Relevant_Collumns =  colnames(Personality)[grep(c("Personality_|Covariate_"), names(Personality))] 

    Not_Normal = sapply(Personality[,Relevant_Collumns], function(col) check_normality(col)) 
    Not_Normal_CollumnNames = Relevant_Collumns[as.logical(Not_Normal)]

    
    
    # Apply Normalization
    if (length(Not_Normal_CollumnNames)>1) {
      Personality[,Not_Normal_CollumnNames] = lapply(Personality[,Not_Normal_CollumnNames], function(col) normalize_data(col, choice))
    } else if ((length(Not_Normal_CollumnNames)==1)) {
      Personality[,Not_Normal_CollumnNames] = normalize_data(Personality[,Not_Normal_CollumnNames], choice)
    }
    
    # Save for next Step
    input$stephistory$output_Personality = Personality
    
    
    #########################################################
    # (3) Normalize EEG data per component
    #########################################################
    # Get Grouping Variables from previous step
    GroupingVariables = input$stephistory[["GroupingVariables"]]
    
    for (iComponent in c("FRN", "FMT")) {
    ChecknotNormal =   output %>%
      filter(Component == iComponent) %>%
      group_by_at(GroupingVariables) %>%
      summarise(notNormal = check_normality(EEG_Signal))
    
    if (any(ChecknotNormal$notNormal)) {
    output$EEG_Signal[output$Component == iComponent] = normalize_data(output$EEG_Signal[output$Component == iComponent], choice)
    }
    }

    
    #########################################################
    # (4) Normalize RTs 
    #########################################################
    output_RT = output[output$Component == "Behav",] 
    output_RT = output_RT[!is.na(output_RT$RT), ]    
    
    # Check if cells are not normally distributed
    ChecknotNormal =   output_RT %>%
      filter(!is.na("RT")) %>%
      group_by_at(c("Offer" , "Component" )) %>%
      summarise(notNormal = check_normality(RT))
    
    if (any (ChecknotNormal$notNormal)){ 
      output_RT$RT = normalize_data(output_RT$RT, choice)
    }
    
    # merge (LONG FORMAT) with full dataset
    output = bind_rows(output[!output$Component == "Behav",],
                       output_RT)  
    

    
  }
  
  
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}