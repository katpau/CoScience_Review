  function prepare_step_functions(DesignName, DESIGN, Path_To_Save, overwrite) 
  % Prepares new .m script for each step according to a template.
  % these are saved in the path: current folder / Design Name / Step_Functions
  % Template includes a summary of the Design Structure
  
  % Inputs:
  %     DesignName: String, Used to create root folder for the step_functions, the preprocessing and stats
  %     DESIGN: Structure with field for each Step. 
  %                Step has subfield: 
  %                     Choice (string array)
  %                Step can have optional fields: 
  %                      Weights (numeric, have do add um to 1, default equal weights)
  %                      Conditional (string, includes condition in Matlab terms; important use double quotation marks! """"Choice""""  default NaN)
  %                      SaveInterim (logical; default false)
  %     
  % Optional Inputs:
  %     overwrite: logical, should files be overwritten if they exist? Default is 0, No overwrite
              if nargin<4
              overwrite = 0;
              end
              
              
       
  FolderName = strcat(Path_To_Save, "/StepFunctions_", DesignName);
  mkdir(FolderName);
  cd(FolderName);
  Steps = fields(DESIGN);
  
      for iStep = 1: length(Steps); 
          if   isfile(strjoin([char(Steps{iStep}), ".m"], '')) ==1 & overwrite == 0
          fprintf("Function: %s already exists. Is not overwritten. \n", char(Steps{iStep}));
          continue
          else
          fileID = fopen(strjoin([char(Steps{iStep}), ".m"], ''),'w');
          fprintf(fileID, "function  OUTPUT = %s(INPUT, Choice);\n \n", char(Steps{iStep}));
          fprintf(fileID, "% This script does the following:\n");
          fprintf(fileID, "% ADD DESCRIPTION \n");
          fprintf(fileID, "% ADD DESCRIPTION \n");
          fprintf(fileID, "% % It is able to handle all options from ""Choices"" below (see Summary). \n  \n \n");
          

          
          fprintf(fileID, "%#####################################################################\n");
          fprintf(fileID, "%### Usage Information                                         #######\n");
          fprintf(fileID, "%#####################################################################\n");
          fprintf(fileID, "% This function requires the following inputs:\n");
          fprintf(fileID, "% INPUT = structure, containing at least the fields ""Data"" (containing the\n");
          fprintf(fileID, "%       EEGlab structure, ""StephHistory"" (for every forking decision). More\n");
          fprintf(fileID, "%       fields can be added through other preprocessing steps.\n");
          fprintf(fileID, "% Choice = string, naming the choice run at this fork (included in ""Choices"")\n \n");
          fprintf(fileID, "% This function gives the following output:\n");
          fprintf(fileID, "% OUTPUT = struct, similiar to the INPUT structure. StepHistory and Data is\n");
          fprintf(fileID, "%           updated based on the new calculations. Additional fields can be\n");
          fprintf(fileID, "%           added below\n");

          
          
          fprintf(fileID, "%#####################################################################\n");
          fprintf(fileID, "%### Summary from the DESIGN structure                         #######\n");
          fprintf(fileID, "%#####################################################################\n");
          fprintf(fileID, "% Gives the name of the Step, all possible Choices, as well as any possible\n");
          fprintf(fileID, "% Conditional statements related to them (""NaN"" when none applicable).\n");
          fprintf(fileID, "% SaveInterim marks if the results of this preprocessing step should be\n");
          fprintf(fileID, "% saved on the harddrive (in order to be loaded and forked from there).\n");
          fprintf(fileID, "% Order determines when it should be run.\n");

          fprintf(fileID, "StepName = ""%s"";\n", char(Steps{iStep}));
          fprintf(fileID, "Choices = [""%s""]; \n", strjoin(DESIGN.(char(Steps{iStep})).Choices, '", "'));
          fprintf(fileID, "Conditional = [""%s""]; \n", strjoin(DESIGN.(char(Steps{iStep})).Conditional, '", "'));
          fprintf(fileID, "SaveInterim = logical([%s]); \n", num2str(DESIGN.(char(Steps{iStep})).SaveInterim));
          fprintf(fileID, "Order = [%s]; \n \n", num2str(DESIGN.(char(Steps{iStep})).Order));

          fprintf(fileID, "%%****** Updating the OUTPUT structure ****** \n");
          fprintf(fileID, "% No changes should be made here. \n");
          fprintf(fileID, "INPUT.StepHistory.%s = Choice; \n", char(Steps{iStep}));
          fprintf(fileID, "OUTPUT = INPUT; \n");   
          fprintf(fileID, "tic % for keeping track of time \n"); 
          fprintf(fileID, "try % For Error Handling, all steps are positioned in a try loop to capture errors \n \n"); 
    
          fprintf(fileID, "%#####################################################################\n"); 
          fprintf(fileID, "%### Start Preprocessing Routine                               #######\n"); 
          fprintf(fileID, "%##################################################################### \n \n"); 
    
          fprintf(fileID, "% Get EEGlab EEG structure from the provided Input Structure\n"); 
          fprintf(fileID, "EEG = INPUT.data;\n"); 
          
          fprintf(fileID, "%% ADD ROUTINE HERE \n \n \n"); 
          
        fprintf(fileID, "%#####################################################################\n");  
        fprintf(fileID, "%### Wrapping up Preprocessing Routine                         #######\n");  
        fprintf(fileID, "%#####################################################################\n");  
        fprintf(fileID, "% ****** Export ******\n");  
        fprintf(fileID, "% Script creates an OUTPUT structure. Assign here what should be saved\n");  
        fprintf(fileID, "% and made available for next step. Always save the EEG structure in\n");  
        fprintf(fileID, "% the OUTPUT.data field, overwriting previous EEG information.\n");  
        fprintf(fileID, "OUTPUT.data = EEG;\n");  
        fprintf(fileID, "OUTPUT.StepDuration = [OUTPUT.StepDuration; toc]; \n\n");  

        fprintf(fileID, "% ****** Error Management ******\n");  
        fprintf(fileID, "catch e\n");  
        fprintf(fileID, "% If error ocurrs, create ErrorMessage(concatenated for all nested\n");  
        fprintf(fileID, "% errors). This string is given to the OUTPUT struct.\n");  
        fprintf(fileID, "ErrorMessage = string(e.message);\n");  
        fprintf(fileID, "for ierrors = 1:length(e.stack)\n");  
        fprintf(fileID, "    ErrorMessage = strcat(ErrorMessage, ""//"", num2str(e.stack(ierrors).name), "", Line: "",  num2str(e.stack(ierrors).line));\n");  
        fprintf(fileID, "end \n \n");  

        fprintf(fileID, "OUTPUT.Error = ErrorMessage;\n");  
        fprintf(fileID, "end\n");  
        fprintf(fileID, "end\n");  

          fclose(fileID);
          end
      end
  fprintf("Functions are saved in Folder %s. \n", FolderName);  
  end