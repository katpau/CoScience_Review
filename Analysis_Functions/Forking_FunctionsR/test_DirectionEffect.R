test_DirectionEffect = function(DirectionEffect = NULL, Subset = NULL, ModelResult = NULL) {
  # DirectionEffect is a list with the following named elements:
  #               Effect - char to determine what kind of test, either main, interaction, correlation, interaction_correlation, interaction2_correlation
  #               Personality - char name of personality column
  #               Larger - array of 2 chars: first name of column coding condition, second name of factor with larger effect
  #               Smaller - array of 2 chars: first name of column coding condition, second name of factor with smaller effect
  #               Interaction - array of 3 chars: first name of column coding condition additional to Larger/Smaller, second name of factor with smaller effect, third with larger effect
  # Subset is dataframe including all Data (Personality, EEG_Signal, Conditions)
  # ModelResult are the Estimates exported from test_Hypothesis
  
  if ("DV" %in% names(DirectionEffect) ) {
    DV = DirectionEffect$DV
  } else {DV = "EEG_Signal"}
  
  
  # Aggregate if trialwise for Flanker and Ultimatum
  if(length(unique(Subset$ID))*40 < nrow(Subset)) {
    if ("Congruency_notCentered" %in% colnames(Subset)){
      Groupings = c("ID", "Congruency_notCentered", "Electrode")
      Groupings = Groupings[Groupings %in% colnames(Subset)]
    } else if ("Offer" %in% colnames(Subset)) {
      Groupings = c("ID", "Offer", "Choice")
      Groupings = Groupings[Groupings %in% colnames(Subset)]
      Groupings = Groupings[!grepl(DV, Groupings)]
    } else {
      Groupings = c("ID", "Condition")
    }
    if ("Personality" %in% names(DirectionEffect)) {
    Subset = Subset %>%
      group_by_at(Groupings) %>%
      summarise(DV = mean(get(DV), na.rm =T),
                Personality = get(DirectionEffect$Personality)[1])
      colnames(Subset)[colnames(Subset) == "DV"] = DV
      colnames(Subset)[colnames(Subset) == "Personality"] = DirectionEffect$Personality
    } else {
      Subset = Subset %>%
        group_by_at(Groupings) %>%
        summarise(DV = mean(get(DV), na.rm =T))
      colnames(Subset)[colnames(Subset) == "DV"] = DV
    }
  }
  
  if (DirectionEffect$Effect == "main") {
    Subset$Recode = NA
    Subset$Recode[Subset[,DirectionEffect$Smaller[1]]  ==    DirectionEffect$Smaller[2]] = 0
    Subset$Recode[Subset[,DirectionEffect$Larger[1]]  ==    DirectionEffect$Larger[2]] = 1
    
    Test = cor(Subset[,DV], Subset$Recode, use = "complete.obs")>0
    
    
  } else if (DirectionEffect$Effect == "interaction") { # Interaction
    # Problem? This does not take into account within Subject Diffs but only across all Subjects
    Smaller = Subset[,DirectionEffect$Smaller[1]]  ==    DirectionEffect$Smaller[2]
    Larger =  Subset[,DirectionEffect$Larger[1]]  ==    DirectionEffect$Larger[2]
    
    Subset$Recode = NA
    Subset$Recode[Subset[,DirectionEffect$Interaction[1]]  ==    DirectionEffect$Interaction[2]] = 0
    Subset$Recode[Subset[,DirectionEffect$Interaction[1]]  ==    DirectionEffect$Interaction[3]] = 1
    
    SmallerCorr = cor(Subset[Smaller, DV ], Subset$Recode[Smaller ], use = "complete.obs")
    LargerCorr = cor(Subset[Larger, DV ], Subset$Recode[Larger ], use = "complete.obs")
    
    Test = (LargerCorr-SmallerCorr)>0
    
  } else if (DirectionEffect$Effect == "correlation") { # Correlation with Personality between conditions 
    CorrAll = cor(Subset[,DV], Subset[, DirectionEffect$Personality], use = "complete.obs")
    Test = CorrAll>0
    
  } else if (DirectionEffect$Effect == "interaction_correlation") { # Correlation with Personality between conditions
    Smaller = which(Subset[,DirectionEffect$Smaller[1]]  ==    DirectionEffect$Smaller[2])
    Larger =  which(Subset[,DirectionEffect$Larger[1]]  ==    DirectionEffect$Larger[2])
    SmallerCorr = cor(Subset[Smaller, DV], Subset[Smaller, DirectionEffect$Personality], use = "complete.obs")
    LargerCorr = cor(Subset[Larger, DV], Subset[Larger, DirectionEffect$Personality], use = "complete.obs")
    
    Test = (LargerCorr-SmallerCorr)>0
    
    
  } else if (DirectionEffect$Effect == "interaction2_correlation") {  # Correlation with Personality between conditions and their Interaction
    SmallerS = Subset[,DirectionEffect$Smaller[1]]  ==    DirectionEffect$Smaller[2] &
      Subset[,DirectionEffect$Interaction[1]]  ==    DirectionEffect$Interaction[2]   
    SmallerL = Subset[,DirectionEffect$Smaller[1]]  ==    DirectionEffect$Smaller[2] &
      Subset[,DirectionEffect$Interaction[1]]  ==    DirectionEffect$Interaction[3]                     
    LargerS = Subset[,DirectionEffect$Larger[1]]  ==    DirectionEffect$Larger[2] &
      Subset[,DirectionEffect$Interaction[1]]  ==    DirectionEffect$Interaction[2]   
    LargerL = Subset[,DirectionEffect$Larger[1]]  ==    DirectionEffect$Larger[2] &
      Subset[,DirectionEffect$Interaction[1]]  ==    DirectionEffect$Interaction[3]                     
    
    
    SmallerSCorr = cor(Subset[SmallerS, DV], Subset[SmallerS, DirectionEffect$Personality], use = "complete.obs")
    SmallerLCorr = cor(Subset[SmallerL, DV], Subset[SmallerL, DirectionEffect$Personality], use = "complete.obs")
    LargerSCorr = cor(Subset[LargerS, DV], Subset[LargerS, DirectionEffect$Personality], use = "complete.obs")
    LargerLCorr = cor(Subset[LargerL, DV], Subset[LargerL, DirectionEffect$Personality], use = "complete.obs")
    
    Test = ((LargerLCorr - LargerSCorr ) - (SmallerLCorr - SmallerSCorr)) >0
    
  } else if (DirectionEffect$Effect == "diff_correlation") { 
    Cond = DirectionEffect$Smaller[1]
    Smaller = DirectionEffect$Smaller[2]
    Larger = DirectionEffect$Larger[2]
    Personality = DirectionEffect$Personality
    
    SubsetWide <- Subset %>%
      group_by(ID, .data[[Cond]]) %>%
      summarise(EEG_Signal = mean(.data[[DV]], na.rm = TRUE),
               Personality := first(!!sym(Personality))) %>%
      #summarise(!!sym(DV) := mean(!!sym(DV), na.rm = TRUE),
      #          Personality := first(!!sym(Personality))) %>%
      pivot_wider(names_from = .data[[Cond]], values_from = DV) %>%
      mutate(Diff = .data[[Larger]] - .data[[Smaller]]) 
      CorrelationTest = cor(SubsetWide$Diff, SubsetWide$Personality, use = "complete.obs")
      Test = CorrelationTest>0
    
  } else if (DirectionEffect$Effect == "diff2_correlation") { 
    Cond = DirectionEffect$Smaller[1]
    Cond2 = DirectionEffect$Smaller2[1]
    Smaller = DirectionEffect$Smaller[2]
    Larger = DirectionEffect$Larger[2]
    Smaller2 = DirectionEffect$Smaller2[2]
    Larger2 = DirectionEffect$Larger2[2]
    Personality = DirectionEffect$Personality
    DV2 = "Diff"
    
    SubsetWide <- Subset %>%
      group_by(ID, !!!syms(c(Cond, Cond2))) %>%
      summarise(EEG_Signal = mean(.data[[DV]], na.rm = TRUE),
                Personality := first(!!sym(Personality))) %>%
      #summarise(!!sym(DV) := mean(!!sym(DV), na.rm = TRUE),
      #          Personality := first(!!sym(Personality))) %>%
      pivot_wider(names_from = .data[[Cond]], values_from = DV) %>%
      mutate(Diff = .data[[Larger]] - .data[[Smaller]]) %>%
      select("ID", "Personality", Cond2, DV2) %>%
      pivot_wider(names_from = .data[[Cond2]], values_from = DV2) %>%
      mutate(Diff = .data[[Larger2]] - .data[[Smaller2]]) 
    CorrelationTest = cor(SubsetWide$Diff, SubsetWide$Personality, use = "complete.obs")
    Test = CorrelationTest>0
    
  }
  
  
  DirectionEffectIA = list("Effect" = "diff2_correlation",
                           "Larger" = c("FB", "Win"),
                           "Smaller" = c("FB", "Loss"),
                           "Smaller2" = c("Magnitude", "P0"),
                           "Larger2" = c("Magnitude", "P50"))
  if (isFALSE(Test) & ModelResult$value_EffectSize > 0) {
    
    ModelResult$value_EffectSize = ModelResult$value_EffectSize * -1
    bu_low = ModelResult$CI_low * -1
    ModelResult$CI_low = ModelResult$CI90_high * -1
    ModelResult$CI90_high = bu_low
  } 
  return(ModelResult)
}
