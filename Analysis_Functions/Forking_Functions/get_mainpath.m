function [MainPath] = get_mainpath(DESIGN, Filepath, Filename, Exceptions)

    if nargin < 4
        Exceptions = {'No_Exceptions', ''};
    end

    % [ocs] CHANGED Added option to skip saving the file
    if nargin < 2, saveToFile = false;
    else, saveToFile = true; end

    Step_Names = fieldnames(DESIGN);
    MainPath = "";
    for iStep = 1:length(Step_Names)
        if any(contains(Exceptions(:, 1), Step_Names(iStep)))
            IdException = find(contains(Exceptions(:, 1), Step_Names(iStep)));
            MainPath = MainPath + "%" + Exceptions{find(contains(Exceptions(:, 1), Step_Names(iStep))), 2};
        else
            MainPath = MainPath + "%" + DESIGN.(Step_Names{iStep}).Choices(1);
        end
    end
    MainPath = char(MainPath); MainPath(1) = [];
    MainPath = convertCharsToStrings(MainPath);

    % [ocs] CHANGED Added option to skip saving the file
    if saveToFile
        % [osc] ??? Why do we double the resulting line?
        MainPath = [MainPath; MainPath];
        save(strcat(Filepath, Filename, '.mat'), "MainPath");
        MainPath = MainPath(1, :);
    end

end
