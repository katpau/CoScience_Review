
################################################################################

# 0. Prepare Files #############################################################

FolderQuestData = paste0(Root, "/Raw/")
OutputFolder = paste0(Root,"/Test-",
                      TaskName, "/")
dir.create(OutputFolder)

# File with Item Information
Helperfile = paste0(Root, "/Raw/Fragebogen_OutputÜbersicht.csv")



# 1. Get Information on Item Level (for Reliability!) ##########################

# Load HelperFile
Helperfile = read.csv(Helperfile, header = TRUE, sep = ";")

# Restructrue Helperfile so that it is long format
Add = Helperfile[Helperfile$Subskala2 != "", ]
Add$Subskala1 = Add$Subskala2
Helperfile = rbind(Helperfile, Add)
Add = Helperfile[Helperfile$Subskala3 != "", ]
Add$Subskala1 = Add$Subskala3
Helperfile = rbind(Helperfile, Add)
Helperfile$Fragebogenkürzel = as.character(Helperfile$Fragebogenkürzel)

# Determine Items of all Scales
Idx_Scales = sapply(Allrelevant_Subscales, grep, as.character(Helperfile$Subskala1))
Names_Items = vector(mode = "list", length = length(Allrelevant_Subscales))
names(Names_Items) = Allrelevant_Subscales
for (i_scale in 1:length(Allrelevant_Subscales)) {
  Names_Items[[Allrelevant_Subscales[i_scale]]] = Helperfile$Fragebogenkürzel[Idx_Scales[[Allrelevant_Subscales[i_scale]]]]
}

# Determine Number of Items included for each subscale (needed for weigthed mean etc.)
weight_Items = lengths(Idx_Scales[Allrelevant_Subscales])



# 2. Adjust Raw Data (reverse coding, outliers) ################################

