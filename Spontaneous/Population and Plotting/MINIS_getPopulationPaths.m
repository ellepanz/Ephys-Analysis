function paths = MINIS_getPopulationPaths(Expt)
% Return population/binder paths from recording type and study ID.

requiredFields = {'recordingType','studyID'};

for k = 1:numel(requiredFields)
    if ~isfield(Expt,requiredFields{k}) || isempty(Expt.(requiredFields{k}))
        error('Expt.%s must be defined.',requiredFields{k});
    end
end

rootFolder = '\\bunson\bunson\Higley_Lab\Lauren bunsen\Data Summaries\Synaptic Currents';

recordingType = char(string(Expt.recordingType));
studyID = char(string(Expt.studyID));

safeRecordingType = regexprep(recordingType,'[^A-Za-z0-9_-]','_');
safeStudyID = regexprep(studyID,'[^A-Za-z0-9_-]','_');

paths.folder = fullfile(rootFolder,safeRecordingType,safeStudyID);

prefix = [safeRecordingType '_' safeStudyID];

paths.populationFile = fullfile(paths.folder,[prefix '_population.mat']);
paths.binderIndexFile = fullfile(paths.folder,[prefix '_BinderIndex.mat']);
paths.binderFile = fullfile(paths.folder,[prefix '_Binder.pdf']);

if ~exist(paths.folder,'dir')
    mkdir(paths.folder);
end

end