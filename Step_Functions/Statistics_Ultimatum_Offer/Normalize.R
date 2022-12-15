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
  # (2) Apply Normalization to Personality Data (only one value per Subject!)
  # (3) Apply Normalization to EEG Data
  # (4) Apply Normalization to RTs/Acceptance Rates
  
  
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
    Relevant_Collumns =  colnames(output)[grep(c("Personality_|Covariate_"), names(output))]
    Relevant_Collumns = Relevant_Collumns[!grepl("Covariate_Gender",Relevant_Collumns)]
    Personality = unique(output[,c("ID", Relevant_Collumns )])
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
    # (3) Normalize EEG data per component
    #########################################################
    # Get Grouping Variables from previous step
    GroupingVariables = input$stephistory[["GroupingVariables"]]
        ChecknotNormal =   output %>%
      filter(!is.na("EEG_Signal")) %>%
      filter(Component == "FRN") %>%
      group_by_at(GroupingVariables) %>%
      summarise(notNormal = check_normality(EEG_Signal))
    
    if (any(ChecknotNormal$notNormal)) {
    output$EEG_Signal[output$Component == "FRN"] = normalize_data(output$EEG_Signal[output$Component == "FRN"], choice)
    }
    

    
    #########################################################
    # (4) Normalize RTs
    #########################################################
    RTs = output[,c("ID", "Behav_RT", "Offer", "Response" )]
    RTs = RTs[!RTs$Response == "BothChoices",]
    RTs = RTs[!duplicated(RTs),]
    RTs = RTs[!RTs$Response == "None",]
    
    # Remove from output file
    output = output[,-which(names(output) %in% "Behav_RT")]
    
    
    # Check if cells are not normally distributed
    ChecknotNormal =   RTs %>%
      filter(!is.na("Behav_RT")) %>%
      group_by_at(c("Offer", "Response"), drop = TRUE) %>%
      summarise(notNormal = check_normality(Behav_RT))
    
    if (any (ChecknotNormal$notNormal)){ 
      RTs$Behav_RT = normalize_data(RTs$Behav_RT, choice)
    }
    
    # Merge again with output
    output =  merge(output,  RTs, by = c("ID", "Offer", "Response"),
                    all.x = TRUE,  all.y = FALSE )
    
    #########################################################
    # (5) Normalize Acceptance Rates
    #########################################################
    ACCs = output[,c("ID", "Behav_AcceptanceRate", "Offer" )]
    ACCs = ACCs[!is.na(ACCs$Behav_AcceptanceRate),]
    ACCs = ACCs[!duplicated(ACCs),]
    # Remove from output file
    output = output[,-which(names(output) %in% "Behav_AcceptanceRate")]
    
    
    # Check if cells are not normally distributed
    ChecknotNormal =   ACCs %>%
      filter(!is.na("Behav_AcceptanceRate")) %>%
      group_by_at(c("Offer")) %>%
      summarise(notNormal = check_normality(Behav_AcceptanceRate))
    
    if (any (ChecknotNormal$notNormal)){ 
      ACCs$Behav_AcceptanceRate = normalize_data(ACCs$Behav_AcceptanceRate, choice)
    }
    
    # Merge again with output
    output =  merge(output,  ACCs, by = c("ID", "Offer"),
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