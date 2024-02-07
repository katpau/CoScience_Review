function bids_export_electrodes (EEG, Filename, Filepath)
% Writes electrodes.JSON  and electrodes.TSV and channels.tsv describing the 
% electrodes/channels of the EEG Data. This includes information about the Coordinate Names, 
% units, channel location
% All of this information is read from the EEG structure. This should already include
% the channel locations and the channel types.
%INPUT
% EEG = struct, EEG file (in EEGlab structure format) that includes information on 
%           EEG/EOG channels, Srate 
% Filename = Filename of original EEG, already in BIDS format(sub-XX), 
%           as this should be constant across tasks (per subject) _task-XX
%           not needed
%           used to create the output file with similiar name
% Filepath = string, pointing to folder where Output files should be saved
%OUTPUT
% Readable BIDS Files with same name as Filename + "_electrodes.json",
% "_electrodes.tsv", "_channels.tsv"


% Get Infos aboout Electrode Names and their XYZ coordinates and Channel Type
ElectrodeNames = cell(1,size(EEG.chanlocs,2));  ElectrodeNames(:) = {'n/a'};
x = ElectrodeNames; y = ElectrodeNames; z = ElectrodeNames; type = ElectrodeNames; 
for electrode = 1:size(EEG.chanlocs,2)
    if ~isempty(EEG.chanlocs(electrode).labels),ElectrodeNames{electrode} = EEG.chanlocs(electrode).labels;  end
    if ~isempty(EEG.chanlocs(electrode).X),     x{electrode}     = EEG.chanlocs(electrode).X;       end
    if ~isempty(EEG.chanlocs(electrode).Y),     y{electrode}     = EEG.chanlocs(electrode).Y;       end
    if ~isempty(EEG.chanlocs(electrode).Z),     z{electrode}     = EEG.chanlocs(electrode).Z;       end
    if ~isempty(EEG.chanlocs(electrode).type),  type{electrode}  = EEG.chanlocs(electrode).type;    end
end

% Define Units for each channel type
units = repmat({''}, 1, length(type));
units(strcmp(type, 'EEG')) = {'microV'};
units(strcmp(type, 'EOG')) = {'microV'};
units(strcmp(type, 'ECG')) = {'microV'};
units(strcmp(type, 'n/a')) = {'n/a'};


% Prepare electrode tsv file = table with channel Name, channel type,
% channel unit
t = table(ElectrodeNames',type', units', 'VariableNames',{'name','type', 'units'});
electrodes_tsv_name = strcat(Filepath, filesep, Filename, '_electrodes.tsv');
writetable(t,electrodes_tsv_name,'FileType','text','Delimiter','\t');


% Prepare channel tsv file = table with Channel Name, XYZ coordinates
t = table(ElectrodeNames',x',y',z','VariableNames',{'name','x','y','z'});
electrodes_tsv_name = strcat(Filepath, filesep, Filename, '_channels.tsv');
writetable(t,electrodes_tsv_name,'FileType','text','Delimiter','\t');


% Prepare electrode json file = Information on unit and Coordinate System
coordsystemStruct.EEGCoordinateUnits = 'mm';
coordsystemStruct.EEGCoordinateSystem = 'ARS'; % X=Anterior Y=Right Z=Superior
FileName = char(strcat(Filepath, filesep, Filename, '_electrodes.json'));
jsonwrite(FileName,coordsystemStruct, struct('indent','  '));  




