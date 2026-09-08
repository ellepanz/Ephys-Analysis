function Results = MINIS_batchReprocessPopulation(Expt,varargin)
% Batch-reprocess saved spontaneous-current cells with the current histogram analysis.
%
% The BinderIndex supplies the historical cell list. Saved deleted/stable-trial
% choices are reused; no interactive QC is repeated.
%
% Default behavior is a DRY RUN:
%   - cell files are loaded
%   - current histogram metrics are recalculated in memory
%   - nothing is saved or overwritten
%
% Example:
%   Expt.recordingType = 'mIPSC';
%   Expt.studyID = 'NMDA';
%   Results = MINIS_batchReprocessPopulation(Expt, ...
%       'ExcludeCellIDs',{'LP288a'});
tic 
paths = MINIS_getPopulationPaths(Expt);

p = inputParser;
addParameter(p,'BinderIndexFile',paths.binderIndexFile,@(x) ischar(x) || isstring(x)); % where BatchIndex.mat file is
addParameter(p,'DataRoot','\\bunson\bunson\Higley_Lab\Lauren bunsen',@(x) ischar(x) || isstring(x)); % sets bunsen top-level folder
addParameter(p,'ExcludeCellIDs',{},@(x) iscell(x) || isstring(x) || ischar(x)); % which cells to deliberately skip. {}default means skip nothing
addParameter(p,'SaveCellData',false,@(x) islogical(x) && isscalar(x)); % controls whether newly recalculated values are written back into each .mat file. default FALSE 
addParameter(p,'UpdatePopulation',false,@(x) islogical(x) && isscalar(x)); % controls whether population variable is updated
addParameter(p,'BackupBeforeSave',true,@(x) islogical(x) && isscalar(x)); % default true, makes a backup copy of the cell's original .mat file before overwriting
addParameter(p,'RefreshCellFigures',false,@(x) islogical(x) && isscalar(x)); % controls whether the cell-level MATLAB figures are regenerated 
addParameter(p,'RefreshCellPDFs',false,@(x) islogical(x) && isscalar(x)); % control whether the cell summary PDFs are recreated
addParameter(p,'StopOnError',false,@(x) islogical(x) && isscalar(x)); % default false = records any errors but keeps processing. 
parse(p,varargin{:});

binderIndexFile = char(p.Results.BinderIndexFile);
dataRoot = char(p.Results.DataRoot);
excludeCellIDs = lower(string(p.Results.ExcludeCellIDs));

if ~isfile(binderIndexFile)
    error('BinderIndex file not found: %s',binderIndexFile);
end

tmp = load(binderIndexFile,'BinderIndex');

if ~isfield(tmp,'BinderIndex') || ~istable(tmp.BinderIndex)
    error('BinderIndex file does not contain a BinderIndex table.');
end

BinderIndex = tmp.BinderIndex;

% Recording-wide BinderIndex: only process rows belonging to the requested study.
if ~ismember('StudyID',BinderIndex.Properties.VariableNames)
    error('BinderIndex must contain StudyID before using a recording-wide binder.');
end

rowStudyID = strtrim(string(BinderIndex.StudyID));
targetStudyID = strtrim(string(Expt.studyID));

if any(strlength(rowStudyID) == 0)
    warning('%d BinderIndex row(s) have blank StudyID and will be skipped.', ...
        sum(strlength(rowStudyID) == 0));
end

BinderIndex = BinderIndex(strcmpi(rowStudyID,targetStudyID),:);

if isempty(BinderIndex)
    error('No BinderIndex rows found for studyID %s.',targetStudyID);
end

if ismember('Marker',BinderIndex.Properties.VariableNames)
    binderMarkers = string(BinderIndex.Marker);
elseif ismember('CellID',BinderIndex.Properties.VariableNames)
    binderMarkers = string(BinderIndex.CellID);
else
    error('BinderIndex must contain Marker or CellID.');
end

