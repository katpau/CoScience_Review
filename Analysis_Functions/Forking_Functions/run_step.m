function [Data] = run_step(Step, Data, Choice)

evalc(strcat("Data = ", Step, "(Data, """, Choice, """);"));

 %functionname = Step;
 %functionname = str2func(functionname);
 %Data = functionname(Data, Choice, SubjectName);
end

        