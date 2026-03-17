Covariate = function(input = NULL, choice = NULL) {
  StepName = "Covariate"
  Choices = c("None", "Gender_MF", "Gender", "Age_MF", "Age",  "BDI_Depression","BFI_Extraversion","BFI_OpenMindedness","BFI_Conscientiousness","BFI_Agreeableness","BFI_NegativeEmotionality", "Big5_OCEAN")
  Order = 4
  output = input$data
  
  ## Contributors
  # Last checked by KP 12/22
  # Planned/Completed Review by:
  
  # Handles all Choices listed above as well as choices from previous Steps 
  # (Attention Checks Personality, Outliers_Personality, Personality_Variable)
  # (1) Preparation. Get Choices from previous Steps
  # (2) Load Data. Depending on these choices the correct Personality Scoring File is loaded (have been prepared separately)
  # (3) run Choice Relevant Covariate Score , Keep only the relevant Scores 
  # (4) Prepare Output and get Grouping Variables for later steps
  
  
  
  
  
  
  #########################################################
  # (1) Preparations 
  #########################################################
  # Collect all Choices
  
  
  Attention_Checks_Personality_choice = unlist(input$stephistory["Attention_Checks_Personality"])
  Outliers_Personality_choice = unlist(input$stephistory["Outliers_Personality"])
  Personality_Variable_choice = c("Personality_MPS_PersonalStandards","Personality_MPS_ConcernOverMistakes")
  Covariate_choice = choice
  
  
  
  #########################################################
  # (2) Load Data
  #########################################################
  # load correct file, these files have been created separately
  
  QuestFolder = input$stephistory["Root_Personality"]
  if (Attention_Checks_Personality_choice == "Applied") {
    if (Outliers_Personality_choice == "None") {
      QuestionnaireFile = "Personality-Scores-filtered_outliers-notremoved.csv"
    } else {
      QuestionnaireFile = "Personality-Scores-filtered_outliers-removed.csv"
    }
    
  } else {
    if (Outliers_Personality_choice == "None") {
      QuestionnaireFile = "Personality-Scores-unfiltered_outliers-notremoved.csv"
    } else {
      QuestionnaireFile = "Personality-Scores-unfiltered_outliers-removed.csv"
    }
    
  }
  
  ScoreData = read.csv(paste0(QuestFolder, QuestionnaireFile), header = TRUE)
  
  
  
  #########################################################
  # (3) run Choice Relevant Covariate Score 
  #########################################################
  
  # Select only Relevant Covariate
  if (Covariate_choice != "None") {
    if (Covariate_choice == "Gender_MF") {
      Covariate_Variable = "Gender"
    }  else if (Covariate_choice == "Age_MF") {
      Covariate_Variable = "Age"
    } else if (Covariate_choice == "Big5_OCEAN") {
      Covariate_Variable = c(
        "BFI_OpenMindedness",
        "BFI_Conscientiousness",
        "BFI_Agreeableness",
        "BFI_NegativeEmotionality",
        "BFI_Extraversion"
      )
    } else  {
      Covariate_Variable = Covariate_choice
    }
    CovariateData = ScoreData[, c("ID",  paste0("Covariate_",Covariate_Variable))]
    AddCovariate = 1
  } else {AddCovariate = 0}
  
  
  
  #########################################################
  # (4) Prepare Output
  #########################################################

  # quantileMs <- function (p, shape, rate, srate, modeSmp, modeMs) {
  #   frate <- 1000 / srate
  #   # Calculate the measurement sample offset from a given transformation
  #   xOff <- -(modeMs / frate - modeSmp)
  #   qSmp <- qgamma(p, shape = shape, rate = rate)
  #   return((qSmp - xOff) * frate)
  # }

# onset is computed empirically (see below), not with a fixed threshold [elisa 17/02/26]
# output <- output %>% rowwise() %>% mutate(
#    onset_ms = quantileMs(0.025, shape, rate, eeg_srate, mode, mode_ms),
#    offset_ms = quantileMs(0.975, shape, rate, eeg_srate, mode, mode_ms),
#    .after = excess
#  )
  
  # First derivation of Gamma Density [elisa 23/05/25]
  dgamma_prime <- function(x, yscale, shape, rate) {
    yscale * dgamma(x, shape, rate) * ((shape - 1)/x - rate)
  }
  
  # Second derivation of Gamma Density [elisa 23/05/25]  
  dgamma_double_prime <- function(x, yscale, shape, rate)  {
    yscale * dgamma(x, shape, rate) * (((shape - 1)/x - rate)^2 - (shape - 1)/x^2)
  }
  
  
  # Define the third derivative function
  dgamma_triple_prime <- function(x, a, shape, rate) {
    term1 <- ((shape - 1)/x - rate)^3
    term2 <- -3 * (shape - 1)*(shape - 2)/x^3
    term3 <- 3 * (shape - 1)*rate/x^2
    
    y <- a * dgamma(x, shape, rate) * (term1 + term2 + term3)
    
    return(y)
  }
  
  get_onset <- function(a, shape, rate, mode) {
  
    x <- seq(0.1, mode, length.out = 1000)
    y <- dgamma_triple_prime(x, a = a, shape = shape, rate = rate)
    
    # Determine lower limit of search window as first maximum of third derivation
    lower_lim <- x[y == max(y)]
    
    # Determine upper limit of search window as first minimum of third derivation
    upper_lim <- x[y == min(y)]
    
    if (any(is.na(c(lower_lim, upper_lim)))) {
      return(NA)
    } else {
      tryCatch({
        out <- uniroot(dgamma_triple_prime, interval = c(lower_lim, upper_lim), a = a, shape = shape, rate = rate)
        return(out$root)
      }, 
      error = function(x) return(NA))
      
    }
    
  }
  
  # determine empirical offset [elisa 27.08.25]
  
  # determine local maxima of 3rd derivation to limit search window
  find_localmax <- function(y) {
    
    # First differences and their signs
    dy <- diff(y)
    s  <- sign(dy)
    
    # Turning points occur where sign changes in s_use
    turn <- diff(s)
    
    # Local maxima: slope goes + to -  => diff(s_use) == -2
    # Local minima: slope goes - to +  => diff(s_use) == +2
    i_max <- which(turn == -2) + 1L
    return(i_max)
  }
  
  find_localmin <- function(y) {
    
    # First differences and their signs
    dy <- diff(y)
    s  <- sign(dy)
    
    # Turning points occur where sign changes in s_use
    turn <- diff(s)
    
    # Local maxima: slope goes + to -  => diff(s_use) == -2
    # Local minima: slope goes - to +  => diff(s_use) == +2
    i_min <- which(turn == 2) + 1L
    return(i_min)
  }
  
  
  get_offset <- function(a, shape, rate) {
    
    x <- seq(0.1, 300, length.out = 1000)
    y <- dgamma_triple_prime(x, a = a, shape = shape, rate = rate)
    
    # Determine lower limit of search window
    i_max <- find_localmax(y)
    lower_lim <- x[max(i_max)]
    
    # Determine upper limit of search window
    i_min <- find_localmin(y)
    upper_lim <- x[max(i_min)]
    
    if (any(is.na(c(lower_lim, upper_lim)))) {
      return(NA)
    } else {
      tryCatch({
        out <- uniroot(dgamma_triple_prime, interval = c(lower_lim, upper_lim), a = a, shape = shape, rate = rate)
        return(out$root)
      }, 
      error = function(x) return(NA))
      
    }
    
  }
  
 
  # compute mode peak, empirical on- & offset [elisa 23/05/25]  
  output <- output %>%
    rowwise() %>%
    mutate(mode_peak = yscale * dgamma(mode, shape, rate),
          onset_emp_dp = get_onset(a = yscale, shape = shape, rate = rate, mode = mode),
          offset_emp_dp = get_offset(a = yscale, shape = shape, rate = rate) # added 27.08.25 by elisa
    )

  # transform onset, offset and IP slopes from dp to ms
  convert <- output %>% 
    group_by(lab) %>% 
    nest() %>% 
    mutate(model = purrr::map(data, ~lm(mode_ms ~ mode, .)), 
           coefs = purrr::map(model, ~tidy(.))) %>% 
    select(lab, coefs) %>% 
    unnest("coefs") %>% 
    mutate(term = recode(term, "(Intercept)" = "shift", "mode" = "factor")) %>% 
    select(lab, term, estimate) %>% 
    spread(term, estimate)
  
  output <- merge(output, convert, by = "lab")
  
  # convert on- and offsets from dp to ms
  #compute ip slopes based on ms-parameters (without shifting as we are only interested in the slope)
  output <- output %>%
    mutate(onset_emp = onset_emp_dp * factor + shift,
           offset_emp = offset_emp_dp * factor + shift,
           ip1_slope = dgamma_prime(ip1*factor, yscale, shape, rate/factor)*factor,
           ip2_slope = dgamma_prime(ip2*factor, yscale, shape, rate/factor)*factor) 
    

  # Restructure wide into Long 
  output = output %>% 
    # [Elisa 01/2025] added eeg_mean_win, mode, removed shape, rate, yscale
    # [Elisa 27/05/2025] added mode_peak and ip_slopes
    select(subject,lab,experimenter,task,condition,channel,component,n_trials, eeg_mean_win, 
           skew, excess, mode_ms, ip1_ms, ip2_ms, 
           mode_peak, ip1_slope, ip2_slope, onset_emp, offset_emp) %>%
        gather(GMA_Measure, EEG_Signal, eeg_mean_win:offset_emp)
  colnames(output)[1:8] = str_to_title(colnames(output)[1:8])
  
  output = output %>%  # consistence across Projects
    rename(ID = Subject,
           Electrode = Channel,
           Epochs = N_trials)
  
  
  
  # Merge Data with EEG Data
  output = merge(
    output,
    ScoreData[,c("ID", Personality_Variable_choice)],
    by = c("ID"),
    all.x = TRUE,
    all.y = FALSE
  )
  if (!AddCovariate == 0) {
    output = merge(
      output,
      CovariateData,
      by = c("ID"),
      all.x = TRUE,
      all.y = FALSE
    )}
  
  
  # Make sure everything is in correct format
  NumericVariables = c("EEG_Signal", "Epochs", names(output)[grepl("Covariate_", names(output))])
  # [Elisa 01/25] removed ID, added Electrode as Grouping Variable as we do not compute Clusters
  GroupingVariables = c("Task", "Condition", "Electrode", "Component",  "GMA_Measure", names(output)[grepl("Covariate_Gender", names(output))])
  
  output[GroupingVariables] = lapply(output[GroupingVariables], as.factor)
  output[NumericVariables] = lapply(output[NumericVariables], as.numeric)
  
  # [Elisa 04/25] delete cases without perfectionism data
  output <- output %>%
    group_by(ID, Task) %>%
    filter(!any(is.na(Personality_MPS_PersonalStandards)), !any(is.na(Personality_MPS_ConcernOverMistakes))) %>%
    ungroup()
  
  
  # Grouping Variables in all Files and Merge with additional Factors
  # [Elisa 01/25] commented line below bc it's redundant
  #GroupingVariables = c("Condition", "Component", "Task", "GMA_Measure")
  input$stephistory$GroupingVariables = GroupingVariables
  
  #No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
