# wrapper for shapiro.test()
sw <- function(x) {
  x = data.frame(x)
  d = dim(x)
  n = names(x)
  r = NULL
  for (i in 1:dim(x)[2]) {
    y = shapiro.test(x[, i])
    v = cbind(y$statistic, y$p.value)
    colnames(v) = c("W", "p")
    rownames(v) = n[i]
    r = rbind(r, v)
  }
  return(round(r, 3))
}


# for normalizing variables
normalize.gen <- function(data, whichFormula = 2, whichMeanSD = 1) {
  # normalizes DATA using one of the formulae:
  #
  # 1 = Van der Waerden (1952): r * / (n + 1)
  # 2 = Blom (1954):           (r - 3/8) / (n + 1/4) (default)
  # 3 = Bliss (1956; Rankit):  (r - 1/2) / n
  # 4 = Tukey (1962):          (r - 1/3) / (n + 1/3)
  #
  # Ties will be treated as average, and the output will be rescaled
  # to have mean = 0 and sd = 1, if you enter 1 for mean0.sd1 (default);
  # if you want to keep the mean and sd of the original variable, enter 0.
  
  normalize = function(data, normalize.formula = whichFormula,
                       mean0.sd1 = whichMeanSD) {
    r = rank(data,na.last = "keep",ties.method = ("average"))
    n = sum(!is.na(r))
    
    if (normalize.formula == 1)
      x = r / (n + 1)
    if (normalize.formula == 2)
      x = (r - 3 / 8) / (n + 1 / 4)
    if (normalize.formula == 3)
      x = (r - 1 / 2) / n
    if (normalize.formula == 4)
      x = (r - 1 / 3) / (n + 1 / 3)
    
    if (mean0.sd1 == 1)
      normal = qnorm(
        x,
        mean = 0,
        sd = 1,
        lower.tail = TRUE,
        log.p = FALSE
      )
    else
      normal = qnorm(
        x,
        mean = mean(data, na.rm = T),
        sd = sd(data, na.rm = T),
        lower.tail = TRUE,
        log.p = FALSE
      )
  }
  
  if (class(data) == "numeric") {
    normal = normalize(data, whichFormula, whichMeanSD)
  } else {
    normal = NULL
    for (i in 1:dim(data)[2]) {
      normal = cbind(normal, normalize(data[, i], whichFormula, whichMeanSD))
    }
    colnames(normal) = names(data)
  }
  
  return(normal)
  
}


# required function for reporting model fit
fm.report <- function(fit, scaled = T) {
  # which fit measures
  if (scaled == T) {
    fm = fitmeasures(fit)[c(
      "chisq.scaled",
      "df.scaled",
      "pvalue.scaled",
      "cfi.scaled",
      "rmsea.scaled",
      "rmsea.ci.lower.scaled",
      "rmsea.ci.upper.scaled",
      "srmr"
    )]
  } else {
    fm = fitmeasures(fit)[c(
      "chisq",
      "df",
      "pvalue",
      "cfi",
      "rmsea",
      "rmsea.ci.lower",
      "rmsea.ci.upper",
      "srmr"
    )]
  }
  # format
  fmr <- function(fm, digits = 2, nsmall = 2, gt1 = T, pval = F) {
    fm.out = format(round(fm, digits), nsmall = nsmall)
    if (gt1 == F) {
      fm.out = sub("0.", ".", fm.out)
    }
    if (pval == T & fm.out == ".000") {
      fm.out = "< .001"
    } else if (pval == T & fm.out != ".000") {
      fm.out = paste0("= ", fm.out)
    }
    return(fm.out)
  }
  # collapse
  fm.txt = paste0(
    "chi2 = ",
    fmr(fm[1]),
    ", df = ",
    fmr(fm[2], 0, 0),
    ", p ",
    fmr(fm[3], 3, 3, gt1 = F, pval = T),
    ", CFI = ",
    fmr(fm[4], gt1 = F),
    ", RMSEA = ",
    fmr(fm[5], gt1 = F),
    " with 90% CI [",
    fmr(fm[6], gt1 = F),
    ", ",
    fmr(fm[7], gt1 = F),
    "], ",
    "SRMR = ",
    fmr(fm[8], gt1 = F)
  )
  # return
  return(fm.txt)
}