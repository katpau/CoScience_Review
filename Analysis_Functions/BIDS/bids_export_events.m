function bids_export_events(EEG, Filename, Filepath, EventLabels, EventTriggers, varargin)

% Writes events.JSON File and events.TSV  describing the 
% events of the EEG Data. This includes information about the duration,
% onset, trial type, verbal label, and extra fields such as RT etc.
% All of this information is read from the EEG event structure and from two
% input structures
%INPUT
% EEG = struct, EEG file (in EEGlab structure format) that includes information on 
%           the events as new fields/collumnns
% Filename = Filename of original EEG, already in BIDS format(sub-XX_task-XX), 
%           used to create the output file with similiar name
% Filepath = string, pointing to folder where Output files should be saved
% EventLabels = string array, Labels for each Trigger Type
% EventTriggers = (string/number) array of all included Triggers in the
%           file. Same length as EventLabels, and same order
% varargin = Structure including additional fields that should be included.
% Name of extra fields in the event structure. Each Field has the Name of
% the corresponding EEG.event field,  and includes a cell array. Cell array
% inlcudes at least two string entries: name of field; description; third input can be unit)
%OUTPUT
% Readable BIDS Files with same name as Filename + "_events.json",
% "_events.tsv"




% 1.) Prepare Json File - Event Descriptors
% 1.1) Constant based on EEGLAB
eInfoDesc = [];
eInfoDesc.onset.LongName = 'Event onset';
eInfoDesc.onset.Description = 'Onset (in seconds) of the event measured from the beginning of the acquisition of the first volume in the corresponding task imaging data file.';
eInfoDesc.onset.Units = 'second';

eInfoDesc.duration.LongName = 'Event duration';
eInfoDesc.duration.Description = 'Duration of the event (measured from onset) in seconds';
eInfoDesc.duration.Units = 'second';

eInfoDesc.sample.LongName = 'Sample';
eInfoDesc.sample.Description = 'Onset of the event according to the sampling scheme of the recorded modality (i.e., referring to the raw data file that the events.tsv file accompanies).';
eInfoDesc.onset.Units = 'Sampling Points';

eInfoDesc.trial_type.LongName = 'Event categorization';
eInfoDesc.trial_type.Description = 'Complete categorisation of each trial to identify them as instances of the experimental conditions.';

eInfoDesc.value.LongName = 'Event marker';
eInfoDesc.value.Description = 'Marker value associated with the event.';

if ~isempty(varargin)
optional_Fields = varargin{1,1}
    ListFields = fields(optional_Fields);
    for ifield = 1:length(ListFields)
        tmpField = ListFields{ifield};
        eInfoDesc.(tmpField).LongName = (tmpField);
        eInfoDesc.(tmpField).Description = optional_Fields.(tmpField){2};
        if length(optional_Fields.(tmpField))>2
        eInfoDesc.(tmpField).Unit = optional_Fields.(tmpField){3};
        end
    end
end



% 1.2) Get Labels for Triggers based on Input and write json file
eInfoDesc.value.Levels = [];       
   for ifield = 1:length(EventLabels)
   eInfoDesc.value.Levels.(['x', num2str(EventTriggers(ifield))]) = EventLabels(ifield);
   end
jsonwrite(char(strcat(Filepath, Filename, '_events.json')),eInfoDesc, struct('indent','  '));    
   



% 2.) Prepare tsv file
% scan events
Collumns = fieldnames(eInfoDesc);
fid = fopen( strcat(Filepath, Filename, '_events.tsv'), 'w');
% Initate Structure
str = {};
for iField = 1:numel(Collumns)
    str{end+1} = Collumns{iField};
end
strConcat = sprintf('%s\t', str{:});
fprintf(fid, '%s\n', strConcat(1:end-1));
    
for iEvent = 1:length(EEG.event)  
str = {};
    for iField = 1:numel(Collumns)
        tmpField = Collumns{iField};
        switch  tmpField
            case 'onset'
                onset = EEG.event(iEvent).latency-1/EEG.srate;
                str{end+1} = sprintf('%1.10f', onset);

            case 'duration'
                if isfield(EEG.event, tmpField) && ~isempty(EEG.event(iEvent).(tmpField))
                    duration = num2str(EEG.event(iEvent).(tmpField), '%1.10f');
                else
                    duration = 'n/a';
                end
                if isempty(duration) || strcmpi(duration, 'NaN')
                    duration = 'n/a';
                end
                str{end+1} = duration;

            case 'sample'
                if isfield(EEG.event, 'latency')
                    sample = num2str(EEG.event(iEvent).latency-1);
                else
                    sample = 'n/a';
                end
                if isempty(sample) || strcmpi(sample, 'NaN')
                    sample = 'n/a';
                end
                str{end+1} = sample;

            case 'trial_type'
                % trial type (which is the experimental condition - not the
                % same as EEGLAB) NOT CLEAR WHAT ENTRY HERE                       
                if ismember(str2num(EEG.event(iEvent).type), EventTriggers)
                   trialType =  char(eInfoDesc.value.Levels.(['x', num2str(EEG.event(iEvent).type)]));               
                else
                    trialType = 'n/a';
                end
               str{end+1} = trialType; 
              
            case 'value'
                eventValue = strcat('x', EEG.event(iEvent).type);
                str{end+1} = eventValue;
                
            otherwise
                if  ~isempty(EEG.event(iEvent).(tmpField))
                    tmpVal = char(EEG.event(iEvent).(tmpField));
                else
                    tmpVal = 'n/a';
                end
                str{end+1} = tmpVal;
        end 
    end
    strConcat = sprintf('%s\t', str{:});
    fprintf(fid, '%s\n', strConcat(1:end-1));
end
fclose(fid);
