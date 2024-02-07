Outliers_RT = function(input = NULL, choice = NULL) {
  StepName = "Outliers_RT"
  Choices = c("Applied", "None")
  Order = 9.3
  output = input$data
  
  ## Contributors
  # Last checked by KP 01/23
  # Planned/Completed Review by: 

  # if RT is used as a predictor/DV, scan for outliers
  # identifies and removes outliers based on previous criteria (thresholds)
  # (1) drop trials based on min RT (previous choice from EEG preprocessing)
  # (2) Get previous choices about threshold and prepare function
  # (3) Identify outlier
  # (4) Treat outlier
  
  
  #########################################################
  # (1) Get Behavioral Data
  #########################################################
  # RT and ACC in EEG export only applies to trials with EEG Signal!
  Behav_Data = read.csv(paste0(
    input$stephistory["Root_Behavior"],
    "task_UltimatumGame_beh.csv"
  ))
  # Add TrialNr
  Behav_Data =   Behav_Data %>%
    group_by(ID) %>%
    mutate(Trial = 1:length(OfferSelf)) %>%
    ungroup
  
  
  # Drop too fast Trials if forked
  if (grepl("17.2", input$stephistory$Inputfile)) {
    Behav_Data = Behav_Data[Behav_Data$RT >= 0.1,]
  }
  # Rename to make same as EEG
  colnames(Behav_Data)[colnames(Behav_Data)=="OfferSelf"] = "Offer"
  colnames(Behav_Data)[colnames(Behav_Data)=="Response"] = "Choice"
  #########################################################
  # (2) Prepare Outlier Handling
  #########################################################
  
  # Get choices from Earlier
  Threshold = input$stephistory[["Outliers_Threshold"]]
  Treatment = input$stephistory[["Outliers_Treatment"]]
  
  if (choice == "Applied"){
    
    # Set up outlier function based on Choice on Thresholds, takes the corresponding values (central tendency, width),
    # returns 0&1, 1 for the values exceeding the acceptable range
    outlierfunction = function(Threshold, data,  ExportMinMax) {
      if (grepl("SD", Threshold)) {
        Center = mean(data, na.rm = TRUE)
        Width = sd(data, na.rm = TRUE)
      } else if (grepl("IQ", Threshold)) {
        Center = median(data,  na.rm = TRUE)
        Width = IQR(data, na.rm = TRUE)
      }
      Distance = as.numeric(str_split(Threshold, " ")[[1]][1])
      
      Min = Center-Distance*Width
      Max = Center+Distance*Width
      Outliers = numeric(length(data))
      Outliers[!is.na(data) & (data < Min | data > Max)] = 1
      if (ExportMinMax == 1) {
        return(data.frame(Min,Max))
      }  else { return(Outliers)}
    }
    
    
    #########################################################
    # (2) Identify Outliers 
    #########################################################
    Behav_Data = Behav_Data %>%
      group_by(Offer, Choice)%>%
      mutate(Outliers_RT = outlierfunction(Threshold, RT, 0)) %>%
      ungroup()
    
 
    #########################################################
    # (3) Treat Outliers RT
    #########################################################
    if (Treatment == "Replace" ){
      # Save Min/Max in column for later
      MinMax = Behav_Data %>%
        group_by(Offer, Choice)%>%
        do(outlierfunction(Threshold, .$RT, 1))%>%
        ungroup()
      
      
      # merge with output_RT
      Behav_Data =  merge(Behav_Data,    
                      MinMax,
                      by = c("Offer", "Choice"),   
                      all.x = TRUE,    all.y = FALSE )
      
      ExceedMin = which(Behav_Data$RT<Behav_Data$Min)
      ExceedMax = which(Behav_Data$RT>Behav_Data$Max)
      Behav_Data$RT[ExceedMin] =   Behav_Data$Min[ExceedMin]
      Behav_Data$RT[ExceedMax] =   Behav_Data$Max[ExceedMax]
      
      # Exclude Value
    } else {
      Behav_Data$RT[as.logical(Behav_Data$Outliers_RT)] = NA  }
    
    
    # Remove columns
    Behav_Data = Behav_Data[,!names(Behav_Data) %in% c("Outliers_RT",  "Min", "Max")]
    Behav_Data$Offer = as.factor(Behav_Data$Offer)
    Behav_Data$Component = "Behav"
    
    # Add Lab Info
    Labs = output[, c("ID", "Lab")]
    Labs = Labs[!duplicated(Labs),]
    Behav_Data = merge(Behav_Data, Labs, by = c("ID"))
    
    # merge (LONG FORMAT) with full dataset
    output = bind_rows(output,
                       Behav_Data)  
    
  }
  
  
  
  
  
  # No change needed below here - just for bookkeeping
  stephistory = input$stephistory
  stephistory[StepName] = choice
  return(list(
    data = output,
    stephistory = stephistory
  ))
}
