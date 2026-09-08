function [Population,PopulationLong] = MINIS_addCellToPopulation(Data,S,Expt,dataFile,conditions)
% Add/update one histogram-analyzed cell in the appropriate population file.
%
% Population:
%   One row per cell, comparing control versus washout.
%
% PopulationLong:
%   One row per cell per analyzed condition.
%
% Final synaptic metric:
%   Gaussian histogram synaptic current (pA) and charge (pC).

%% POPULATION FILE

paths = MINIS_getPopulationPaths(Expt);

populationFolder = paths.folder;
populationFile = paths.populationFile;
analysisConditions = getAnalysisConditions(conditions,S);

if ~ismember(S.controlCondition,analysisConditions)
    error('Control condition %s is not available for population analysis.',S.controlCondition);
end

if ~ismember(S.washCondition,analysisConditions)
    error('Washout condition %s is not available for population analysis.',S.washCondition);
end

%% BUILD CONDITION-LEVEL SUMMARY ROWS

longRows = table;

for c = 1:numel(analysisConditions)
    cond = analysisConditions{c};

    if ~isfield(Data.(cond),'trialHoldingCurrent')
        error('Data.%s.trialHoldingCurrent is missing. Run MINIS_calculateHistogramMetrics first.',cond);
    end

    if ~isfield(Data.(cond),'trialSynapticCurrent_pA')
        error('Data.%s.trialSynapticCurrent_pA is missing. Run MINIS_calculateHistogramMetrics first.',cond);
    end

    if ~isfield(Data.(cond),'trialSynapticCharge_pC')
        error('Data.%s.trialSynapticCharge_pC is missing. Run MINIS_calculateHistogramMetrics first.',cond);
    end

    holdingTrialMeans = Data.(cond).trialHoldingCurrent;
    synapticCurrentTrialMeans = Data.(cond).trialSynapticCurrent_pA;
    synapticChargeTrialMeans = Data.(cond).trialSynapticCharge_pC;

    avgHolding = mean(holdingTrialMeans,'omitnan');
    avgSynapticCurrent = mean(synapticCurrentTrialMeans,'omitnan');
    avgSynapticCharge = mean(synapticChargeTrialMeans,'omitnan');

    if c == 1
        previousCondition = "";
        deltaHoldingPrevious = NaN;
        deltaSynapticCurrentPrevious = NaN;
        deltaSynapticChargePrevious = NaN;
    else
        previousCondition = string(analysisConditions{c-1});
        prevHolding = longRows.AvgHolding(end);
        prevSynapticCurrent = longRows.AvgSynapticCurrent_pA(end);
        prevSynapticCharge = longRows.AvgSynapticCharge_pC(end);

        deltaHoldingPrevious = avgHolding-prevHolding;
        deltaSynapticCurrentPrevious = avgSynapticCurrent-prevSynapticCurrent;
        deltaSynapticChargePrevious = avgSynapticCharge-prevSynapticCharge;
    end

    avgRs = mean(Data.(cond).stableRs,'omitnan');
    avgRin = mean(Data.(cond).stableRin,'omitnan');

    thisRow = table(string(Expt.marker),string(Expt.recordingType),string(cond),c,previousCondition, ...
        avgHolding,avgSynapticCurrent,avgSynapticCharge,deltaHoldingPrevious, ...
        deltaSynapticCurrentPrevious,deltaSynapticChargePrevious, ...
        numel(holdingTrialMeans),avgRs,avgRin,{holdingTrialMeans}, ...
        {synapticCurrentTrialMeans},{synapticChargeTrialMeans}, ...
        {Data.(cond).stableTrialNames},string(dataFile),string(Expt.date),datetime('today'), ...
        'VariableNames',{'CellID','RecordingType','Condition','ConditionOrder','PreviousCondition', ...
        'AvgHolding','AvgSynapticCurrent_pA','AvgSynapticCharge_pC','DeltaHoldingFromPrevious', ...
        'DeltaSynapticCurrentFromPrevious_pA','DeltaSynapticChargeFromPrevious_pC', ...
        'nTrials','AvgRs','AvgRin','HoldingTrialMeans', ...
        'SynapticCurrentTrialMeans_pA','SynapticChargeTrialMeans_pC', ...
        'StableTrialNames','DataFile','ExptDate','AnalysisDate'});

    if c == 1
        longRows = thisRow;
    else
        longRows = [longRows; thisRow];
    end
end

%% BUILD CONTROL/WASHOUT ROW

baseIdx = strcmp(longRows.Condition,S.controlCondition);
washIdx = strcmp(longRows.Condition,S.washCondition);

baseHoldingTrialMeans = longRows.HoldingTrialMeans{baseIdx};
washHoldingTrialMeans = longRows.HoldingTrialMeans{washIdx};

baseSynapticCurrentTrialMeans = longRows.SynapticCurrentTrialMeans_pA{baseIdx};
washSynapticCurrentTrialMeans = longRows.SynapticCurrentTrialMeans_pA{washIdx};

baseSynapticChargeTrialMeans = longRows.SynapticChargeTrialMeans_pC{baseIdx};
washSynapticChargeTrialMeans = longRows.SynapticChargeTrialMeans_pC{washIdx};

baselineHoldingMean = longRows.AvgHolding(baseIdx);
washoutHoldingMean = longRows.AvgHolding(washIdx);

