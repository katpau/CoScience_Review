BehavCovariate = function(input = NULL, choice = NULL) {
StepName = "BehavCovariate"
Choices = c("pleasant_arousal_perSub", "pleasant_perSub", "pleasant_arousal_av")
Order = 5
output = input$data

# Handles all Choices listed above to add behavioral covariate to data
# (1) Read and Restructure Data
# (2) Extract Ratings and combine (either per Subject/Condition, Arousal or/and Valence, or Group Average by condition)



#########################################################
# (1) Preparations 
#########################################################
# Read Behavioural Data
BehavFile = paste0(input$stephistory["Root_Behavior"], "task_StroopRating_beh.csv")
BehavData = read.csv(BehavFile, header = TRUE, sep = ";")


# Restructure Data so that the Information from  "Condition" is split into relevant collumns
output = output %>%
  separate(Condition, sep = "_", into = c("Task", "AnalysisPhase", "Condition", "Condition2"))
output$Condition = gsub("post", "", output$Condition)
# For Stats later important that resting has a second condition that is not NA 
output$AnalysisPhase[output$Task == "Resting"] = "NA"


#########################################################
# (2) Extract Ratings dependent on Input 
#########################################################

# Add Pleasure Ratings to output
if (choice != "pleasant_arousal_av") {
  # Get Pleasure Ratings per Subject and Condition
  Pleasure = BehavData[BehavData$Dimension == "Valence", c(1, 2, 4)]
  output =  merge(
    output,
    Pleasure,
    by = c("ID", "Condition"),
    all.x = TRUE,
    all.y = FALSE
  )
  colnames(output)[colnames(output) == "Response"] = "Behav_Pleasure"
  

  if (choice == "pleasant_arousal_perSub") {
    # Add Arousal Ratings
    Arousal = BehavData[BehavData$Dimension == "Arousal", c(1, 2, 4)]
    output =  merge(
      output,
      Arousal,
      by = c("ID", "Condition"),
      all.x = TRUE,
      all.y = FALSE
    )
    colnames(output)[colnames(output) == "Response"] = "Behav_Arousal"
  }
  
  
  # Instead of Single Subject Value use Average
} else if (choice == "pleasant_arousal_av") {
  Group_Mean = BehavData %>%
    group_by(Condition, Dimension) %>%
    summarise_at(vars(Response), mean)
  
  output =  merge(
    output,
    Group_Mean[Group_Mean$Dimension == "Arousal", ],
    by = c("Condition"),
    all.x = TRUE,
    all.y = FALSE
  )
  colnames(output)[colnames(output) == "Response"] = "Behav_Arousal"
  
  output =  merge(
    output,
    Group_Mean[Group_Mean$Dimension == "Valence", ],
    by = c("Condition"),
    all.x = TRUE,
    all.y = FALSE
  )
  colnames(output)[colnames(output) == "Response"] = "Behav_Pleasure"
  
  # Drop dimension collumns
  output= output[,-which(grepl("Dimension", names(output)))]
}


# Make sure every Variable is in correct format
NumericVariables = c(names(output)[grepl("Behav_", names(output))])
output[NumericVariables] = lapply(output[NumericVariables], as.numeric)



#No change needed below here - just for bookkeeping
stephistory = input$stephistory
stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
