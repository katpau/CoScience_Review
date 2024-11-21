
# Get library to parallelize For Loop
list.of.packages <- c("foreach", "doParallel", "R.utils", "matrixStats")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,  repos='http://cran.us.r-project.org')
suppress = lapply(list.of.packages, require, character.only = TRUE)


args=commandArgs(trailingOnly = TRUE)

AnalysisName = args[1]
ImportedTask = args[2]
Steps_toSave_Delete = as.numeric(unlist(strsplit(args[3], "\\+") ))
MaxStep = args[4]
if (MaxStep < max(Steps_toSave_Delete)) {
Steps_toSave_Delete = c(Steps_toSave_Delete[1:Steps_toSave_Delete<MaxStep], MaxStep)
}



# # # For Testing
# AnalysisName="Alpha_Context"
# ImportedTask="Resting"
# Steps_toSave_Delete=c(7,20)

ImportFolder = sprintf("/work/bay2875/RawData/task-%s/", ImportedTask)
ListFolder = sprintf("/home/bay2875/ForkingFiles/%s/List_Subsets/%s/", AnalysisName, ImportedTask)
ExportFolder = sprintf("/home/bay2875/ForkingFiles/%s/List_Subsets/", AnalysisName)
OutputFolder = sprintf("/work/bay2875/%s/task-%s/", AnalysisName, ImportedTask)

####### Create List of completed Subs
SubjectsNames = list.files(path = ImportFolder)
Subjects = data.frame(matrix(nrow =length(SubjectsNames), ncol = length(Steps_toSave_Delete)+1))
Subjects[,1] = SubjectsNames
# Loop through all interim Saves and find where to start subject
for (iMax in 1:length(Steps_toSave_Delete)) {   
  # List all Subject Files that contain the Forking Subsets of that Step
  ListFolder_MaxStep = paste0(ListFolder, Steps_toSave_Delete[iMax])
  SubjectList = list.files(path = ListFolder_MaxStep, pattern = 'sub-*', full.names = TRUE) 
  # Drop empty files 
  SubjectList = SubjectList[!file.size(SubjectList) == 0L]
  SubjectList = gsub(".csv", "", basename(SubjectList))
  # Mark if this Step has to be run
  Subjects[Subjects[,1] %in% SubjectList, (iMax+1)] = Steps_toSave_Delete[iMax]
}
# if final step has been done, drop subject
CompletedSubs = Subjects[is.na(Subjects[,ncol(Subjects)]),]


########### Delete Subs
ForkingFolders = list.dirs(path = OutputFolder)
# Drop First one (includes header)
ForkingFolders = ForkingFolders[grepl("/1.", ForkingFolders)]

# Important: Drop Folders to not delete Relevant Information
# Don't delete the last Step
ForkingFolders = ForkingFolders[!grepl(paste0("_", MaxStep, "."), ForkingFolders)]


# Initate Function to delete Files in Folder
Cleanup = function(i_Fork) {
  SubjectFiles = list.files(path = i_Fork, pattern = '*.mat', full.names = TRUE)
  SubjectFiles = SubjectFiles[!grepl("_error", SubjectFiles)]

  % only mark completed Files
  SubjectFiles = SubjectFiles[grepl(paste(CompletedSubs[,1], collapse= "|"), SubjectFiles)]

  if (length(SubjectFiles )>0) {
  file.remove(SubjectFiles)
  # remove Folder
  #SubjectFiles = list.files(path = i_Fork, pattern = 'sub-*', full.names = TRUE)
  #if(length(SubjectFiles) ==0) {unlink(i_Fork, recursive = TRUE)}}
}}




## Delete Files
# wrap in invisible to suppress output
nr_Cores = detectCores()-1
myCluster  = parallel::makeForkCluster(nr_Cores) 
registerDoParallel(myCluster)
invisible(foreach(i_Fork = ForkingFolders) %dopar% Cleanup(i_Fork))
on.exit(stopCluster(myCluster ))




