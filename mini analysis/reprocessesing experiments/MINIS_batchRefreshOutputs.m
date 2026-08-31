function cellData = MINIS_batchRefreshOutputs(cellData,dataFile)
% Processor for MINIS_batchProcess.
%
% For an already-analyzed cell:
%   1) add generalized settings if missing
%   2) update Population / PopulationLong
%   3) regenerate baseline validation figures
%   4) regenerate summary PDF + BinderIndex
%
% Does not recalculate trial metrics, stable ranges, or Imean.

set(groot,'defaultFigureVisible','off');

requiredVars = {'Data','S','Expt','conditions','color','figureFolder'};

for i = 1:numel(requiredVars)
    if ~isfield(cellData,requiredVars{i})
        error('%s is missing from %s.',requiredVars{i},dataFile);
    end
end

Data = cellData.Data;
S = cellData.S;
Expt = cellData.Expt;
conditions = cellData.conditions;
color = cellData.color;
figureFolder = cellData.figureFolder;

if ~isfield(S,'excludedAnalysisConditions')
    S.excludedAnalysisConditions = {'NMDA'};
    cellData.S = S;
end

MINIS_addCellToPopulation(Data,S,Expt,dataFile,conditions);
MINIS_plotBaselineValidation(Data,S,conditions,color,figureFolder);
MINIS_createCellSummaryPDF(Expt,figureFolder,true);


set(groot,'defaultFigureVisible','on');
end