baselineSynapticCurrentMean = longRows.AvgSynapticCurrent_pA(baseIdx);
washoutSynapticCurrentMean = longRows.AvgSynapticCurrent_pA(washIdx);

baselineSynapticChargeMean = longRows.AvgSynapticCharge_pC(baseIdx);
washoutSynapticChargeMean = longRows.AvgSynapticCharge_pC(washIdx);

row = struct;

row.CellID = string(Expt.marker);
row.RecordingType = string(Expt.recordingType);
row.DataFile = string(dataFile);

row.avgBaselineHolding = baselineHoldingMean;
row.avgWashoutHolding = washoutHoldingMean;
row.DeltaHolding = washoutHoldingMean-baselineHoldingMean;

row.avgBaselineSynapticCurrent_pA = baselineSynapticCurrentMean;
row.avgWashoutSynapticCurrent_pA = washoutSynapticCurrentMean;
row.DeltaSynapticCurrent_pA = washoutSynapticCurrentMean-baselineSynapticCurrentMean;

row.avgBaselineSynapticCharge_pC = baselineSynapticChargeMean;
row.avgWashoutSynapticCharge_pC = washoutSynapticChargeMean;
row.DeltaSynapticCharge_pC = washoutSynapticChargeMean-baselineSynapticChargeMean;

row.BaselineHoldingTrialMeans = {baseHoldingTrialMeans};
row.WashoutHoldingTrialMeans = {washHoldingTrialMeans};

row.BaselineSynapticCurrentTrialMeans_pA = {baseSynapticCurrentTrialMeans};
row.WashoutSynapticCurrentTrialMeans_pA = {washSynapticCurrentTrialMeans};

row.BaselineSynapticChargeTrialMeans_pC = {baseSynapticChargeTrialMeans};
row.WashoutSynapticChargeTrialMeans_pC = {washSynapticChargeTrialMeans};

row.BaselineTrialNames = {Data.(S.controlCondition).stableTrialNames};
row.WashoutTrialNames = {Data.(S.washCondition).stableTrialNames};

row.nBaselineTrials = numel(baseHoldingTrialMeans);
row.nWashoutTrials = numel(washHoldingTrialMeans);

row.BaselineRs = mean(Data.(S.controlCondition).stableRs,'omitnan');
row.WashoutRs = mean(Data.(S.washCondition).stableRs,'omitnan');

row.BaselineRin = mean(Data.(S.controlCondition).stableRin,'omitnan');
row.WashoutRin = mean(Data.(S.washCondition).stableRin,'omitnan');

row.exptDate = string(Expt.date);
row.analysisDate = datetime('today');

newRow = struct2table(row,'AsArray',true);

%% LOAD EXISTING HISTOGRAM TABLES

if isfile(populationFile)
    loaded = load(populationFile);

    if isfield(loaded,'Population')
        Population = addMissingPopulationColumns(loaded.Population,newRow);
    else
        Population = newRow([],:);
    end

    if isfield(loaded,'PopulationLong')
        PopulationLong = addMissingPopulationColumns(loaded.PopulationLong,longRows);
    else
        PopulationLong = longRows([],:);
    end
else
    Population = newRow([],:);
    PopulationLong = longRows([],:);
end

%% ADD OR REPLACE CELL ROW

existingIdx = find(strcmp(string(Population.CellID),string(Expt.marker)));
newRow = alignPopulationSchema(newRow,Population);

if isempty(existingIdx)
    Population = [Population; newRow];
else
    Population(existingIdx(1),:) = newRow;

    if numel(existingIdx) > 1
        Population(existingIdx(2:end),:) = [];
    end
end

%% ADD OR REPLACE LONG-FORM CONDITION ROWS

if ~isempty(PopulationLong)
    PopulationLong(strcmp(string(PopulationLong.CellID),string(Expt.marker)),:) = [];
end

longRows = alignPopulationSchema(longRows,PopulationLong);
PopulationLong = [PopulationLong; longRows];
PopulationLong = sortrows(PopulationLong,{'CellID','ConditionOrder'});

save(populationFile,'Population','PopulationLong');

fprintf('Histogram population file: %s\n',populationFile);
fprintf('Population now contains %d cells.\n',height(Population));
fprintf('PopulationLong updated for %s: %s\n',Expt.marker, ...
    strjoin(strrep(analysisConditions,'_','/'),', '));

end


function T = alignPopulationSchema(T,template)

if width(template) == 0
    return
end

templateVars = template.Properties.VariableNames;
tableVars = T.Properties.VariableNames;

for k = 1:numel(templateVars)
    varName = templateVars{k};

    if ~ismember(varName,tableVars)
        T.(varName) = missingColumnLike(template.(varName),height(T));
    end
end

T = T(:,templateVars);

end


function T = addMissingPopulationColumns(T,template)

if width(template) == 0
    return
end

templateVars = template.Properties.VariableNames;
tableVars = T.Properties.VariableNames;

for k = 1:numel(templateVars)
    varName = templateVars{k};

    if ~ismember(varName,tableVars)
        T.(varName) = missingColumnLike(template.(varName),height(T));
    end
end

end


function col = missingColumnLike(example,nRows)

if iscell(example)
    col = cell(nRows,1);
elseif isstring(example)
    col = strings(nRows,1);
elseif isdatetime(example)
    col = NaT(nRows,1);
elseif islogical(example)
    col = false(nRows,1);
elseif isnumeric(example)
    col = nan(nRows,1);
else
    col = cell(nRows,1);
end

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
