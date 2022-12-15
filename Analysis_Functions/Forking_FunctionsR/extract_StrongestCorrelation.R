

###########################
# For Hypothesis Set 2, the tests are conducted on the Condition of the strongest correlation (if it was significant, otherwise the main effect)
extract_StrongestCorrelation = function (SignTest, Task, AnalysisPhase, additional_Factors_Name, Extracted_Data, Correlations_Within_Conditions, Average_Across_Conditions) {
  # This Function takes SignTest (the test of the interaction term with Condition1), if it is significant, the strongest correlation is found and exported
  if (!is.na(SignTest)) {
    if (SignTest < 0.05){
      Subset = Correlations_Within_Conditions[which(Correlations_Within_Conditions$Task == Task &
                                                      Correlations_Within_Conditions$AnalysisPhase == AnalysisPhase),]
      
      # only take frontal values!
      if ("Localisation" %in% additional_Factors_Name || "Elecrode" %in% additional_Factors_Name) {
        Subset = Subset[which(Subset$Localisation == "Frontal"),]}
      
      # Find Condition1 with highest correlation
      Idx = which.max(Subset$Correlation_with_Personality)
      # Take only data from that Condition1
      Extracted_Data = rbind(Extracted_Data, 
                             output[output$Task == Task &
                                      output$AnalysisPhase == AnalysisPhase &
                                      output$Condition1 == Subset$Condition1[Idx],
                                    names(Average_Across_Conditions)])
      
    } else {
      # if no interaction significant, simply take average
      Extracted_Data = rbind(Extracted_Data, 
                             Average_Across_Conditions[which(Average_Across_Conditions$Task == Task &
                                                               Average_Across_Conditions$AnalysisPhase == AnalysisPhase),] )
    }} else {
      # if no interaction significant, simply take average
      Extracted_Data = rbind(Extracted_Data, 
                             Average_Across_Conditions[which(Average_Across_Conditions$Task == Task &
                                                               Average_Across_Conditions$AnalysisPhase == AnalysisPhase),] )
      
    }
  return(Extracted_Data)
}
