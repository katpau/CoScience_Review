GMA_Fit = function(input = NULL, choice = NULL) {
  StepName = "GMA_Fit"
  Choices = c("all", "0.7 corr", "0.8 corr", "0.9 corr")
  Order = 3
  output = input$data
  
  ## Contributors
  # Last checked by OCS 02/24
  # Planned/Completed Review by:

  # Handles all Choices listed above 
  # Filters for all successful GMA fits with a PDF to data correlation oefficient equal to
  # or above the threhold or uses all fits.

  if (grepl("corr", choice)) {
    minCorr <- as.numeric(str_split(choice, " ")[[1]][1])
  } else {
    minCorr <- 0
  }

  # Since we cannot use data of a failed GMA, we already drop them here
  output <- output %>%
    group_by(subject, task, channel) %>%
    filter(!any(is.na(shape)) & all(fit == 1) & all(r > minCorr)) %>%
    ungroup()


  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
