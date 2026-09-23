function BinderIndex = MINIS_excludeCellFromPopulation(Expt,reason,dataFile,figureFolder)
% Mark one analyzed MINIS cell as excluded from its study population.
%
% Example:
%   MINIS_excludeCellFromPopulation(Expt, ...
%       "Washout baseline never reached a stable analysis range.", ...
%       dataFile,figureFolder)
%
% This creates/updates the BinderIndex row even if the summary PDF has not
% been created yet. MINIS_createCellSummaryPDF will preserve this decision.

if nargin < 2 || strlength(string(reason)) == 0
    error('Give an exclusion reason.');
end

if nargin < 3
    dataFile = "";
end

if nargin < 4
    figureFolder = "";
end

reason = string(reason);
dataFile = string(dataFile);
figureFolder = string(figureFolder);

paths = MINIS_getPopulationPaths(Expt);
binderIndexFile = paths.binderIndexFile;

%% LOAD / CREATE BINDER INDEX

if isfile(binderIndexFile)
    tmp = load(binderIndexFile,'BinderIndex');

    if isfield(tmp,'BinderIndex') && istable(tmp.BinderIndex)
        BinderIndex = upgradeBinderIndex(tmp.BinderIndex);
    else
        BinderIndex = emptyBinderIndex();
    end
else
    BinderIndex = emptyBinderIndex();
end

%% PRESERVE EXISTING FILE/PDF PATHS IF PRESENT

idx = find(string(BinderIndex.Marker) == string(Expt.marker),1);

summaryFig = "";
summaryPDF = "";
includeValidation = false;

if ~isempty(idx)
    if strlength(dataFile) == 0
        dataFile = string(BinderIndex.DataFile(idx));
    end

    if strlength(figureFolder) == 0
        figureFolder = string(BinderIndex.FigureFolder(idx));
    end

    summaryFig = string(BinderIndex.SummaryFig(idx));
    summaryPDF = string(BinderIndex.SummaryPDF(idx));
    includeValidation = BinderIndex.IncludeValidation(idx);
end

%% FILL OBVIOUS CURRENT PATHS WHEN AVAILABLE

if strlength(dataFile) == 0 && strlength(figureFolder) > 0
    cellFolder = fileparts(char(figureFolder));
    candidate = fullfile(cellFolder,sprintf('%s_data.mat',Expt.marker));

    if isfile(candidate)
        dataFile = string(candidate);
    end
end

%% BUILD / REPLACE ROW

newRow = table( ...
    string(Expt.marker), ...
    string(Expt.recordingType), ...
    string(Expt.studyID), ...
    dataFile, ...
    figureFolder, ...
    summaryFig, ...
    summaryPDF, ...
    logical(includeValidation), ...
    false, ...
    reason, ...
    datetime('now'), ...
    'VariableNames',{ ...
    'Marker','RecordingType','StudyID','DataFile','FigureFolder', ...
    'SummaryFig','SummaryPDF','IncludeValidation','IncludeInPopulation', ...
    'ExclusionReason','LastUpdated'});

allIdx = find(string(BinderIndex.Marker) == string(Expt.marker));

if isempty(allIdx)
    BinderIndex = [BinderIndex; newRow];
else
    BinderIndex(allIdx(1),:) = newRow;

    if numel(allIdx) > 1
        BinderIndex(allIdx(2:end),:) = [];
    end
end

BinderIndex = sortrows(BinderIndex,'Marker');
save(binderIndexFile,'BinderIndex');

fprintf('%s excluded from population.\n',Expt.marker);
fprintf('Reason: %s\n',reason);
fprintf('BinderIndex: %s\n',binderIndexFile);

end


function BinderIndex = emptyBinderIndex

BinderIndex = table( ...
    strings(0,1),strings(0,1),strings(0,1),strings(0,1),strings(0,1), ...
    strings(0,1),strings(0,1),false(0,1),false(0,1),strings(0,1),NaT(0,1), ...
    'VariableNames',{ ...
    'Marker','RecordingType','StudyID','DataFile','FigureFolder', ...
    'SummaryFig','SummaryPDF','IncludeValidation','IncludeInPopulation', ...
    'ExclusionReason','LastUpdated'});

end


function BinderIndex = upgradeBinderIndex(BinderIndex)

n = height(BinderIndex);

if ~ismember('Marker',BinderIndex.Properties.VariableNames)
    error('BinderIndex is missing Marker.');
end

if ~ismember('RecordingType',BinderIndex.Properties.VariableNames)
    BinderIndex.RecordingType = strings(n,1);
end

if ~ismember('StudyID',BinderIndex.Properties.VariableNames)
    BinderIndex.StudyID = strings(n,1);
end

if ~ismember('DataFile',BinderIndex.Properties.VariableNames)
    BinderIndex.DataFile = strings(n,1);
end

if ~ismember('FigureFolder',BinderIndex.Properties.VariableNames)
    BinderIndex.FigureFolder = strings(n,1);
end

if ~ismember('SummaryFig',BinderIndex.Properties.VariableNames)
    BinderIndex.SummaryFig = strings(n,1);
end

if ~ismember('SummaryPDF',BinderIndex.Properties.VariableNames)
    BinderIndex.SummaryPDF = strings(n,1);
end

if ~ismember('IncludeValidation',BinderIndex.Properties.VariableNames)
    BinderIndex.IncludeValidation = false(n,1);
end

if ~ismember('IncludeInPopulation',BinderIndex.Properties.VariableNames)
    BinderIndex.IncludeInPopulation = false(n,1);
end

if ~ismember('ExclusionReason',BinderIndex.Properties.VariableNames)
    BinderIndex.ExclusionReason = strings(n,1);
end

if ~ismember('LastUpdated',BinderIndex.Properties.VariableNames)
    BinderIndex.LastUpdated = NaT(n,1);
end

vars = {'Marker','RecordingType','StudyID','DataFile','FigureFolder','SummaryFig', ...
    'SummaryPDF','IncludeValidation','IncludeInPopulation','ExclusionReason','LastUpdated'};

BinderIndex = BinderIndex(:,vars);

end