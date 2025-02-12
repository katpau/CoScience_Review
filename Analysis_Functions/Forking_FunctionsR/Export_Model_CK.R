### CK: added functions for reporting LMM and SSA results as table

# function for creating a table displaying MLM results of the random slopes model
mlm.table <- function(Model_Result, Effect_of_Interest) {
  # get random and fixed effects
  ranef <- as.data.frame(summary(Model_Result)$varcor)
  fixef <- summary(Model_Result)$coefficients
  
  if (length(Effect_of_Interest)>1) {
    Idx = which(rowSums(sapply(X = Effect_of_Interest, FUN = grepl, rownames(fixef))) == length(Effect_of_Interest))
    Idx = Idx[          str_count(rownames(fixef)[Idx] , ":")  <  length(Effect_of_Interest)             ]
  }  else {
    Idx = rownames(fixef) == Effect_of_Interest
  }
  
  if (Model_Result@lmFamily == "binominal") {
    rtable = fixef[Idx, c(1, 2, 4)]   
  } else {
    rtable = fixef[Idx, c(1, 2, 5)]  
  }
  
  
  if (any(grepl("Personality_", Effect_of_Interest))) { # SD of random effects only for..Intercept/Demand
    rtable= c(rtable,NA)
  } else {
    rtable= c(rtable, ranef$sdcor[2]) # is it always 2nd?
  }
  
  names(rtable) = c("Beta", "SE", "pvalue", "Rand_Eff_SD")
  # Dropped adding * and rounding -> for forks better 
  return(rtable)
}

# mlm.table <- function(x, type = c("mlm", "glmm"), demand.only = F, model.no = c(1,2,3)) {
#   # get random and fixed effects
#   ranef <- as.data.frame(summary(x)$varcor)
#   fixef <- summary(x)$coefficients
#   
#   # prepare table
#   if(model.no == 1) {
#     rtable <- as.data.frame(cbind(c("Intercept", "demand", "CEI", "CEI:demand"),
#                                   fixef[-c(4:5),c(1, 2, 5)]))
#   }
#   else if (model.no == 2) {
#     rtable <- as.data.frame(cbind(c("Intercept", "demand", "COM", "COM:demand"),
#                                   fixef[-c(4:5),c(1, 2, 5)])) 
#   }
#   else if (model.no == 3) {
#     rtable <- as.data.frame(cbind(c("Intercept", "demand", "ESC", "ESC:demand"),
#                                   fixef[-c(4:5),c(1, 2, 5)]))
#   }
#   
#   rtable$ranef.sd <- NA
#   rtable$ranef.sd[1:2] <- ranef$sdcor[1:2]
#   rtable$ranef.sd[which(is.na(rtable$ranef.sd))] <- ""
#   
#   rtable[2:5] <- lapply(rtable[2:5], as.numeric)
#   rtable[c(2,3,5)] <- round(rtable[c(2,3,5)], digits = 2)
#   rtable[4] <- round(rtable[4], digits = 3)
#   
#   rtable[,4][which(rtable[,4] <.01)] <- paste0(rtable[,4][which(rtable[,4]<.01)],"*")
#   rtable[,4][which(rtable[,4]<.05)] <- paste0(rtable[,4][which(rtable[,4]<.05)],"*")
#   rtable[,4][which(rtable[,4]<.001)] <- paste0("<.001***")
#   
#   rtable$ranef.sd[which(is.na(rtable$ranef.sd))] <- ""
#   colnames(rtable) <- c("Parameter", "Beta", "SE", "p-value", "Random Effects (SD)")
#   row.names(rtable) <- NULL
#   rtable[2:3] <- lapply(rtable[2:3], as.character)
#   
#   return(list(rtable = rtable))
# }



# function for creating a table displaying simple slopes analysis results (CEI only)
ssa.table <- function(x, predictor) {
  rtable <- data.frame("V1" = c("- 1 SD", "Mean", "+ 1 SD"),
                       round(x$slopes[2:6], digits = 2), x$slopes[7], round(x$ints[2:3], digits = 2))
  rtable$sig <- NA
  rtable$sig[which(rtable$p <.01)] <- "*"
  rtable$sig[which(rtable$p <.05)] <- "**"
  rtable$sig[which(rtable$p <.001)] <- "***"
  rtable$sig[which(is.na(rtable$sig))] <- ""
  
  rtable$slope <- paste0(rtable$Est., " (", rtable$S.E., ")", rtable$sig)
  rtable$CI <- paste0("[", rtable$X2.5., ", ", rtable$X97.5., "]")
  rtable$int <- paste0(rtable$Est..1, " (", rtable$S.E..1, ")")
  
  if (predictor == "payoff") {
    rtable <- rbind(c("Value of CEI", "Slope of Payoff", "", "Conditional Intercept"),
                    c("", "Beta (SE)", "95% CI", "Beta (SE)"), 
                    rtable[,c(1, 11:13)])
    rtable <- cbind("V0" = c("", "","", "Payoff", ""), rtable)
    
  } else if (predictor == "demand") {
    rtable <- rbind(c("Value of CEI", "Slope of Demand", "", "Conditional Intercept"),
                    c("", "Beta (SE)", "95% CI", "Beta (SE)"), 
                    rtable[,c(1, 11:13)])
    rtable <- cbind("V0" = c("", "","", "Demand", ""), rtable)
  }
  colnames(rtable) <- c("V0", "V1", "V2", "V3", "V4")
  
  return(rtable = rtable)
}