if ismember('DataFile',BinderIndex.Properties.VariableNames)
    requestedFiles = string(BinderIndex.DataFile);
else
    requestedFiles = strings(height(BinderIndex),1);
end

nCells = height(BinderIndex);

CellID = binderMarkers;
RequestedDataFile = requestedFiles;
ResolvedDataFile = strings(nCells,1);
OldBinWidth_pA = nan(nCells,1);
NewBinWidth_pA = nan(nCells,1);
AnalysisConditions = strings(nCells,1);
Status = strings(nCells,1);
Message = strings(nCells,1);
ErrorFunction = strings(nCells,1);
ErrorLine = nan(nCells,1);
ElapsedSec = nan(nCells,1);

set(groot,'defaultFigureVisible','off');
cleanupObj = onCleanup(@() set(groot,'defaultFigureVisible','on')); %#ok<NASGU>

for i = 1:nCells

    tStart = tic;
    marker = char(CellID(i));
    requestedFile = char(RequestedDataFile(i));

    fprintf('\n========================================\n');
    fprintf('Cell %d/%d: %s\n',i,nCells,marker);
    fprintf('========================================\n');

    try
        if ismember(lower(string(marker)),excludeCellIDs)
            Status(i) = "SKIPPED_EXCLUDED";
            Message(i) = "Explicitly excluded from this batch.";
            fprintf('Skipped: explicitly excluded.\n');
            ElapsedSec(i) = toc(tStart);
            continue
        end

        dataFile = resolveActiveExperimentFile(marker,requestedFile,dataRoot);
        ResolvedDataFile(i) = string(dataFile);
        fprintf('Using: %s\n',dataFile);

        cellData = load(dataFile);

        [matchesTarget,reason] = metadataMatchesTarget(cellData,Expt,dataFile);

        if ~matchesTarget
            Status(i) = "SKIPPED_METADATA_MISMATCH";
            Message(i) = reason;
            fprintf('Skipped: %s\n',reason);
            ElapsedSec(i) = toc(tStart);
            continue
        end

        [cellData,oldBinWidth] = reprocessOneCell(cellData,dataFile,Expt);

        OldBinWidth_pA(i) = oldBinWidth;
        NewBinWidth_pA(i) = cellData.S.fitBinWidth_pA;
        AnalysisConditions(i) = strjoin(string(cellData.Data.analysisConditions),', ');

        % Stamp target metadata BEFORE any optional save.
        cellData.Expt.recordingType = Expt.recordingType;
        cellData.Expt.studyID = Expt.studyID;

        % Saved paths may be stale after moving experiments into month folders.
        cellFolder = fileparts(dataFile);
        cellData.folder = cellFolder;
        cellData.figureFolder = fullfile(cellFolder,'Matlab figures');

        if p.Results.SaveCellData
            backupDataFile(dataFile,p.Results.BackupBeforeSave);
            save(dataFile,'-struct','cellData','-v7.3');
        end

        if p.Results.UpdatePopulation
            if ~ismember('IncludeInPopulation',BinderIndex.Properties.VariableNames)
                error('BinderIndex must contain IncludeInPopulation before UpdatePopulation can be used.');
            end

            if BinderIndex.IncludeInPopulation(i)
                MINIS_addCellToPopulation( ...
                    cellData.Data,cellData.S,cellData.Expt,dataFile,cellData.conditions);
            else
                fprintf('Population skipped: BinderIndex IncludeInPopulation is false.\n');
            end
        end

        if p.Results.RefreshCellFigures
            refreshCellFigures(cellData);
        end

        if p.Results.RefreshCellPDFs
            MINIS_createCellSummaryPDF( ...
                cellData.Expt,cellData.figureFolder,true,cellData.conditions,dataFile);
        end

        Status(i) = "OK";

    catch ME
        Status(i) = "ERROR";
        Message(i) = string(ME.message);

        if ~isempty(ME.stack)
            ErrorFunction(i) = string(ME.stack(1).name);
            ErrorLine(i) = ME.stack(1).line;
            warning('%s failed in %s at line %d: %s', ...
                marker,ME.stack(1).name,ME.stack(1).line,ME.message);
        else
            warning('%s failed: %s',marker,ME.message);
        end

        if p.Results.StopOnError
            rethrow(ME);
        end
    end

    ElapsedSec(i) = toc(tStart);
