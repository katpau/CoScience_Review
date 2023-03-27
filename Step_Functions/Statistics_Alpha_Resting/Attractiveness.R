Attractiveness = function(input = NULL, choice = NULL) {
  StepName = "Attractiveness"
  Choices = c("Diff_subj", "Diff_AV", "Attractiveness_subj", "Attractiveness_AV", "Attractiveness_Median", "MedianSplit")
  Order = 4.2
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:

  # Handles how Attractiveness Score is defined
  # (1) Preparations: loading File and selecting Data
  # (2) Scoring: Depending on choice
  # (3) Export: Combine with data
  
  
  
  #########################################################
  # (1) Preparations 
  #########################################################
  # Read Behavioural Data
  BehavFile = paste0(input$stephistory["Root_Behavior"], "task_Ratings_beh.csv")
  BehavData = read.csv(BehavFile, header = TRUE, sep = ",")
  
  # keep only Ratings of Experimenter
  BehavData = BehavData[BehavData$Rated_Person == "Experimenter",]
  
  
  #########################################################
  # (2) Scoring 
  #########################################################
  # In Any case, median split is performed for hypothesis 5 (keep as seperate collumn)
  #Rating of experimenter attractiveness, median across subjects
  MedianSplit = BehavData %>% 
    group_by(ExperimenterID) %>%
    summarise(Median_Attractiveness = median(attractiveness))

  
  
  
  if (choice == "Diff_subj") {
    # Difference score of attractiveness minus assertiveness, for each subject individually.
    BehavData$Behav_Attractiveness = BehavData$attractiveness - BehavData$assertiveness
    BehavData = BehavData[,c("ID", "ExperimenterID", "Behav_Attractiveness", "Experimenter_Sex")]
    
  } else if (choice == "Diff_AV") {
    #Difference score of attractiveness minus assertiveness, average across subjects
    BehavData$Behav_Attractiveness = BehavData$attractiveness - BehavData$assertiveness
    AverageScores = BehavData %>% 
      group_by(ExperimenterID) %>%
      summarise(Behav_Attractiveness = mean(Behav_Attractiveness))
    BehavData = merge(BehavData[,c("ID", "ExperimenterID", "Experimenter_Sex")],
                      AverageScores,
                      by ="ExperimenterID")  
    
  } else if (choice == "Attractiveness_subj") {
    #Ratings of experimenter attractiveness, for each subject individually
    BehavData = BehavData[,c("ID", "ExperimenterID", "attractiveness", "Experimenter_Sex")]
    colnames(BehavData)[3] = "Behav_Attractiveness"
    
  } else if (choice == "Attractiveness_AV") {
    #Rating of experimenter attractiveness, average across subjects.
    AverageScores = BehavData %>% 
      group_by(ExperimenterID) %>%
      summarise(Behav_Attractiveness = mean(attractiveness))
    BehavData = merge(BehavData[,c("ID", "ExperimenterID", "Experimenter_Sex")],
                      AverageScores,
                      by ="ExperimenterID")  
    
    
  } else if (choice == "Attractiveness_Median") {
    #Rating of experimenter attractiveness, median across subjects
    AverageScores = BehavData %>% 
      group_by(ExperimenterID) %>%
      summarise(Behav_Attractiveness = median(attractiveness))
    BehavData = merge(BehavData[,c("ID", "ExperimenterID", "Experimenter_Sex")],
                      AverageScores,
                      by ="ExperimenterID")  
    
  } else if (choice == "MedianSplit") {
    #Assigning participants value to highly or low attractive experimenters: Dependent on median
    #split of all ratings across subjects
    AverageScores = BehavData %>% 
      group_by(ExperimenterID) %>%
      summarise(Attractiveness = mean(attractiveness))
    MedianAttractiveness = median(AverageScores$Attractiveness)
    AverageScores$Split = NA
    AverageScores$Split[AverageScores$Attractiveness<=MedianAttractiveness] = 0
    AverageScores$Split[AverageScores$Attractiveness>MedianAttractiveness] = 1
    AverageScores$Behav_Attractiveness = AverageScores$Split
    BehavData = merge(BehavData[,c("ID", "ExperimenterID", "Experimenter_Sex")],
                      AverageScores[,c("ExperimenterID", "Behav_Attractiveness")],
                      by ="ExperimenterID")  
    
  }

  # Add Median Split
  BehavData = merge(BehavData,
                    MedianSplit[,c("ExperimenterID", "Median_Attractiveness")],
                    by ="ExperimenterID")  
  
  #########################################################
  # (3) Export 
  #########################################################
  # Merge with data
  output =  merge(
    output,
    BehavData,
    by = c("ID"),
    all.x = TRUE,
    all.y = FALSE
  )
  
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
