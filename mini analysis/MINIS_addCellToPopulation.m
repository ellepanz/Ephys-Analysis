function [Population,PopulationLong] = MINIS_addCellToPopulation(Data,S,Expt,dataFile,conditions)
% Add/update one analyzed cell in the master population file.
%
% Population:
%   One row per cell for baseline-vs-washout summaries.
%
% PopulationLong:
%   One row per cell per analyzed condition.
%
% Synaptic metric:
%   Histogram synaptic-excess fraction from MINIS_calculateHistogramMetrics.
%
% If the existing population tables use the retired phasic-Imean schema,
% they are preserved once as Population_TimeDomainBackup and
% PopulationLong_TimeDomainBackup before new histogram-based tables start.

populationFolder = '\\bunson\bunson\Higley_Lab\Lauren bunsen\Data Summaries\mIPSCs with NMDA';
populationFile = fullfile(populationFolder,'NMDAmIPSCs_population.mat');

if ~exist(populationFolder,'dir')
    mkdir(populationFolder);
end

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

    holding = Data.(cond).oneSecEpoch.epochHoldingCurrent;
    excess = Data.(cond).oneSecEpoch.epochSynapticExcessFraction;

    holdingTrialMeans = mean(holding,1,'omitnan');
    excessTrialMeans = mean(excess,1,'omitnan');

    avgHolding = mean(holdingTrialMeans,'omitnan');
    avgExcess = mean(excessTrialMeans,'omitnan');

    if c == 1
        previousCondition = "";
        deltaHoldingPrevious = NaN;
        deltaExcessPrevious = NaN;
    else
        previousCondition = string(analysisConditions{c-1});
        prevHolding = longRows.AvgHolding(end);
        prevExcess = longRows.AvgSynapticExcessFraction(end);
        deltaHoldingPrevious = avgHolding-prevHolding;
        deltaExcessPrevious = avgExcess-prevExcess;
    end

    avgRs = mean(Data.(cond).stableRs,'omitnan');
    avgRin = mean(Data.(cond).stableRin,'omitnan');

    thisRow = table(string(Expt.marker),string(cond),c,previousCondition,avgHolding,avgExcess, ...
        deltaHoldingPrevious,deltaExcessPrevious,numel(holdingTrialMeans),avgRs,avgRin, ...
        {holdingTrialMeans},{excessTrialMeans},{Data.(cond).stableTrialNames},string(dataFile), ...
        string(Expt.date),datetime('today'), ...
        'VariableNames',{'CellID','Condition','ConditionOrder','PreviousCondition','AvgHolding', ...
        'AvgSynapticExcessFraction','DeltaHoldingFromPrevious','DeltaSynapticExcessFromPrevious', ...
        'nTrials','AvgRs','AvgRin','HoldingTrialMeans','SynapticExcessTrialMeans', ...
        'StableTrialNames','DataFile','ExptDate','AnalysisDate'});

    if c == 1
        longRows = thisRow;
    else
        longRows = [longRows; thisRow];
    end
end

%% BUILD BASELINE/WASHOUT ROW

baseIdx = strcmp(longRows.Condition,S.controlCondition);
washIdx = strcmp(longRows.Condition,S.washCondition);

baseHoldingTrialMeans = longRows.HoldingTrialMeans{baseIdx};
washHoldingTrialMeans = longRows.HoldingTrialMeans{washIdx};
baseExcessTrialMeans = longRows.SynapticExcessTrialMeans{baseIdx};
washExcessTrialMeans = longRows.SynapticExcessTrialMeans{washIdx};

baselineHoldingMean = longRows.AvgHolding(baseIdx);
washoutHoldingMean = longRows.AvgHolding(washIdx);
baselineExcessMean = longRows.AvgSynapticExcessFraction(baseIdx);
washoutExcessMean = longRows.AvgSynapticExcessFraction(washIdx);

row = struct;
row.CellID = string(Expt.marker);
row.DataFile = string(dataFile);

row.avgBaselineHolding = baselineHoldingMean;
row.avgWashoutHolding = washoutHoldingMean;
row.DeltaHolding = washoutHoldingMean-baselineHoldingMean;

row.avgBaselineSynapticExcessFraction = baselineExcessMean;
row.avgWashoutSynapticExcessFraction = washoutExcessMean;
row.DeltaSynapticExcessFraction = washoutExcessMean-baselineExcessMean;

row.BaselineHoldingTrialMeans = {baseHoldingTrialMeans};
row.WashoutHoldingTrialMeans = {washHoldingTrialMeans};
row.BaselineSynapticExcessTrialMeans = {baseExcessTrialMeans};
row.WashoutSynapticExcessTrialMeans = {washExcessTrialMeans};

row.BaselineTrialNames = {Data.(S.controlCondition).stableTrialNames};
row.WashoutTrialNames = {Data.(S.washCondition).stableTrialNames};

row.nBaselineTrials = numel(baseHoldingTrialMeans);
row.nWashoutTrials = numel(washHoldingTrialMeans);

row.BaselineRs = mean(Data.(S.controlCondition).stableRs,'omitnan');
row.WashoutRs = mean(Data.(S.washCondition).stableRs,'omitnan');
row.BaselineRin = mean(Data.(S.controlCondition).stableRin,'omitnan');
row.WashoutRin = mean(Data.(S.washCondition).stableRin,'omitnan');

row.exptDate = Expt.date;
row.analysisData = datetime('today');

newRow = struct2table(row,'AsArray',true);

%% LOAD EXISTING TABLES

Population_TimeDomainBackup = table;
PopulationLong_TimeDomainBackup = table;

if isfile(populationFile)
    loaded = load(populationFile);

    if isfield(loaded,'Population_TimeDomainBackup')
        Population_TimeDomainBackup = loaded.Population_TimeDomainBackup;
    end

    if isfield(loaded,'PopulationLong_TimeDomainBackup')
        PopulationLong_TimeDomainBackup = loaded.PopulationLong_TimeDomainBackup;
    end

    if isfield(loaded,'Population')
        existingPopulation = loaded.Population;

        if ismember('avgBaselineSynapticExcessFraction',existingPopulation.Properties.VariableNames)
            Population = existingPopulation;
        elseif ismember('avgBaselinePhasic',existingPopulation.Properties.VariableNames)
            if isempty(Population_TimeDomainBackup)
                Population_TimeDomainBackup = existingPopulation;
            end

            Population = newRow([],:);
            fprintf('Retired phasic-Imean Population preserved as Population_TimeDomainBackup.\n');
        else
            error('Existing Population table has an unrecognized schema.');
        end
    else
        Population = newRow([],:);
    end

    if isfield(loaded,'PopulationLong')
        existingPopulationLong = loaded.PopulationLong;

        if ismember('AvgSynapticExcessFraction',existingPopulationLong.Properties.VariableNames)
            PopulationLong = existingPopulationLong;
        elseif ismember('AvgPhasic',existingPopulationLong.Properties.VariableNames)
            if isempty(PopulationLong_TimeDomainBackup)
                PopulationLong_TimeDomainBackup = existingPopulationLong;
            end

            PopulationLong = longRows([],:);
            fprintf('Retired phasic-Imean PopulationLong preserved as PopulationLong_TimeDomainBackup.\n');
        else
            error('Existing PopulationLong table has an unrecognized schema.');
        end
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

save(populationFile,'Population','PopulationLong','Population_TimeDomainBackup', ...
    'PopulationLong_TimeDomainBackup');

fprintf('Population now contains %d histogram-analyzed cells.\n',height(Population));
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