end

Results = table(CellID,RequestedDataFile,ResolvedDataFile,OldBinWidth_pA, ...
    NewBinWidth_pA,AnalysisConditions,Status,Message,ErrorFunction,ErrorLine,ElapsedSec);

fprintf('\n========================================\n');
fprintf('Batch reprocess complete.\n');
fprintf('Successful: %d\n',sum(Status=="OK"));
fprintf('Failed:     %d\n',sum(Status=="ERROR"));
fprintf('Excluded:   %d\n',sum(Status=="SKIPPED_EXCLUDED"));
fprintf('Mismatch:   %d\n',sum(Status=="SKIPPED_METADATA_MISMATCH"));
fprintf('========================================\n');

end


function [cellData,oldBinWidth] = reprocessOneCell(cellData,dataFile,targetExpt)

requiredVars = {'Data','Expt','conditions'};

for i = 1:numel(requiredVars)
    if ~isfield(cellData,requiredVars{i})
        error('%s is missing from %s.',requiredVars{i},dataFile);
    end
end

defaults = MINIS_defaultSettings;

if ~isfield(cellData,'S') || isempty(cellData.S)
    oldBinWidth = NaN;
    cellData.S = fillMissingSettings(struct,defaults,cellData.Expt);
else
    if isfield(cellData.S,'fitBinWidth_pA') && ~isempty(cellData.S.fitBinWidth_pA)
        oldBinWidth = cellData.S.fitBinWidth_pA;
    else
        oldBinWidth = NaN;
    end

    cellData.S = fillMissingSettings(cellData.S,defaults,cellData.Expt);
end

% The saved stableMiniData has already been filtered, so do not silently
% reinterpret data generated with a different smoothing window/order.
if isfield(cellData.S,'sgFrame') && cellData.S.sgFrame ~= defaults.sgFrame
    error('Saved S.sgFrame is %g, but current approved sgFrame is %g.', ...
        cellData.S.sgFrame,defaults.sgFrame);
end

if isfield(cellData.S,'sgOrder') && cellData.S.sgOrder ~= defaults.sgOrder
    error('Saved S.sgOrder is %g, but current approved sgOrder is %g.', ...
        cellData.S.sgOrder,defaults.sgOrder);
end

% Force the current APPROVED histogram-analysis settings.
cellData.S.fitBinWidth_pA = defaults.fitBinWidth_pA;
cellData.S.maxMuShiftFromPeak_pA = defaults.maxMuShiftFromPeak_pA;
cellData.S.sgFrame = defaults.sgFrame;
cellData.S.sgOrder = defaults.sgOrder;

% Preserve acquisition-specific settings such as Fs and trial interval.
cellData.S = configureAnalysisConditions(cellData.S,cellData.Data,cellData.conditions);

cellData.Data = ensureStableMiniData( ...
    cellData.Data,cellData.S,cellData.conditions);

cellData.Data = MINIS_calculateHistogramMetrics( ...
    cellData.Data,cellData.S,cellData.conditions);

cellData.Expt.recordingType = targetExpt.recordingType;
cellData.Expt.studyID = targetExpt.studyID;
cellData = stampReprocessHistory(cellData,dataFile);

end


function S = fillMissingSettings(S,defaults,Expt)

hadTrialInterval = isfield(S,'trialStartIntervalSec') && ...
    ~isempty(S.trialStartIntervalSec);

defaultFields = fieldnames(defaults);

for i = 1:numel(defaultFields)
    fieldName = defaultFields{i};

    if ~isfield(S,fieldName) || isempty(S.(fieldName))
        S.(fieldName) = defaults.(fieldName);
    end
