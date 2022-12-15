For each Analysis, there is a folder containing important Files to run the forking path analysis

each folder contains
DESIGN.mat = a overview of all Steps, their choices and conditional statements
FORKS.mat = a subsample of some forking paths (array of strings, one row is one forking path, Choice for each steps are concatenated with %)
StatFORKS.txt = a subsample combining the available group data (usually reflecting all the calculated FORKS) with a subsample of the possible statistical analyses
	these contain the name of the group file, the combination of the statistics (in numbers and words)


The folder List_Subsets is used on the high performance computer to keep track of which tasks need to be processed and if the analysis should only 
continue to intermediate steps and finally contain a file for each subject, that points to the Files listing which combinations need to be run (usually more than just FORKS.mat)
This is not of importance for the review