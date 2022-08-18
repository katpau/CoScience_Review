function [Data] = run_step(Step, Data, Choice, SubjectName, FilePath_to_Import, File_to_Import)

evalc(strcat("Data = ", Step, "(Data, """, Choice, """, """, SubjectName, """, """, FilePath_to_Import, """, """, File_to_Import, """);"));

 %functionname = Step;
 %functionname = str2func(functionname);
 %Data = functionname(Data, Choice, SubjectName);
end

       