end

% Older experiments sometimes stored the actual trial interval in Expt.
if ~hadTrialInterval && isfield(Expt,'trialInterval') && ~isempty(Expt.trialInterval)
    S.trialStartIntervalSec = Expt.trialInterval;
end

S.miniSamples = round(S.miniDurationSec*S.Fs);
S.baselineSamples = round(S.baselineWindowSec*S.Fs);
S.sealStartIdx = round(S.testPulseStartSec*S.Fs) + 1;
S.sealSamples = round(S.testPulseDurationSec*S.Fs);
S.sealEndIdx = S.sealStartIdx + S.sealSamples - 1;

end


function S = configureAnalysisConditions(S,Data,conditions)

conditions = cellstr(string(conditions));

% NMDA induction itself is never part of the stable final analysis.
excluded = conditions(strcmpi(conditions,'NMDA'));

% Older cells may only have saved stable selections for control and washout.
% Exclude any condition for which a stable range cannot be recovered.
for c = 1:numel(conditions)
    cond = conditions{c};

    if strcmpi(cond,'NMDA')
        continue
    end

    if ~hasRecoverableStableData(Data,cond)
        excluded{end+1} = cond; %#ok<AGROW>
    end
end

S.excludedAnalysisConditions = unique(excluded,'stable');

analysisConditions = conditions( ...
    ~ismember(lower(string(conditions)),lower(string(S.excludedAnalysisConditions))));

if isempty(analysisConditions)
    error('No conditions with recoverable stable data remain for analysis.');
end

if ~isfield(S,'controlCondition') || ...
        ~any(strcmpi(S.controlCondition,analysisConditions))
    S.controlCondition = chooseControlCondition(analysisConditions);
end

if ~isfield(S,'washCondition') || ...
        ~any(strcmpi(S.washCondition,analysisConditions))
    S.washCondition = chooseWashCondition(analysisConditions);
end

if strcmpi(S.controlCondition,S.washCondition)
    error('Control and wash conditions resolved to the same condition: %s.',S.controlCondition);
end

end


function tf = hasRecoverableStableData(Data,cond)

tf = false;

if ~isfield(Data,cond)
    return
end

condData = Data.(cond);

if isfield(condData,'stableMiniData') && ~isempty(condData.stableMiniData)
    tf = true;
elseif isfield(condData,'stableNotDelIdx') && ~isempty(condData.stableNotDelIdx) && ...
        isfield(condData,'notDelMiniData') && ~isempty(condData.notDelMiniData)
    tf = true;
elseif isfield(condData,'stableTrialNames') && ~isempty(condData.stableTrialNames) && ...
        isfield(condData,'notDelMiniTrials') && ~isempty(condData.notDelMiniTrials)
    tf = true;
end

end


function cond = chooseControlCondition(analysisConditions)

labels = lower(string(analysisConditions));
idx = find(contains(labels,'nbqx'),1,'first');

if isempty(idx)
    idx = 1;
end

cond = analysisConditions{idx};

end


function cond = chooseWashCondition(analysisConditions)

labels = lower(string(analysisConditions));
idx = find(contains(labels,'wash'),1,'last');

if isempty(idx)
    error('Could not identify a wash condition from: %s', ...
        strjoin(analysisConditions,', '));
end

cond = analysisConditions{idx};

end


function Data = ensureStableMiniData(Data,S,conditions)

conditions = cellstr(string(conditions));

analysisConditions = conditions( ...
    ~ismember(lower(string(conditions)),lower(string(S.excludedAnalysisConditions))));

