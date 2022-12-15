This folder Contains Scripts to prepare the relevant questionnaires for the Forking Path 
Analyses, including the forking of the questionnaire (e.g. different Scores, PCA, 
applying outlier correction to the personality data etc.)


For each Analysis there is a corresponding File. These files contain the information on 
the relevant subscales, or how/if scales should be condensed. All files start the file
*Fork_Questionnaire_Common* 

Fork_Questionnaire_Common the file that actually extracts the data. 
It loops through the different Forking options
(1 - is the personality data filtered based on RTs in the questionnaire and correctness to the attention
checks?,
2 - should outiers be excluded based on mahalanobis distance?)
And then, depending on the choices defined in the Analyses Files, scores the data
(extracts scores, calculates reliability of scales, creates Zscores, PCA, Factor analyses...)
The Scores are saved in CSV files in a folder "Test-AnalysisName"



The Folder Raw contains the Questionnaire data 
	- at the score level and at the Item level. [Item level data has already been recoded if necessary]
	- also contains a file connecting Items with Scores (Fragebogen_OutputÜbersicht.csv)


To Run the script: Open the File with your analysis of interest (e.g. Flanker_Conflict) and run the entire file.
		Or run the File with your analysis line by line and then the file Fork_Questionnaire_Common