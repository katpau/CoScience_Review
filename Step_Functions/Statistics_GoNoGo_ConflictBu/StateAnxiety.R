StateAnxiety = function(input = NULL, choice = NULL) {
StepName = "StateAnxiety"
Choices = c("AV", "Anxiety")
Order = 10
output = input$data

## Contributors
# Last checked by KP 12/22
# Planned/Completed Review by:


# Handles how StateAnxiety is defined
# (1) Preparations: loading File and selecting Data
# (2) Scoring: Depending on choice
# (3) Export: Combine with data

#########################################################
# (1) Preparations 
#########################################################
# Read Behavioural Data
BehavFile = paste0(input$stephistory["Root_Behavior"], "task_SR_beh.csv")
BehavData = read.csv(BehavFile, header = TRUE)

# keep only Ratings during GoNoGo Task
BehavData = BehavData[BehavData$Run == 2 | BehavData$Run == 3 ,]


#########################################################
# (2) Scoring 
#########################################################
if (choice == "AV") {
  BehavData$StateAnxiety = (BehavData$anxious  + abs((BehavData$relaxed - 8))) /2
} else {
  BehavData$StateAnxiety = BehavData$anxious
}


#########################################################
# (3) Export 
#########################################################
# Rearrange
BehavData = BehavData[,c("ID", "Run", "StateAnxiety")]

# Instead of Run use Condition (read from GoNoGo Behavior File earlier)
RelaxedFirst = output$ID[output$OrderInstr %in% "relaxed_first"]
SpeedFirst = output$ID[output$OrderInstr %in% "speed_accuracy_first"]

BehavData$Condition_Instruction[BehavData$ID %in% RelaxedFirst & BehavData$Run %in% 2 ] = "Relaxed"
BehavData$Condition_Instruction[BehavData$ID %in% RelaxedFirst & BehavData$Run %in% 3 ] = "Speed"
BehavData$Condition_Instruction[BehavData$ID %in% SpeedFirst & BehavData$Run %in% 2 ] = "Speed"
BehavData$Condition_Instruction[BehavData$ID %in% SpeedFirst & BehavData$Run %in% 3 ] = "Relaxed"



# Merge with data
output =  merge(
  output,
  BehavData[,c("ID", "Condition_Instruction", "StateAnxiety")],
  by = c("ID", "Condition_Instruction"),
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