for c = 1:numel(analysisConditions)
    cond = analysisConditions{c};

    if ~isfield(Data,cond)
        error('Data.%s is missing.',cond);
    end

    if ~isfield(Data.(cond),'stableMiniData') || isempty(Data.(cond).stableMiniData)

        if isfield(Data.(cond),'stableNotDelIdx') && ...
                isfield(Data.(cond),'notDelMiniData')
            idx = Data.(cond).stableNotDelIdx;
            Data.(cond).stableMiniData = Data.(cond).notDelMiniData(:,idx);

        elseif isfield(Data.(cond),'stableTrialNames') && ...
                isfield(Data.(cond),'notDelMiniTrials')
            Data.(cond).stableMiniData = stableTrialsFromStruct( ...
                Data.(cond).notDelMiniTrials,Data.(cond).stableTrialNames);

        else
            error('Data.%s does not contain enough information to reconstruct stableMiniData.',cond);
        end
    end

    if ~isfield(Data.(cond),'stableTrialTimeMin') || ...
            isempty(Data.(cond).stableTrialTimeMin)
        Data.(cond).stableTrialTimeMin = inferStableTrialTime(Data.(cond),S);
    end
end

end


function stableMiniData = stableTrialsFromStruct(trialStruct,trialNames)

trialNames = cellstr(string(trialNames));
nTrials = numel(trialNames);

if nTrials == 0
    stableMiniData = [];
    return
end

firstTrial = trialStruct.(trialNames{1});
stableMiniData = nan(numel(firstTrial),nTrials);

for k = 1:nTrials
    stableMiniData(:,k) = trialStruct.(trialNames{k})(:);
end

end


function stableTrialTimeMin = inferStableTrialTime(condData,S)

if isfield(condData,'stableNotDelIdx') && isfield(condData,'trialTimeMin')
    stableTrialTimeMin = condData.trialTimeMin(condData.stableNotDelIdx);

elseif isfield(condData,'stableTrialNums') && ~isempty(condData.stableTrialNums)
    firstTrial = min(condData.stableTrialNums);
    stableTrialTimeMin = ...
        ((condData.stableTrialNums-firstTrial)*S.trialStartIntervalSec)/60;

else
    nTrials = size(condData.stableMiniData,2);
    stableTrialTimeMin = ((0:nTrials-1)*S.trialStartIntervalSec)/60;
end

end


function [tf,reason] = metadataMatchesTarget(cellData,targetExpt,dataFile)

tf = true;
reason = "";

if ~isfield(cellData,'Expt') || isempty(cellData.Expt)
    return
end

if isfield(cellData.Expt,'recordingType') && ...
        ~isempty(cellData.Expt.recordingType) && ...
        ~strcmpi(string(cellData.Expt.recordingType),string(targetExpt.recordingType))
    tf = false;
    reason = sprintf('Saved recordingType is %s, target batch is %s.', ...
        string(cellData.Expt.recordingType),string(targetExpt.recordingType));
    return
end

if isfield(cellData.Expt,'studyID') && ...
        ~isempty(cellData.Expt.studyID) && ...
        ~strcmpi(string(cellData.Expt.studyID),string(targetExpt.studyID))
    tf = false;
    reason = sprintf('Saved studyID is %s, target batch is %s.', ...
        string(cellData.Expt.studyID),string(targetExpt.studyID));
    return
end

% Extra guard for old files missing recordingType metadata.
pathText = lower(string(dataFile));

if strcmpi(string(targetExpt.recordingType),"mIPSC") && contains(pathText,"sipsc")
    tf = false;
    reason = "File path indicates sIPSC, not mIPSC.";
elseif strcmpi(string(targetExpt.recordingType),"sIPSC") && contains(pathText,"mipsc")
    tf = false;
    reason = "File path indicates mIPSC, not sIPSC.";
end

end


function dataFile = resolveActiveExperimentFile(marker,requestedFile,dataRoot)

candidateNames = {[marker '.mat'],[marker '_data.mat']};
matches = strings(0,1);

for n = 1:numel(candidateNames)
    d = dir(fullfile(dataRoot,'**',candidateNames{n}));

    if isempty(d)
        continue
    end

    these = string(fullfile({d.folder},{d.name}))';
    matches = [matches; these]; %#ok<AGROW>
