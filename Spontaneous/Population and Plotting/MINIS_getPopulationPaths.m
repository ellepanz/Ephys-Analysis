function paths = MINIS_getPopulationPaths(Expt)
% Return population/binder paths from recording type and optional study ID.
%
% Binder files are recording-type-wide:
%   ...\Synaptic Currents\mIPSC\mIPSC_BinderIndex.mat
%   ...\Synaptic Currents\mIPSC\mIPSC_Binder.pdf
%
% Population files remain study-specific:
%   ...\Synaptic Currents\mIPSC\NMDA\mIPSC_NMDA_population.mat

if ~isfield(Expt,'recordingType') || isempty(Expt.recordingType)
    error('Expt.recordingType must be defined.');
end

rootFolder = '\\bunson\bunson\Higley_Lab\Lauren bunsen\Data Summaries\Synaptic Currents';

recordingType = char(string(Expt.recordingType));
safeRecordingType = regexprep(recordingType,'[^A-Za-z0-9_-]','_');

paths.rootFolder = rootFolder;
paths.recordingFolder = fullfile(rootFolder,safeRecordingType);
paths.binderIndexFile = fullfile(paths.recordingFolder,[safeRecordingType '_BinderIndex.mat']);
paths.binderFile = fullfile(paths.recordingFolder,[safeRecordingType '_Binder.pdf']);

if ~exist(paths.recordingFolder,'dir')
    mkdir(paths.recordingFolder);
end

hasStudyID = isfield(Expt,'studyID') && ~isempty(Expt.studyID);

if hasStudyID
    studyID = char(string(Expt.studyID));
    safeStudyID = regexprep(studyID,'[^A-Za-z0-9_-]','_');

    paths.studyFolder = fullfile(paths.recordingFolder,safeStudyID);
    paths.folder = paths.studyFolder; % backward-compatible population folder

    prefix = [safeRecordingType '_' safeStudyID];
    paths.populationFile = fullfile(paths.studyFolder,[prefix '_population.mat']);

    if ~exist(paths.studyFolder,'dir')
        mkdir(paths.studyFolder);
    end
else
    paths.studyFolder = '';
    paths.folder = paths.recordingFolder;
    paths.populationFile = '';
end

end
