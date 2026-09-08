%% One-time migration from study-specific BinderIndex to recording-type binders
% This script DOES NOT delete or overwrite the old mIPSC_NMDA_BinderIndex.mat.
% It creates:
%   ...\Synaptic Currents\mIPSC\mIPSC_BinderIndex.mat
%   ...\Synaptic Currents\sIPSC\sIPSC_BinderIndex.mat
%
% Change calciumStudyID below if you prefer a different label before running.

calciumStudyID = "AgaConoSnx";

rootFolder = '\\bunson\bunson\Higley_Lab\Lauren bunsen\Data Summaries\Synaptic Currents';
dataRoot = '\\bunson\bunson\Higley_Lab\Lauren bunsen';
oldIndexFile = fullfile(rootFolder,'mIPSC','NMDA','mIPSC_NMDA_BinderIndex.mat');

if ~isfile(oldIndexFile)
    error('Old BinderIndex not found: %s',oldIndexFile);
end

tmp = load(oldIndexFile,'BinderIndex');

if ~isfield(tmp,'BinderIndex') || ~istable(tmp.BinderIndex)
    error('Old file does not contain a BinderIndex table.');
end

BinderIndex = canonicalizeBinderIndex(tmp.BinderIndex);

% Repair the stored file/figure paths while preserving the historical cell list.
for i = 1:height(BinderIndex)
    marker = char(BinderIndex.Marker(i));
    requestedFile = char(BinderIndex.DataFile(i));
    dataFile = resolveActiveExperimentFile(marker,requestedFile,dataRoot);
    cellFolder = fileparts(dataFile);

    BinderIndex.DataFile(i) = string(dataFile);
    BinderIndex.FigureFolder(i) = string(fullfile(cellFolder,'Matlab figures'));
    BinderIndex.SummaryFig(i) = string(fullfile(cellFolder,[marker '_summary.fig']));
    BinderIndex.SummaryPDF(i) = string(fullfile(cellFolder,[marker '_summary.pdf']));
end

% Recording subtype and study identity.
BinderIndex.RecordingType(:) = "mIPSC";
BinderIndex.StudyID(:) = "NMDA";

idx287c = BinderIndex.Marker == "LP287c";
BinderIndex.StudyID(idx287c) = calciumStudyID;

idx288a = BinderIndex.Marker == "LP288a";
BinderIndex.RecordingType(idx288a) = "sIPSC";
BinderIndex.StudyID(idx288a) = "NMDA";

% Historical/current population decisions recovered from the original binder.
includedNMDA = ["LP279b","LP279c","LP280c","LP280e","LP281a","LP281d", ...
    "LP282a","LP283b","LP285a","LP285d","LP285e","LP287b"];

BinderIndex.IncludeInPopulation(:) = false;
BinderIndex.IncludeInPopulation(ismember(BinderIndex.Marker,includedNMDA)) = true;
BinderIndex.IncludeInPopulation(idx288a) = true;

BinderIndex.ExclusionReason(:) = "";
BinderIndex.ExclusionReason(BinderIndex.Marker == "LP283d") = ...
    "Unstable baseline across the recording; no stable analysis range.";
BinderIndex.ExclusionReason(BinderIndex.Marker == "LP284b") = ...
    "Historically excluded: within-trial baseline waviness produced bimodal whole-trial histograms.";
BinderIndex.ExclusionReason(idx287c) = ...
    "Separate calcium-channel-blocker analysis with no NMDA exposure; not part of the NMDA population.";

% Split into recording-type-wide BinderIndex files.
mIPSC_BinderIndex = BinderIndex(BinderIndex.RecordingType == "mIPSC",:);
sIPSC_BinderIndex = BinderIndex(BinderIndex.RecordingType == "sIPSC",:);

mIPSC_BinderIndex = sortrows(mIPSC_BinderIndex,'Marker');
sIPSC_BinderIndex = sortrows(sIPSC_BinderIndex,'Marker');

mIPSCFolder = fullfile(rootFolder,'mIPSC');
sIPSCFolder = fullfile(rootFolder,'sIPSC');

if ~exist(mIPSCFolder,'dir'); mkdir(mIPSCFolder); end
if ~exist(sIPSCFolder,'dir'); mkdir(sIPSCFolder); end

mIPSCFile = fullfile(mIPSCFolder,'mIPSC_BinderIndex.mat');
sIPSCFile = fullfile(sIPSCFolder,'sIPSC_BinderIndex.mat');

backupExisting(mIPSCFile);
backupExisting(sIPSCFile);

BinderIndex = mIPSC_BinderIndex; %#ok<NASGU>
save(mIPSCFile,'BinderIndex');

BinderIndex = sIPSC_BinderIndex; %#ok<NASGU>
save(sIPSCFile,'BinderIndex');

fprintf('\nCreated recording-type BinderIndexes:\n%s\n%s\n',mIPSCFile,sIPSCFile);
fprintf('mIPSC rows: %d\n',height(mIPSC_BinderIndex));
fprintf('sIPSC rows: %d\n',height(sIPSC_BinderIndex));
fprintf('Old BinderIndex left untouched:\n%s\n',oldIndexFile);

%% HELPERS

function BinderIndex = canonicalizeBinderIndex(BinderIndex)

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
isArchive = contains(lower(matches),lower("\Reprocess Archive\"));
matches = matches(~isArchive);

if isempty(matches)
    error('No active saved data file found for %s.',marker);
end

if ~isempty(requestedFile)
    [~,requestedName,requestedExt] = fileparts(requestedFile);
    requestedBase = string([requestedName requestedExt]);

    [~,candidateNamesOnly,candidateExts] = cellfun(@fileparts,cellstr(matches),'UniformOutput',false);
    candidateBase = string(strcat(candidateNamesOnly,candidateExts));
    sameName = strcmpi(candidateBase,requestedBase);

    if sum(sameName) == 1
        dataFile = char(matches(sameName));
        return
    elseif sum(sameName) > 1
        error('Multiple active files match the stored filename for %s:\n%s', ...
            marker,strjoin(matches(sameName),newline));
    end
end

if numel(matches) == 1
    dataFile = char(matches);
    return
end

error('Multiple active saved files found for %s and the stored filename did not resolve them:\n%s', ...
    marker,strjoin(matches,newline));

end

function backupExisting(file)

if ~isfile(file)
    return
end

[folder,name,ext] = fileparts(file);
stamp = datestr(now,'yyyymmdd_HHMMSS');
backup = fullfile(folder,[name '_backup_' stamp ext]);
copyfile(file,backup);
fprintf('Backed up existing file: %s\n',backup);

end