end

matches = unique(matches,'stable');

% Never reprocess archived backup copies.
isArchive = contains(lower(matches),lower("\Reprocess Archive\"));
matches = matches(~isArchive);

if isempty(matches)
    error('No active saved data file found for %s under %s.',marker,dataRoot);
end

% Prefer the filename stored in BinderIndex, while ignoring its stale folder.
if ~isempty(requestedFile)
    [~,requestedName,requestedExt] = fileparts(requestedFile);
    requestedBase = string([requestedName requestedExt]);

    [~,candidateNamesOnly,candidateExts] = cellfun(@fileparts,cellstr(matches), ...
        'UniformOutput',false);
    candidateBase = string(strcat(candidateNamesOnly,candidateExts));

    sameName = strcmpi(candidateBase,requestedBase);

    if sum(sameName) == 1
        dataFile = char(matches(sameName));
        return
    elseif sum(sameName) > 1
        error('Multiple active files match the BinderIndex filename for %s:\n%s', ...
            marker,strjoin(matches(sameName),newline));
    end
end

if numel(matches) == 1
    dataFile = char(matches);
    return
end

error('Multiple active saved files found for %s and BinderIndex did not resolve them:\n%s', ...
    marker,strjoin(matches,newline));

end


function cellData = stampReprocessHistory(cellData,dataFile)

entry = struct;
entry.dateTime = datetime('now');
entry.processor = "MINIS_batchReprocessPopulation";
entry.sourceDataFile = string(dataFile);
entry.analysisMethod = string(cellData.Data.finalAnalysisMethod);
entry.analysisEpochSec = cellData.Data.finalAnalysisEpochSec;
entry.analysisBinWidth_pA = cellData.Data.finalAnalysisBinWidth_pA;
entry.note = "Reprocessed using saved QC/stable-trial choices and the approved 1-s local Gaussian histogram charge/current analysis.";

if ~isfield(cellData.Expt,'reprocessHistory') || isempty(cellData.Expt.reprocessHistory)
    cellData.Expt.reprocessHistory = entry;
elseif isstruct(cellData.Expt.reprocessHistory)
    cellData.Expt.reprocessHistory(end+1) = entry;
else
    cellData.Expt.previousReprocessHistory = cellData.Expt.reprocessHistory;
    cellData.Expt.reprocessHistory = entry;
end

cellData.Expt.lastReprocessDate = entry.dateTime;
cellData.Expt.lastReprocessMethod = entry.analysisMethod;

end


function refreshCellFigures(cellData)

requiredVars = {'Data','S','conditions','color','figureFolder','Expt'};

for i = 1:numel(requiredVars)
    if ~isfield(cellData,requiredVars{i})
        error('%s is required to refresh figures.',requiredVars{i});
    end
end

if ~exist(cellData.figureFolder,'dir')
    mkdir(cellData.figureFolder);
end

MINIS_plotBaselineValidation( ...
    cellData.Data,cellData.S,cellData.conditions,cellData.color, ...
    cellData.figureFolder,cellData.Expt);

MINIS_plotSynapticExcessVariability( ...
    cellData.Data,cellData.S,cellData.conditions,cellData.color, ...
    cellData.figureFolder,cellData.Expt);

end


function backupDataFile(dataFile,backupBeforeSave)

if ~backupBeforeSave
    return
end

[folder,name,ext] = fileparts(dataFile);
archiveRoot = fullfile(folder,'Reprocess Archive');
stamp = datestr(now,'yyyymmdd_HHMMSS');
archiveFolder = fullfile(archiveRoot,[stamp '_approvedLocalHistogramReprocess']);

if ~exist(archiveFolder,'dir')
    mkdir(archiveFolder);
end

backupFile = fullfile(archiveFolder,[name ext]);
copyfile(dataFile,backupFile);
fprintf('Backed up: %s\n',backupFile);
toc
end
