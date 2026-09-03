%function Inventory = makeEphysExperimentInventory(SummaryStruct)

% makeEphysExperimentInventory
%
% Creates a flat table showing which experiments exist in which condition
% fields of a summary struct like AgaTK or ConoGVIA.

% Want to split the original AgaTK/ConoGVIA summary structures into smaller
% variables to split out the older datasets (CdCl2 etc) from the currently
% working datasets. This looks at which experiments are contained in each
% gorup (Control, AgaTK_CdCl2, AgaTK etc), and makes a table that lists
% which experiments are in each category. 

condNames = fieldnames(SummaryStruct); % SummaryStruct is the big dataset you're startign with 

% Collect all experiment names from all condition fields
allExpts = {};

for c = 1:numel(condNames)
    cond = condNames{c};

    if isempty(SummaryStruct.(cond))
        continue
    end

    if isfield(SummaryStruct.(cond), 'Expt')
        exptsThisCond = {SummaryStruct.(cond).Expt};
        allExpts = [allExpts, exptsThisCond];
    end
end

allExpts = unique(allExpts(:), 'stable');

% Initialize table
Inventory = table();
Inventory.Expt = string(allExpts);

% Add one logical column per condition
for c = 1:numel(condNames)
    cond = condNames{c};

    hasCond = false(numel(allExpts), 1);

    if isempty(SummaryStruct.(cond)) || ~isfield(SummaryStruct.(cond), 'Expt')
        Inventory.(cond) = hasCond;
        continue
    end

    exptsThisCond = string({SummaryStruct.(cond).Expt});

    for e = 1:numel(allExpts)
        hasCond(e) = any(exptsThisCond == string(allExpts{e}));
    end

    Inventory.(cond) = hasCond;
end

% Count how many conditions each experiment has
conditionMatrix = table2array(Inventory(:, 2:end));
Inventory.NumConditions = sum(conditionMatrix, 2);


%%
% sort by experiment name 
Inventory = sortrows(Inventory, 'Expt'); 

% make a "current experiments" mask
% Keeps: Control → AgaTK → Muscarine
% Control → AgaTK → AMN082
% AgaTK → Muscarine
% AgaTK → AMN082

% Archives: Control → AgaTK only
% Control → AgaTK → CdCl2
% AgaTK → CdCl2
hasCdCl2 = Inventory.ConoGVIA_CdCl2;
hasMuscarine = Inventory.ConoGVIA_Muscarine;
hasAMN082 = ...
    Inventory.ConoGVIA_10uM_AMN082 | ...
    Inventory.ConoGVIA_100uM_AMN082;

% marking current experiments as any that have musc/AMN082
hasCurrentDrug = hasMuscarine | hasAMN082;

currentMask = hasCurrentDrug & ~hasCdCl2;
archiveMask = ~currentMask;

% separate current from archived experiments 
CurrentInventory = Inventory(currentMask, :);
ArchiveInventory = Inventory(~currentMask, :);

% get experiment names
currentExpts = cellstr(CurrentInventory.Expt);
archiveExpts = cellstr(ArchiveInventory.Expt);

% save split parts
ephysDataFolder = 'C:\Users\Lauren Panzera\Cardin-Higley Lab Dropbox\HigleyLab Team Folder\Lauren\Data Summaries\EPSC PP trains Aga Cono Musc';
save(fullfile(ephysDataFolder, 'ConoGVIA_Inventory_Jun2026.mat'), ...
    'Inventory', 'CurrentInventory', 'ArchiveInventory', ...
    'currentExpts', 'archiveExpts')

%%
function [CurrentStruct, ArchiveStruct] = splitSummaryStructByExptList(SummaryStruct, currentExpts)
% splitSummaryStructByExptList
%
% Splits a summary struct like AgaTK into current/archive structs
% based on experiment marker.
%
% INPUTS:
%   SummaryStruct : e.g. AgaTK (the big main one that you're splitting)
%   currentExpts  : cell array of experiment markers to keep active
%
% OUTPUTS:
%   CurrentStruct : entries whose Expt is in currentExpts
%   ArchiveStruct : entries whose Expt is NOT in currentExpts

condNames = fieldnames(SummaryStruct);

CurrentStruct = struct();
ArchiveStruct = struct();

for c = 1:numel(condNames)

    cond = condNames{c};

    if isempty(SummaryStruct.(cond))
        CurrentStruct.(cond) = SummaryStruct.(cond);
        ArchiveStruct.(cond) = SummaryStruct.(cond);
        continue
    end

    exptNames = {SummaryStruct.(cond).Expt};

    isCurrent = ismember(exptNames, currentExpts);

    CurrentStruct.(cond) = SummaryStruct.(cond)(isCurrent);
    ArchiveStruct.(cond) = SummaryStruct.(cond)(~isCurrent);
end
ConoGVIA_current = CurrentStruct;
ConoGVIA_archive = ArchiveStruct;

end


%%
save(fullfile(ephysDataFolder, 'EPSCsConoGVIA_current'), "ConoGVIA_current");
save(fullfile(ephysDataFolder, 'EPSCsConoGVIA_archive'), "ConoGVIA_archive");





