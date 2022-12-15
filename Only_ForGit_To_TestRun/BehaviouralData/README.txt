This folder contains behavioural data extracted for the relevant information

each file contains multiple subjects and multiple trials. These files are created from the individual
psychopy csv files through the corresponding scripts in the Folder Scripts/BehaviouralData (not included here)

the collumn names for the files indicate:

task_Flanker_beh.csv:
	-"ID", Subject Identifier
	-"Event", only Targets
	-"ExperimenterPresence", present or absent
	-"Congruency", 0, 0.33, 0.66, 1 corresponds to % of congruency of Flankers with Target
	-"Accuracy", 0 or 1 (0 incorrect, 1 correct response)
	-"RT", in seconds
	-"Post_Trial", if current trial followed a correct or error response
	-"TaskPerf" ACC across the Task in Percentage

task_GoNoGo_beh.csv
	-"ID", Subject Identifier
	-"Order_Instruction", relaxed_first or speed_accuracy_first - order of instructions (were given blockwise)
	-"Type", Go or NoGo
	-"InstructionCondition", Relaxed or Speed
	- "Accuracy", 0 or 1 (0 incorrect, 1 correct response)
	-"RT", in seconds
	-"Post_Trial", if current trial followed a correct or error response or a correct inhibition
	-"TaskPerf" ACC across the Task in Percentage

task_Ratings_beh
	-"ID", Subject Identifier
	-"Rated_Person", Participant or Experimenter
	- two items per dimension: "extraversion1","agreeableness1","conscientiousness1","neuroticism1","openness1","extraversion2","agreeableness2","conscientiousness2","neuroticism2","openness2",
		Answers to BFI Rating (1-5)
	- "attractiveness","sympathy","competence","assertiveness","trustworthyness","familarity",
		Answers to additional ratings (1-5)
	- "BFI_Extraversion","BFI_Neuroticism","BFI_Conscientiousness","BFI_Agreeableness","BFI_Openness",
		Sum score of two Items
	- "ExperimenterID", To identify Experimenter and Lab
	- "Experimenter_Sex", 	"Male" or Female

task_SR_beh
	-"ID", Subject Identifier
	- "Run",
		1 = after Setup, before first Rest
		2 = after GoNoGo first Block
		3 = after GoNoGo second Block
		4 = after Gamble, before second rest
		5 = after pause, before Stroop
		6 = after Stroop Rating
		7 = after Flanker, first Block
		8 = after Flanker, second Block
		9 = after Ultimatum, before third Rest
	- "anxious","peppy","peeved","happy","tired","relaxed","sad","calm","exhausted","irritated"
		Answers 1-7

task_StroopRating_beh
	-"ID", Subject Identifier
	- "Condition", NeutralCouple, NeutralManWoman, EroticCouple, EroticWoman, Tree, EroticMan, PositiveManWoman
	- "Dimension", Valence or Arousal
	- "Response", 1 - 9
	- "RT", in seconds

task_UltimatumGame_beh
	-"ID", Subject Identifier
	- "Event", only Offer
	- "Offer", Offer1 or Offer3 or Offer5 (what would the subject get)
	- "Response", Reject Accept or "None" (if timed out)
	- "RT", in seconds
	- "Offer", 

task-IST_beh
	-"ID", Subject Identifier
	-"IST_Fluid_Sum", Sum score fluid intelligence
	"IST_Crystallized_Sum", Sum score crystallized intelligence
	"verbal","verbal 1","verbal 2","verbal 3","numerical","numerical 1","numerical 2","numerical 3","figural","figural 1","figural 2","figural 3",
		Sum scores for the subcategories of the crystallized
	- "Item_161" - "Item_180", item responses to fluid
	- "Item_204" - "Item_287", item responses to crystallized


