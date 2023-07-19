%% Compile Relative


AnalysisName = "Gambling_RewP"
Command_To_Run = strcat("mcc -o parfor_",  AnalysisName, "_Relative", ...
    " -W main:parfor_",  AnalysisName, "_Relative", ...
    " -T link:exe -d ", '/home/bay2875/Compilations/Compile_', AnalysisName, '/',  ...
    " -v /home/bay2875/ForCompiling/Step_Functions/For_Relative/parfor_",AnalysisName, "_Relative", ...
    " -a /home/bay2875/ForCompiling/Analysis_Functions/PlugIn_Functions/MATLAB_Functions/", ...
    " -a /home/bay2875/ForCompiling/Analysis_Functions/PlugIn_Functions/custom_Indexing/");

eval(Command_To_Run)



% For Testing 
/sw/app/matlab/2019b/bin/matlab
addpath("/home/bay2875/ForCompiling/Step_Functions/For_Relative")
addpath("/home/bay2875/ForCompiling/Analysis_Functions/PlugIn_Functions/MATLAB_Functions/")
addpath("/home/bay2875/ForCompiling/Analysis_Functions/PlugIn_Functions/custom_Indexing/")
parfor_Gambling_RewP_Relative("even", "/work/bay2875/Gambling_RewP/task-Gambling/testrelative")
% For Testing Compilation
/home/bay2875/Compilations/Compile_Gambling_RewP/run_parfor_Gambling_RewP_Relative.sh /sw/app/matlab/2019b/ even /home/bay2875/ForCompiling/Step_Functions/For_Relative

%ADD MORE PRINTS TO CHECK IF IT WORKED??