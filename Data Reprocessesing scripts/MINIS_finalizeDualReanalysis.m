function [Data,Expt,Population,PopulationLong,pdfFile,Sensitivity] = ...
    MINIS_finalizeDualReanalysis(Data,S,conditions,color,figureFolder,folder,Expt,dataFile)
% Finalize one cell after the whole-19-s baseline review.
%
% Assumes:
%   - stable trials are already selected
%   - MINIS_reviewBaselineTrialExclusions has already been completed
%
% This function:
%   1) Calculates Whole19 and Local1s analyses
%   2) Regenerates cell figures
%   3) Creates a timestamped backup of the active MAT file
%   4) Stamps explicit dual-reanalysis metadata
%   5) Saves the active cell MAT file
%   6) Adds/removes the cell from Population according to BinderIndex
%   7) Creates the updated cell summary PDF
%   8) Regenerates population figures

if nargin < 8 || strlength(string(dataFile)) == 0
    error('Pass the exact active dataFile path as the eighth input.');
end

dataFile = char(string(dataFile));

if ~isfile(dataFile)
    error('Active data file not found: %s',dataFile);
end

%% CALCULATE BOTH ANALYSES

Data = MINIS_calculateWholeTrialMetrics(Data,S,conditions);
Data = MINIS_calculateHistogramMetrics(Data,S,conditions);

%% REGENERATE PRESENTATION / QC FIGURES

MINIS_plotBaselineValidation(Data,S,conditions,color,figureFolder,Expt);
MINIS_plotSynapticExcessVariability(Data,S,conditions,color,figureFolder,Expt);

Sensitivity = MINIS_compareWholeTrialBaselineSensitivity( ...
    Data,S,conditions,color,figureFolder,Expt);

%% STAMP REANALYSIS METADATA

nowTime = datetime('now');

entry = struct;
entry.dateTime = nowTime;
entry.processor = "MINIS_finalizeDualReanalysis";
entry.sourceDataFile = string(dataFile);
entry.analysisVersion = "dualHistogram_v1";
entry.wholeTrialMethod = "Whole 19-s Gaussian; manually baseline-unstable/bimodal stable trials excluded";
entry.localMethod = "19 x 1-s local Gaussian fits; all selected stable trials retained";
entry.binWidth_pA = S.fitBinWidth_pA;
entry.wholeTrialDurationSec = 19;
entry.localEpochSec = 1;
entry.controlExcludedTrials = excludedNames(Data,S.controlCondition);
entry.washExcludedTrials = excludedNames(Data,S.washCondition);
entry.note = "Dual reanalysis for Mike whole-trial QC method and Chiayu 1-s segmented method.";

if ~isfield(Expt,'dualReanalysisHistory') || isempty(Expt.dualReanalysisHistory)
    Expt.dualReanalysisHistory = entry;
else
    Expt.dualReanalysisHistory(end+1) = entry;
end

Expt.lastReprocessDate = nowTime;
Expt.lastReprocessMethod = "Dual histogram: Whole19 baseline-QC + Local1s";

Data.dualAnalysisVersion = "dualHistogram_v1";
Data.dualReprocessDate = nowTime;
Data.dualReprocessed = true;

%% BACK UP CURRENT ACTIVE FILE BEFORE OVERWRITE

backupFile = backupDataFile(dataFile);

%% SAVE ACTIVE CELL

save(dataFile,'Data','Expt','S','conditions','color','figureFolder','folder','-v7.3');

fprintf('\nSaved dual-reprocessed cell:\n%s\n',dataFile);
fprintf('Backup created:\n%s\n',backupFile);

%% POPULATION

[Population,PopulationLong] = MINIS_addCellToPopulation( ...
    Data,S,Expt,dataFile,conditions);

%% SUMMARY PDF + BINDER INDEX

[pdfFile,~] = MINIS_createCellSummaryPDF( ...
    Expt,figureFolder,true,conditions,dataFile);

%% POPULATION FIGURES

if ~isempty(Population) && ismember('CellID',Population.Properties.VariableNames) && ...
        any(string(Population.CellID) == string(Expt.marker))
    MINIS_plotPopulation(Expt);
end

fprintf('Summary PDF: %s\n',pdfFile);
fprintf('Finished %s.\n\n',Expt.marker);

end


function names = excludedNames(Data,cond)

names = "";

if isfield(Data,cond) && ...
        isfield(Data.(cond),'baselineSensitivityExcludedTrialNames') && ...
        ~isempty(Data.(cond).baselineSensitivityExcludedTrialNames)

    names = strjoin(string(Data.(cond).baselineSensitivityExcludedTrialNames),", ");
end

end


function backupFile = backupDataFile(dataFile)

[cellFolder,name,ext] = fileparts(dataFile);
archiveRoot = fullfile(cellFolder,'Reprocess Archive');
stamp = datestr(now,'yyyymmdd_HHMMSS');
archiveFolder = fullfile(archiveRoot,[stamp '_dualHistogramReprocess']);

if ~exist(archiveFolder,'dir')
    mkdir(archiveFolder);
end

backupFile = fullfile(archiveFolder,[name ext]);

[ok,msg] = copyfile(dataFile,backupFile);

if ~ok
    error('Could not create backup before save: %s',msg);
end

end
