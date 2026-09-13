function [Data,Expt,Population,PopulationLong,pdfFile,Sensitivity] = MINIS_reprocessSavedCellDual(dataFile)
% Reprocess one already-analyzed saved cell with both histogram methods.
%
% Reuses the saved stable-range selection.
% Opens the interactive whole-19-s baseline review, then finalizes the cell.
%
% Example:
%   MINIS_reprocessSavedCellDual('...\LP283b_data.mat')

dataFile = char(string(dataFile));

if ~isfile(dataFile)
    error('Data file not found: %s',dataFile);
end

cellData = load(dataFile);

required = {'Data','Expt','S','conditions','color'};

for k = 1:numel(required)
    if ~isfield(cellData,required{k})
        error('%s is missing from %s.',required{k},dataFile);
    end
end

Data = cellData.Data;
Expt = cellData.Expt;
S = cellData.S;
conditions = cellData.conditions;
color = cellData.color;

if isfield(cellData,'folder')
    folder = cellData.folder;
else
    folder = fileparts(dataFile);
end

if isfield(cellData,'figureFolder')
    figureFolder = cellData.figureFolder;
else
    figureFolder = fullfile(folder,'Matlab figures');
end

if ~exist(figureFolder,'dir')
    mkdir(figureFolder);
end

%% FORCE APPROVED ANALYSIS SETTINGS

oldBinWidth = NaN;

if isfield(S,'fitBinWidth_pA')
    oldBinWidth = S.fitBinWidth_pA;
end

S.fitBinWidth_pA = 0.5;

if ~isequaln(oldBinWidth,S.fitBinWidth_pA)
    fprintf('%s: fitBinWidth_pA %.3g -> %.3g pA\n', ...
        Expt.marker,oldBinWidth,S.fitBinWidth_pA);
end

if ~isfield(S,'maxMuShiftFromPeak_pA') || S.maxMuShiftFromPeak_pA ~= 5
    error('Saved S.maxMuShiftFromPeak_pA is not 5 pA for %s.',Expt.marker);
end

%% VERIFY STABLE SELECTION EXISTS

analysisConditions = getAnalysisConditions(conditions,S);

for c = 1:numel(analysisConditions)
    cond = analysisConditions{c};

    if ~isfield(Data.(cond),'stableMiniData') || ...
            ~isfield(Data.(cond),'stableTrialNames')
        error('Stable selection is missing for %s / %s.',Expt.marker,cond);
    end
end

%% WHOLE-19-S BASELINE REVIEW

[Data,~] = MINIS_reviewBaselineTrialExclusions( ...
    Data,S,conditions,color,Expt);

%% CALCULATE, BACK UP, SAVE, UPDATE POPULATION/PDF

[Data,Expt,Population,PopulationLong,pdfFile,Sensitivity] = ...
    MINIS_finalizeDualReanalysis( ...
    Data,S,conditions,color,figureFolder,folder,Expt,dataFile);

end


function analysisConditions = getAnalysisConditions(conditions,S)

if isfield(S,'excludedAnalysisConditions')
    excluded = S.excludedAnalysisConditions;
elseif isfield(S,'drugCondition')
    excluded = {S.drugCondition};
else
    excluded = {'NMDA'};
end

mask = ~ismember(lower(string(conditions)),lower(string(excluded)));
analysisConditions = conditions(mask);

end