# Depending on Combination (Attention Checks + Outliers based on RT), load the different 
# files with the Scores (for each subscale)
for (CutOff_Applied in 0) { # Cut loop here for testing
  for (Outliers_Applied in 1) {
  
    print(paste("Running with CutoffOption:", CutOff_Applied , "and Outlier applied Option:", Outliers_Applied))
    # Load Scores File
    if (CutOff_Applied == 1) {
      Scores_File = paste0(FolderQuestData, "Questionnaire_Scores-filtered.csv")
      Items_File = paste0(FolderQuestData, "Questionnaire_Items-filtered.csv")
    } else {
      Scores_File = paste0(FolderQuestData, "Questionnaire_Scores-unfiltered.csv")
      Items_File = paste0(FolderQuestData, "Questionnaire_Items-unfiltered.csv")
    }
    
    # Load Scores and select only relevant Scales
    Score_Data_AllScores = read.csv2(
      Scores_File,
      header = TRUE,
      sep = ";",
      check.names = FALSE  )
    Score_Data = Score_Data_AllScores[, c("ID", Allrelevant_Subscales)]
    
    # Load Items and select only relevant Scale Items
    Items_Data = read.csv2(Items_File,
                          header = TRUE,
                          sep = ";",
                          check.names = FALSE)
    
    Items_Data = Items_Data[,c("ID", unlist(Names_Items))]
    
   
    ## 2.1 Check for Outliers in Personality Data based on Mahalanobis Distance ####

    if (Outliers_Applied == 1){
      # Determine Outliers based on all (possibly) relevant Subscales
      ToTestforOutliers = Score_Data[,Maha_Subscales]
      mahala = psych::mardia(ToTestforOutliers,plot = FALSE)
      p = 1 - pchisq(mahala$d^2, df = ncol(ToTestforOutliers))
      outliers_mahalanobis = which(p < 0.001)
      
      # Remove all Data Entries and replace with NA
      Score_Data[outliers_mahalanobis, 2:ncol(Score_Data)] = NA
      
      # To match Item Data with Scores Data, Answers of excluded Scores must be replaced by NA
      for (i_Scale in 1:length(Maha_Subscales)) {
        if (any(is.na(Score_Data[, Maha_Subscales[i_Scale]]))) {
          BadSubs = which(is.na(Score_Data[, Maha_Subscales[i_Scale]]))
          BadSubs = Score_Data$ID[BadSubs]
          BadAnswers = Helperfile$Fragebogenkürzel[Helperfile$Subskala1 == Maha_Subscales[i_Scale]]
          Items_Data[Items_Data$ID %in% BadSubs, BadAnswers] = NA
        }
      }
      
      }
    

 
    if (Do_ZScores == 1) {

      
    ## 2.2 Calculate Cronbach Alpha for each Subscale ##########################

    z_ScoreCollumns = unique(c(unlist(Z_Scores_Average), unlist(Z_Scores_Sum)))
    weight_Reliability = weight_Items
    for (iSubscale in 1:length(z_ScoreCollumns)) {
      Test_Alpha = alpha(Items_Data[, Names_Items[[z_ScoreCollumns[[iSubscale]]]]])
      weight_Reliability[iSubscale] = Test_Alpha$total$raw_alpha
    }
    

    ## 2.3 Calculate Z Scores of Personality Variable ##########################

    Z_Score_Data = data.frame( Score_Data$ID)
    colnames(Z_Score_Data) = "ID"
   
    # z-score of Different Subscales
    Z_Scores = Score_Data[, z_ScoreCollumns]
    Z_Scores = apply(Z_Scores, 2, function(x) ( x - mean(x, na.rm=TRUE)) / sd(x, na.rm=TRUE))
    
    # SUM of zscores
    if (length(Z_Scores_Sum)>0) {
    for (iScore in names(Z_Scores_Sum)) {
      if (length(names(Z_Scores_Sum))>1) {
        NameCollumn = paste0("_", iScore)
      } else {
        NameCollumn = ""}
      Z_Score_Data[,paste0("Personality_Z_sum",NameCollumn)] =  rowSums(Z_Scores[,Z_Scores_Sum[[iScore]]])
    }}
    
    # AVERAGES OF ZSCORES
    # SUM of zscores
    for (iScore in names(Z_Scores_Average)) {
      if (length(names(Z_Scores_Average))>1) {
      NameCollumn = paste0("_", iScore)
      } else {
      NameCollumn = ""}
      # No Weight, just z-Score
      Z_Score_Data[,paste0("Personality_Z_AV_notweighted", NameCollumn)] =  rowMeans(Z_Scores[,Z_Scores_Average[[iScore]]])
      # z-score weighted by ItemNr of Subscales
      Z_Score_Data[,paste0("Personality_Z_AV_ItemNr", NameCollumn)] =  rowWeightedMeans(Z_Scores[,Z_Scores_Average[[iScore]]],
                                                                                                    weight_Items[Z_Scores_Average[[iScore]]])
      # z-score weighted by Reliability
      Z_Score_Data[,paste0("Personality_Z_AV_Reliability", NameCollumn)] =  rowWeightedMeans(Z_Scores[,Z_Scores_Average[[iScore]]],
                                                                                             weight_Reliability[Z_Scores_Average[[iScore]]])
    }   
 
    }
    if (Do_PCA == 1) {

      
    ## 2.4 Calculate PCA across Subscales ######################################

    PCA_Subset = na.omit(Score_Data[,c("ID", PCA_Subscales)])
    
    PCA_FirstFactor = prcomp(PCA_Subset[,2:ncol(PCA_Subset)])$x[, 1] # scale = TRUE???
    PCA_FirstFactor = cbind(PCA_Subset$ID, PCA_FirstFactor)
    colnames(PCA_FirstFactor) = c("ID", "Personality_PCA")
    
    

    ### 2.4.1 Calculate Factor Analysis across Subscales #######################

    ## An oblique rotation and analysis of all factors from a factor analysis (including all relevant subscales).
    # The factor analysis is estimated using a PCA, a promax rotation (with Kappa=4) is applied.
    # Parallel Analysis is used as a method for the number of factors to extract. Component scores are computed
    # from the rotated solution
    
    # Create initial factor analysis to determine number of factors
    FactAn = paran(
      na.omit(PCA_Subset[,2:ncol(PCA_Subset)]),
      iterations = 500,
      quietly = TRUE,
      status = TRUE,
      all = TRUE,
      cfa = TRUE,
      graph = TRUE
    )
    
    # Select Factors that explain more than random and which Eigenvalue are larger than 1
    nr_factors = sum(FactAn$AdjEv>1 & FactAn$AdjEv>FactAn$RndEv )
    # With test this was sometimes 0 (with real data did not happen yet)
    if (nr_factors == 0) {nr_factors = 1}
    
    # run Factor analysis with correct number of factors
    FactAn = factanal(
      PCA_Subset[,2:ncol(PCA_Subset)],
      factors = nr_factors,
      rotation = "promax",
      scores = 'regres' ) # Bartlett
 
    if (CutOff_Applied == 1 & Outliers_Applied == 1) {
      iFactor = FactorsToKeep[1]
    } else if  (CutOff_Applied == 1 & Outliers_Applied == 0) {
      iFactor = FactorsToKeep[2]
    } else if (CutOff_Applied == 0 & Outliers_Applied == 1) {
      iFactor = FactorsToKeep[3]
    } else if (CutOff_Applied == 0 & Outliers_Applied == 0) {
      iFactor = FactorsToKeep[4] }
    
    Factor_Analysis = cbind(PCA_Subset$ID, FactAn$scores[,iFactor])
    colnames(Factor_Analysis) = c("ID", "Personality_FactorAnalysis")
    
    
    
    ### 2.4.2 Second PCA/Factor Analysis #######################################

    
    ### If second PCA should be run (only selected Analysis)
    if (TaskName == "Alpha_Resting") {
    colnames(PCA_FirstFactor) = c("ID", "Personality_PCA_BAS")
    PCA_Subset = na.omit(Score_Data[,c("ID", PCA_Subscales2)])
    PCA_FirstFactor2 = prcomp(PCA_Subset[,2:ncol(PCA_Subset)])$x[, 1] # scale = TRUE???
    PCA_FirstFactor2 = cbind(PCA_Subset$ID, PCA_FirstFactor2)
    colnames(PCA_FirstFactor2) = c("ID", "Personality_PCA_BIS")
    
    PCA_FirstFactor = merge(PCA_FirstFactor,
                            PCA_FirstFactor2,
                            by = c("ID"),
                            all.x = TRUE,
                            all.y = FALSE)

  
    # Create initial factor analysis to determine number of factors
    FactAn2 = paran(
      na.omit(PCA_Subset[,2:ncol(PCA_Subset)]),
      iterations = 500,
      quietly = TRUE,
      status = TRUE,
      all = TRUE,
      cfa = TRUE,
      graph = TRUE
    )
    
    # Select Factors that explain more than random and which Eigenvalue are larger than 1
    nr_factors = sum(FactAn2$AdjEv>1 & FactAn2$AdjEv>FactAn2$RndEv )
    
    # run Factor analysis with correct number of factors
    FactAn2 = factanal(
      PCA_Subset[,2:ncol(PCA_Subset)],
      factors = nr_factors,
      rotation = "promax",
      scores = 'regres' ) # Bartlett
    
    if (CutOff_Applied == 1 & Outliers_Applied == 1) {
      iFactor = FactorsToKeep2[1]
    } else if  (CutOff_Applied == 1 & Outliers_Applied == 0) {
      iFactor = FactorsToKeep2[2]
    } else if (CutOff_Applied == 0 & Outliers_Applied == 1) {
      iFactor = FactorsToKeep2[3]
    } else if (CutOff_Applied == 0 & Outliers_Applied == 0) {
      iFactor = FactorsToKeep2[4] }
    
    Factor_Analysis = cbind(Factor_Analysis,FactAn2$scores[,iFactor])
    colnames(Factor_Analysis) = c("ID", "Personality_FactorAnalysis_BAS", "Personality_FactorAnalysis_BIS")
    
    }}

    
    ## 2.5 Calculate CFA for Cognitive Effort Investment #######################
    
    

    ## 2.6 Get Scores for the Personality Variable #############################

    # Scores from Subscales
    if (length(Scored_Subscales) > 0) {
      Score_Subscales = Score_Data[, Scored_Subscales]
    } else {
      Score_Subscales = NULL
    }

    

    ## 2.7 Get Scores for the Covariates #######################################

    # Scores from Subscales
    if (length(Covariates_Subscales) > 0) {
      Covariates = Score_Data[, Covariates_Subscales]
    } else {
      Covariates = NULL
    }
    

    ## 2.8 Some Special Concepts ###############################################

    
   if (TaskName == "Ultimatum_Offer") {
     Score_Subscales$AVBIS = rowMeans(Score_Data[,c("BISBAS_BIS", "RSTPQ_BIS")])
   }
    

## 3. Merge and export Data ####################################################

    ## Merge Data
    colnames(Score_Subscales) = paste0("Personality_", colnames(Score_Subscales))
    colnames(Covariates) = paste0("Covariate_", colnames(Covariates))
    OUTPUT = cbind(
      Score_Data[, 1],
      Score_Subscales,
      Covariates)
    colnames(OUTPUT)[1] = "ID"
    
    
    if (Do_ZScores == 1) {
      OUTPUT = merge(OUTPUT, Z_Score_Data, by = c("ID"),
                     all.x = TRUE,
                     all.y = FALSE)
      
      
      
      colnames(OUTPUT)[grepl("Z_Score", colnames(OUTPUT))] = paste0("Personality_",  colnames(OUTPUT)[grepl("Z_Score", colnames(OUTPUT))])
      
      }
    
    if (Do_PCA == 1) {    
      OUTPUT = merge(OUTPUT, PCA_FirstFactor, by = c("ID"),
                                          all.x = TRUE,
                                          all.y = FALSE)
      OUTPUT = merge(OUTPUT, Factor_Analysis, by = c("ID"),
                   all.x = TRUE,
                   all.y = FALSE)
   }
    


    # Export Data
    if (CutOff_Applied == 1) {
      Export_File_Name = "/Personality-Scores-filtered"
    } else {
      Export_File_Name = "/Personality-Scores-unfiltered"
    }
    if (Outliers_Applied == 1) {
      Export_File_Name = paste0(Export_File_Name, '_outliers-removed.csv')
    } else {
      Export_File_Name = paste0(Export_File_Name, '_outliers-notremoved.csv')
    }
    write.csv(OUTPUT,
              paste0(OutputFolder, Export_File_Name),
              row.names = FALSE)
    
    if (Do_PCA == 1) { 
      capture.output(FactAn, file = paste0(OutputFolder, "/Results_Factor_Analysis_", gsub("/", "", Export_File_Name)))
      if (TaskName == "Alpha_Resting") {
        capture.output(FactAn2, file = paste0(OutputFolder, "/Results_Factor_Analysis_BIS", gsub("/", "", Export_File_Name)))
        
      }
    }

  
  }}

################################################################################