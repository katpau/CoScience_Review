Outliers_ACC <- function(input = NULL, choice = NULL) {
  StepName <- "Outliers_ACC"
  Choices <- c("Applied", "None")
  Order <- 7
  output <- input$data

  ## Contributors
  # Original last checked by KP 12/22
  # Last checked by OCS 02/25
  # Planned/Completed Review by:

  # if ACC is available, scan for performance in task
  # identifies and removes outliers based on previous criteria (thresholds)
  # (1) Get previous choices about threshold and prepare function
  # (2) Identify and Remove outliers


  #########################################################
  # (1) Preparations
  #########################################################

  if (choice == "Applied") {
    # Read Behavioural Data of both tasks for ACC
    # Specifically, for the GMA analyses, we only use a part of the trials to
    # determine the accuracy: for Flanker, only the trials without a presenter
    # present (i.e., absent; 3 blocks of 96 trials) and for Go/NoGo, speeded
    # and not the relaxed trials (i.e., Speed; 1 block of 252 trials).
    # The trial accuracy will be calculated for all trials – regardless of the
    # RT window (i.e., responses faster than 100 ms and slower than 800 ms will
    # still be included).
    # The accuracy threshold for exclusions will not be use from Outliers_Threshold
    # (e.g., 3.29 SD) but determined by estimating the chance accuracy for the given
    # trials in a binomial test.

    # Returns the upper confidence level of the chance probability above which random
    # guesses are unlikely (alpha = 5%) for a given probability of a correct response.
    chance_level <- function(n_trials, p_correct, conf_level = 0.95) {
      expected_correct <- n_trials * p_correct
      # Compute confidence interval for chance performance
      chance_CI <- binom.test(x = expected_correct, n = n_trials, p = p_correct, conf.level = conf_level)
      return(chance_CI$conf.int[2] * 100)
    }
    

    Behav_Flanker <- read.csv(paste0(
      input$stephistory["Root_Behavior"],
      "task_Flanker_beh.csv"
    ), header = TRUE) %>%
      # RT window NOT used:
      # filter(RT >= 0.1 & RT <= 0.8) %>%
      filter(ExperimenterPresence == "absent") %>%
      group_by(ID) %>%
      # Accuracy of all trials in the data NOT used:
      # summarize(Task = "Flanker", TaskPerf = mean(TaskPerf))
      summarize(
        Task = "Flanker",
        TaskPerf = sum(Accuracy) / n() * 100,
        chance_tresh = chance_level(n_trials = n(), p_correct = 0.5)
      )

    Behav_GoNoGo <- read.csv(paste0(
      input$stephistory["Root_Behavior"],
      "task_GoNoGo_beh.csv"
    ), header = TRUE) %>%
      # RT window NOT used:
      # filter(RT >= 0.1 & RT <= 0.8) %>%
      filter(InstructionCondition == "Speed") %>%
      group_by(ID) %>%
      # Accuracy of all trials in the data NOT used:
      # summarize(Task = "GoNoGo", TaskPerf = mean(TaskPerf))
      summarize(
        Task = "GoNoGo",
        TaskPerf = sum(Accuracy) / n() * 100,
        chance_tresh = chance_level(n_trials = n(), p_correct = 2/3)
      )

    BehavData <- bind_rows(Behav_Flanker, Behav_GoNoGo)

    # Set up outlier function based on Choice on Thresholds, takes the corresponding values (central tendency, width),
    # returns 0&1, 1 for the values exceeding the acceptable range
    outlierfunction <- function(Threshold, data) {
      Outliers <- numeric(length(data))
      Outliers[!is.na(data) & data < Threshold] <- 1
      return(Outliers)
    }


    #########################################################
    # (2) Identify Outliers
    #########################################################
    BehavData <- BehavData %>%
      distinct() %>%
      reframe(
        ID = ID,
        Task = Task,
        TaskPerf = TaskPerf,
        Outliers_TaskPerf = outlierfunction(chance_tresh, TaskPerf)
      )


    # merge with full dataset
    output <- merge(output,
      BehavData,
      by = c("ID", "Task"),
      all.x = TRUE, all.y = FALSE
    )


    # Remove EEG data if Accuracy was below chance
    output$EEG_Signal[as.logical(output$Outliers_TaskPerf)] <- NA

    # Remove subjects with incomplete cases
    output <- output %>%
      group_by(ID, Task) %>%
      filter(!any(is.na(EEG_Signal))) %>%
      ungroup()
  } else {
    # do nothing
  }


  # No change needed below here - just for bookkeeping
  stephistory <- input$stephistory
  stephistory[StepName] <- choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
