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
%   Gaussian histogram synaptic-excess fraction (dimensionless).

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

    if ~isfield(Data.(cond),'trialSynapticExcessFraction')
        error('Data.%s.trialSynapticExcessFraction is missing. Run MINIS_calculateHistogramMetrics first.',cond);
    end

    holdingTrialMeans = Data.(cond).trialHoldingCurrent;
    synapticTrialMeans = Data.(cond).trialSynapticExcessFraction;

    avgHolding = mean(holdingTrialMeans,'omitnan');
    avgSynapticExcess = mean(synapticTrialMeans,'omitnan');

    if c == 1
        previousCondition = "";
        deltaHoldingPrevious = NaN;
        deltaSynapticExcessPrevious = NaN;
    else
        previousCondition = string(analysisConditions{c-1});
        prevHolding = longRows.AvgHolding(end);
        prevSynapticExcess = longRows.AvgSynapticExcessFraction(end);

        deltaHoldingPrevious = avgHolding-prevHolding;
        deltaSynapticExcessPrevious = avgSynapticExcess-prevSynapticExcess;
    end

    avgRs = mean(Data.(cond).stableRs,'omitnan');
    avgRin = mean(Data.(cond).stableRin,'omitnan');

    thisRow = table(string(Expt.marker),string(Expt.recordingType),string(cond),c,previousCondition, ...
        avgHolding,avgSynapticExcess,deltaHoldingPrevious,deltaSynapticExcessPrevious, ...
        numel(holdingTrialMeans),avgRs,avgRin,{holdingTrialMeans},{synapticTrialMeans}, ...
        {Data.(cond).stableTrialNames},string(dataFile),string(Expt.date),datetime('today'), ...
        'VariableNames',{'CellID','RecordingType','Condition','ConditionOrder','PreviousCondition', ...
        'AvgHolding','AvgSynapticExcessFraction','DeltaHoldingFromPrevious', ...
        'DeltaSynapticExcessFromPrevious','nTrials','AvgRs','AvgRin','HoldingTrialMeans', ...
        'SynapticExcessTrialMeans','StableTrialNames','DataFile','ExptDate','AnalysisDate'});

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

baseSynapticTrialMeans = longRows.SynapticExcessTrialMeans{baseIdx};
washSynapticTrialMeans = longRows.SynapticExcessTrialMeans{washIdx};

baselineHoldingMean = longRows.AvgHolding(baseIdx);
washoutHoldingMean = longRows.AvgHolding(washIdx);

baselineSynapticMean = longRows.AvgSynapticExcessFraction(baseIdx);
washoutSynapticMean = longRows.AvgSynapticExcessFraction(washIdx);

row = struct;

row.CellID = string(Expt.marker);
row.RecordingType = string(Expt.recordingType);
row.DataFile = string(dataFile);

row.avgBaselineHolding = baselineHoldingMean;
row.avgWashoutHolding = washoutHoldingMean;
row.DeltaHolding = washoutHoldingMean-baselineHoldingMean;

row.avgBaselineSynapticExcessFraction = baselineSynapticMean;
row.avgWashoutSynapticExcessFraction = washoutSynapticMean;
row.DeltaSynapticExcessFraction = washoutSynapticMean-baselineSynapticMean;

row.BaselineHoldingTrialMeans = {baseHoldingTrialMeans};
row.WashoutHoldingTrialMeans = {washHoldingTrialMeans};

row.BaselineSynapticExcessTrialMeans = {baseSynapticTrialMeans};
row.WashoutSynapticExcessTrialMeans = {washSynapticTrialMeans};

row.BaselineTrialNames = {Data.(S.controlCondition).stableTrialNames};
row.WashoutTrialNames = {Data.(S.washCondition).stableTrialNames};

row.nBaselineTrials = numel(baseHoldingTrialMeans);
row.nWashoutTrials = numel(washHoldingTrialMeans);

row.BaselineRs = mean(Data.(S.controlCondition).stableRs,'omitnan');
row.WashoutRs = mean(Data.(S.washCondition).stableRs,'omitnan');

row.BaselineRin = mean(Data.(S.controlCondition).stableRin,'omitnan');
row.WashoutRin = mean(Data.(S.washCondition).stableRin,'omitnan');

row.exptDate = Expt.date;
row.analysisDate = datetime('today');

newRow = struct2table(row,'AsArray',true);

%% LOAD EXISTING HISTOGRAM TABLES

if isfile(populationFile)
    loaded = load(populationFile);

    if isfield(loaded,'Population')
        Population = loaded.Population;
    else
        Population = newRow([],:);
    end

    if isfield(loaded,'PopulationLong')
        PopulationLong = loaded.PopulationLong;
    else
        PopulationLong = longRows([],:);
    end
else
    Population = newRow([],:);
    PopulationLong = longRows([],:);
end

%% ADD OR REPLACE CELL ROW

existingIdx = find(strcmp(string(Population.CellID),string(Expt.marker)));

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

PopulationLong = [PopulationLong; longRows];
PopulationLong = sortrows(PopulationLong,{'CellID','ConditionOrder'});

save(populationFile,'Population','PopulationLong');

fprintf('Histogram population file: %s\n',populationFile);
fprintf('Population now contains %d cells.\n',height(Population));
fprintf('PopulationLong updated for %s: %s\n',Expt.marker, ...
    strjoin(strrep(analysisConditions,'_','/'),', '));

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