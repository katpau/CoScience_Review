RT = function(input = NULL, choice = NULL) {
  StepName = "RT"
  Choices = c("AV", "trimmedAV", "Median")
  Order = 9.2
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:

  # Handles how RTs are defined
  # Handles all Choices listed above as well as choices from previous Step 
  # (1) Get Choices abotu which Trials to be included, from previous Steps and load Data
  # (2) Drop Trials based on selection criteria
  # (3) Calculate RT based on choice
  # (4) Calculate Acceptance Rates
  # (5) Merge for Export
  
  
  #########################################################
  # (1) Preparations 
  #########################################################
  # Collect all Choices
  Select_Trials_RT = unlist(input$stephistory["Select_Trials_RT"])
  
  
  # Read Behavioural Data
  BehavFile = paste0(input$stephistory["Root_Behavior"], "task_UltimatumGame_beh.csv")
  BehavData = read.csv(BehavFile, header = TRUE)
  BehavData$RT = as.numeric(BehavData$RT)
  
  #########################################################
  # (2) Drop Trials 
  #########################################################
  # only trials with response? what about time out?
  
  if (Select_Trials_RT == "RT") {
    BehavData = BehavData[BehavData$RT >= 0.1,] 
  }
  
  #########################################################
  # (3) Calculate RT
  #########################################################
  
  if (choice == "AV") {
  RT_Data = BehavData %>%
    group_by(ID, Offer, Response) %>%
    summarise(Behav_RT = mean(RT, na.rm =TRUE)) %>%
    ungroup() %>%
    filter(!is.na(Response))%>%
    complete(ID, Offer, Response, fill = list(NA))
  
  } else if (choice == "trimmedAV") {
    RT_Data = BehavData %>%
      group_by(ID, Offer, Response) %>%
      summarise(Behav_RT = mean(RT, trim = 0.05, na.rm =TRUE))%>%# lowest and highest 5 %
      ungroup() %>%
      filter(!is.na(Response))%>%
      complete(ID, Offer, Response, fill = list(NA))
                
    
  } else if (choice == "Median") {
    RT_Data = BehavData %>%
      group_by(ID, Offer, Response) %>%
      summarise(Behav_RT = median(RT)) %>%
      ungroup() %>%
      filter(!is.na(Response))%>%
      complete(ID, Offer, Response, fill = list(NA))
                
  }
  
  RT_Data$Component = "RT"

  
  #########################################################
  # (4) Calculate ACC_Data
  #########################################################
  ACC_Data = BehavData %>%
    group_by(ID, Offer) %>%
    summarise(Behav_AcceptanceRate = sum(Response == "Accept") / length(Response)*100) 
  ACC_Data$Component = "AcceptanceRate"
  ACC_Data$Response = "BothChoices"
  
  #########################################################
  # (5) Export [Add as new Rows]
  #########################################################
  Data_to_ADD = output[,c("ID", "Offer",  "Lab", "Experimenter",  colnames(output)[grepl("Covariate_|Personality_", colnames(output))])]
  RT_Data = merge(
    RT_Data, 
    Data_to_ADD[!duplicated(Data_to_ADD),],
    by =  c("ID", "Offer" ), 
    all.x = FALSE,
    all.y = FALSE
  )
  
  ACC_Data = merge(
    ACC_Data, 
    Data_to_ADD[!duplicated(Data_to_ADD),],
    by =  c("ID", "Offer" ),
    all.x = FALSE,
    all.y = FALSE
  )
  
  # Merge with data
  output = bind_rows(output, RT_Data,ACC_Data)
 
  
  
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
