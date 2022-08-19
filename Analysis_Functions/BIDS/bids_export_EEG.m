function bids_export_EEG(EEG, Filepath, Filename, TaskDescription, LabDescription)
% Writes JSON File for the EEG Data. This includes general information
% about the recording such as what is the (Recording) Reference, what
% Powerline, Manufacturer of Caps and Information on Filters. In the
% CoScience Project, this depends on the different Labs, but also of the
% Task. Therefore this function takes variable Inputs for these
%
%INPUT
% EEG = struct, EEG file (in EEGlab structure format) that includes information on 
%           EEG/EOG channels, Srate 
% Filepath = string, pointing to folder where Json file should be saved
% Filename = Filename of original EEG, already in BIDS format(sub-XX_task-XXX), 
%           used to create the json file with similiar name
% TaskDescription = struct, with fields "Name" and "Description" of
%           Experiment
% LabDescription = struct, with fields "Reference", "Ground",
%           "Manufacturer", "CapManufacturer", "HardwareFilter", "SoftwareFilter",
%           "AcquisitionSoftware"
%OUTPUT
% Readable JSON FIle with same name as Filename + "_eeg.json"

EEGInfo.TaskName=	TaskDescription.Name ;    %REQUIRED
EEGInfo.TaskDescription= TaskDescription.Description;    %RECOMMENDED
% EEGInfo.Instructions=TaskDescription.Instruction;    %RECOMMENDED
EEGInfo.CogAtlasID='n/a';    %RECOMMENDED
EEGInfo.CogPOID='n/a';    %RECOMMENDED
EEGInfo.OrganisingIstitution='CoScience - Hamburg University';    %RECOMMENDED
EEGInfo.RecordingInstitution=LabDescription.RecordingInstitution;    %RECOMMENDED
%EEGInfo.InstitutionAddress=;    %RECOMMENDED
EEGInfo.InstitutionalDepartmentName='Dept. of Psychology';    %RECOMMENDED
%EEGInfo.DeviceSerialNumber=;    %RECOMMENDED
EEGInfo.SamplingFrequency=EEG.srate;    %REQUIRED
EEGInfo.EEGChannelCount=sum(ismember({EEG.chanlocs.type},'EEG'));    %REQUIRED
EEGInfo.EOGChannelCount=sum(ismember({EEG.chanlocs.type},'EOG'));    %REQUIRED
EEGInfo.ECGChannelCount=LabDescription.ECGChannelCount;    %REQUIRED
EEGInfo.EMGChannelCount=0;    %REQUIRED
EEGInfo.EEGReference=LabDescription.Reference;    %REQUIRED
EEGInfo.PowerLineFrequency=50;    %REQUIRED
EEGInfo.EEGGround=LabDescription.Ground;    %RECOMMENDED
%EEGInfo.HeadCircumference=;    %OPTIONAL
%EEGInfo.MiscChannelCount=;    %OPTIONAL
%EEGInfo.TriggerChannelCount=;    %RECOMMENDED
EEGInfo.EEGPlacementScheme='10-20';    %RECOMMENDED
EEGInfo.Manufacturer=LabDescription.Manufacturer;    %RECOMMENDED
%EEGInfo.ManufacturersModelName=LabDescription.Model;    %OPTIONAL
EEGInfo.CapManufacturer=LabDescription.CapManufacturer;    %RECOMMENDED
%EEGInfo.CapManufacturersModelName=LabDescription.CapModelName;    %OPTIONAL
EEGInfo.HardwareFilters=LabDescription.HardwareFilter;    %OPTIONAL
EEGInfo.SoftwareFilters=LabDescription.SoftwareFilter;    %REQUIRED
%EEGInfo.RecordingDuration=;    %RECOMMENDED
EEGInfo.RecordingType='continous';    %RECOMMENDED
EEGInfo.SoftwareVersions=LabDescription.AcquisitionSoftware;    %RECOMMENDED
%EEGInfo.SubjectArtefactDescription=;    %OPTIONAL
OutputFileName = char(strcat(Filepath, Filename, '_eeg.json')); %
jsonwrite(OutputFileName, EEGInfo, struct('indent','  '));    



