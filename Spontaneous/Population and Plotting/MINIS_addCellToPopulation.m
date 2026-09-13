function [Population,PopulationLong] = MINIS_addCellToPopulation(Data,S,Expt,dataFile,conditions)
% Add/update one dual-analysis cell in the appropriate population file.
%
% Stores BOTH:
%   Whole19 = whole 19-s Gaussian analysis after manual baseline exclusions
%   Local1s = 19 x 1-s local Gaussian analysis using all selected stable trials
%
% Existing legacy population columns are preserved. The old generic histogram
% columns are also populated from Local1s for backward compatibility.

paths = MINIS_getPopulationPaths(Expt);
populationFile = paths.populationFile;
analysisConditions = getAnalysisConditions(conditions,S);

if ~ismember(S.controlCondition,analysisConditions)
    error('Control condition %s is not available for population analysis.',S.controlCondition);
end

if ~ismember(S.washCondition,analysisConditions)
    error('Washout condition %s is not available for population analysis.',S.washCondition);
end

%% HONOR BINDER POPULATION DECISION

includeInPopulation = getBinderPopulationDecision(paths,Expt.marker);

if ~includeInPopulation
    [Population,PopulationLong] = removeCellFromPopulationFile(populationFile,Expt.marker);
    fprintf('%s is marked IncludeInPopulation=false; removed/skipped from population.\n',Expt.marker);
    return
end

%% VERIFY BOTH ANALYSES EXIST

for c = 1:numel(analysisConditions)
    cond = analysisConditions{c};

    localFields = {'trialHoldingCurrent','trialSynapticCurrent_pA','trialSynapticCharge_pC','stableTrialNames'};

    for f = 1:numel(localFields)
        if ~isfield(Data.(cond),localFields{f})
            error('Data.%s.%s is missing. Run MINIS_calculateHistogramMetrics first.',cond,localFields{f});
        end
    end

    if ~isfield(Data.(cond),'wholeTrial')
        error('Data.%s.wholeTrial is missing. Run MINIS_calculateWholeTrialMetrics first.',cond);
    end

    wholeFields = {'trialHoldingCurrent','trialSynapticCurrent_pA','trialSynapticCharge_pC', ...
        'trialNames','excludedTrialNames','nSelectedStableTrials','nExcludedBaselineTrials','nAnalyzedTrials'};

    for f = 1:numel(wholeFields)
        if ~isfield(Data.(cond).wholeTrial,wholeFields{f})
            error('Data.%s.wholeTrial.%s is missing.',cond,wholeFields{f});
        end
    end
end

%% BUILD LONG-FORM TABLE: ONE ROW PER CELL x METHOD x CONDITION

longRows = table;

for c = 1:numel(analysisConditions)
    cond = analysisConditions{c};

    avgRs = mean(Data.(cond).stableRs,'omitnan');
    avgRin = mean(Data.(cond).stableRin,'omitnan');

    % Local 1-s
    localHolding = Data.(cond).trialHoldingCurrent;
    localSynCurrent = Data.(cond).trialSynapticCurrent_pA;
    localSynCharge = Data.(cond).trialSynapticCharge_pC;

    localRow = buildLongRow(Expt,dataFile,cond,c,"Local1s", ...
        localHolding,localSynCurrent,localSynCharge, ...
        Data.(cond).stableTrialNames,{}, ...
        numel(Data.(cond).stableTrialNames),0,numel(Data.(cond).stableTrialNames), ...
        avgRs,avgRin);

    % Whole 19-s
    W = Data.(cond).wholeTrial;

    wholeRow = buildLongRow(Expt,dataFile,cond,c,"Whole19", ...
        W.trialHoldingCurrent,W.trialSynapticCurrent_pA,W.trialSynapticCharge_pC, ...
        W.trialNames,W.excludedTrialNames, ...
        W.nSelectedStableTrials,W.nExcludedBaselineTrials,W.nAnalyzedTrials, ...
        avgRs,avgRin);

    if isempty(longRows)
        longRows = [localRow; wholeRow];
    else
        longRows = [longRows; localRow; wholeRow]; %#ok<AGROW>
    end
end

%% BUILD ONE WIDE CONTROL/WASHOUT ROW

base = S.controlCondition;
wash = S.washCondition;

LB = Data.(base);
LW = Data.(wash);
WB = Data.(base).wholeTrial;
WW = Data.(wash).wholeTrial;

row = struct;

row.CellID = string(Expt.marker);
row.RecordingType = string(Expt.recordingType);
row.StudyID = string(Expt.studyID);
row.DataFile = string(dataFile);
row.DualReprocessed = true;
row.AnalysisVersion = "dualHistogram_v1";
row.exptDate = string(Expt.date);
row.analysisDate = datetime('now');

% ---------- Local 1-s ----------
row.Local1s_avgBaselineHolding = mean(LB.trialHoldingCurrent,'omitnan');
row.Local1s_avgWashoutHolding = mean(LW.trialHoldingCurrent,'omitnan');
row.Local1s_DeltaHolding = row.Local1s_avgWashoutHolding-row.Local1s_avgBaselineHolding;

row.Local1s_avgBaselineSynapticCurrent_pA = mean(LB.trialSynapticCurrent_pA,'omitnan');
row.Local1s_avgWashoutSynapticCurrent_pA = mean(LW.trialSynapticCurrent_pA,'omitnan');
row.Local1s_DeltaSynapticCurrent_pA = ...
    row.Local1s_avgWashoutSynapticCurrent_pA-row.Local1s_avgBaselineSynapticCurrent_pA;

row.Local1s_avgBaselineSynapticCharge_pC = mean(LB.trialSynapticCharge_pC,'omitnan');
row.Local1s_avgWashoutSynapticCharge_pC = mean(LW.trialSynapticCharge_pC,'omitnan');
row.Local1s_DeltaSynapticCharge_pC = ...
    row.Local1s_avgWashoutSynapticCharge_pC-row.Local1s_avgBaselineSynapticCharge_pC;

row.Local1s_BaselineHoldingTrialMeans = {LB.trialHoldingCurrent};
row.Local1s_WashoutHoldingTrialMeans = {LW.trialHoldingCurrent};
row.Local1s_BaselineSynapticCurrentTrialMeans_pA = {LB.trialSynapticCurrent_pA};
row.Local1s_WashoutSynapticCurrentTrialMeans_pA = {LW.trialSynapticCurrent_pA};
row.Local1s_BaselineSynapticChargeTrialMeans_pC = {LB.trialSynapticCharge_pC};
row.Local1s_WashoutSynapticChargeTrialMeans_pC = {LW.trialSynapticCharge_pC};
row.Local1s_BaselineTrialNames = {LB.stableTrialNames};
row.Local1s_WashoutTrialNames = {LW.stableTrialNames};
row.Local1s_nBaselineTrials = numel(LB.stableTrialNames);
row.Local1s_nWashoutTrials = numel(LW.stableTrialNames);

% ---------- Whole 19-s ----------
row.Whole19_avgBaselineHolding = WB.avgHoldingCurrent;
row.Whole19_avgWashoutHolding = WW.avgHoldingCurrent;
row.Whole19_DeltaHolding = WW.avgHoldingCurrent-WB.avgHoldingCurrent;

row.Whole19_avgBaselineSynapticCurrent_pA = WB.avgSynapticCurrent_pA;
row.Whole19_avgWashoutSynapticCurrent_pA = WW.avgSynapticCurrent_pA;
row.Whole19_DeltaSynapticCurrent_pA = WW.avgSynapticCurrent_pA-WB.avgSynapticCurrent_pA;

row.Whole19_avgBaselineSynapticCharge_pC = WB.avgSynapticCharge_pC;
row.Whole19_avgWashoutSynapticCharge_pC = WW.avgSynapticCharge_pC;
row.Whole19_DeltaSynapticCharge_pC = WW.avgSynapticCharge_pC-WB.avgSynapticCharge_pC;

row.Whole19_BaselineHoldingTrialMeans = {WB.trialHoldingCurrent};
row.Whole19_WashoutHoldingTrialMeans = {WW.trialHoldingCurrent};
row.Whole19_BaselineSynapticCurrentTrialMeans_pA = {WB.trialSynapticCurrent_pA};
row.Whole19_WashoutSynapticCurrentTrialMeans_pA = {WW.trialSynapticCurrent_pA};
row.Whole19_BaselineSynapticChargeTrialMeans_pC = {WB.trialSynapticCharge_pC};
row.Whole19_WashoutSynapticChargeTrialMeans_pC = {WW.trialSynapticCharge_pC};

row.Whole19_BaselineTrialNames = {WB.trialNames};
row.Whole19_WashoutTrialNames = {WW.trialNames};
row.Whole19_BaselineExcludedTrialNames = {WB.excludedTrialNames};
row.Whole19_WashoutExcludedTrialNames = {WW.excludedTrialNames};

row.Whole19_nBaselineSelectedStable = WB.nSelectedStableTrials;
row.Whole19_nWashoutSelectedStable = WW.nSelectedStableTrials;
row.Whole19_nBaselineExcluded = WB.nExcludedBaselineTrials;
row.Whole19_nWashoutExcluded = WW.nExcludedBaselineTrials;
row.Whole19_nBaselineAnalyzed = WB.nAnalyzedTrials;
row.Whole19_nWashoutAnalyzed = WW.nAnalyzedTrials;

% ---------- Shared QC ----------
row.BaselineRs = mean(LB.stableRs,'omitnan');
row.WashoutRs = mean(LW.stableRs,'omitnan');
row.BaselineRin = mean(LB.stableRin,'omitnan');
row.WashoutRin = mean(LW.stableRin,'omitnan');

% ---------- Backward-compatible aliases = Local1s ----------
row.avgBaselineHolding = row.Local1s_avgBaselineHolding;
row.avgWashoutHolding = row.Local1s_avgWashoutHolding;
row.DeltaHolding = row.Local1s_DeltaHolding;
row.avgBaselineSynapticCurrent_pA = row.Local1s_avgBaselineSynapticCurrent_pA;
row.avgWashoutSynapticCurrent_pA = row.Local1s_avgWashoutSynapticCurrent_pA;
row.DeltaSynapticCurrent_pA = row.Local1s_DeltaSynapticCurrent_pA;
row.avgBaselineSynapticCharge_pC = row.Local1s_avgBaselineSynapticCharge_pC;
row.avgWashoutSynapticCharge_pC = row.Local1s_avgWashoutSynapticCharge_pC;
row.DeltaSynapticCharge_pC = row.Local1s_DeltaSynapticCharge_pC;
row.BaselineHoldingTrialMeans = {LB.trialHoldingCurrent};
row.WashoutHoldingTrialMeans = {LW.trialHoldingCurrent};
row.BaselineSynapticCurrentTrialMeans_pA = {LB.trialSynapticCurrent_pA};
row.WashoutSynapticCurrentTrialMeans_pA = {LW.trialSynapticCurrent_pA};
row.BaselineSynapticChargeTrialMeans_pC = {LB.trialSynapticCharge_pC};
row.WashoutSynapticChargeTrialMeans_pC = {LW.trialSynapticCharge_pC};
row.BaselineTrialNames = {LB.stableTrialNames};
row.WashoutTrialNames = {LW.stableTrialNames};
row.nBaselineTrials = numel(LB.stableTrialNames);
row.nWashoutTrials = numel(LW.stableTrialNames);

newRow = struct2table(row,'AsArray',true);

%% LOAD EXISTING TABLES

if isfile(populationFile)
    loaded = load(populationFile);

    if isfield(loaded,'Population') && istable(loaded.Population)
        Population = addMissingPopulationColumns(loaded.Population,newRow);
    else
        Population = newRow([],:);
    end

    if isfield(loaded,'PopulationLong') && istable(loaded.PopulationLong)
        PopulationLong = addMissingPopulationColumns(loaded.PopulationLong,longRows);
    else
        PopulationLong = longRows([],:);
    end
else
    Population = newRow([],:);
    PopulationLong = longRows([],:);
end

%% ADD OR REPLACE WIDE ROW

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

Population = sortrows(Population,'CellID');

%% ADD OR REPLACE LONG ROWS

if ~isempty(PopulationLong) && ismember('CellID',PopulationLong.Properties.VariableNames)
    PopulationLong(strcmp(string(PopulationLong.CellID),string(Expt.marker)),:) = [];
end

longRows = alignPopulationSchema(longRows,PopulationLong);
PopulationLong = [PopulationLong; longRows];

sortVars = intersect({'CellID','AnalysisMethod','ConditionOrder'}, ...
    PopulationLong.Properties.VariableNames,'stable');

if ~isempty(sortVars)
    PopulationLong = sortrows(PopulationLong,sortVars);
end

save(populationFile,'Population','PopulationLong');

fprintf('Dual-analysis population file: %s\n',populationFile);
fprintf('Population now contains %d total rows; %d dual-reprocessed cells.\n', ...
    height(Population),sum(getDualMask(Population)));
fprintf('Updated %s with Whole19 and Local1s results.\n',Expt.marker);

end


function row = buildLongRow(Expt,dataFile,cond,conditionOrder,method, ...
    holding,synCurrent,synCharge,trialNames,excludedNames, ...
    nSelected,nExcluded,nAnalyzed,avgRs,avgRin)

row = table( ...
    string(Expt.marker),string(Expt.recordingType),string(Expt.studyID), ...
    string(method),string(cond),conditionOrder, ...
    mean(holding,'omitnan'),mean(synCurrent,'omitnan'),mean(synCharge,'omitnan'), ...
    nSelected,nExcluded,nAnalyzed,avgRs,avgRin, ...
    {holding},{synCurrent},{synCharge},{trialNames},{excludedNames}, ...
    string(dataFile),string(Expt.date),datetime('now'), ...
    'VariableNames',{ ...
    'CellID','RecordingType','StudyID','AnalysisMethod','Condition','ConditionOrder', ...
    'AvgHolding','AvgSynapticCurrent_pA','AvgSynapticCharge_pC', ...
    'nSelectedStableTrials','nExcludedBaselineTrials','nAnalyzedTrials', ...
    'AvgRs','AvgRin','HoldingTrialMeans','SynapticCurrentTrialMeans_pA', ...
    'SynapticChargeTrialMeans_pC','TrialNames','ExcludedTrialNames', ...
    'DataFile','ExptDate','AnalysisDate'});

end


function include = getBinderPopulationDecision(paths,marker)

include = true;

if ~isfield(paths,'binderIndexFile') || ~isfile(paths.binderIndexFile)
    warning('BinderIndex not found; population inclusion defaults to true for %s.',marker);
    return
end

tmp = load(paths.binderIndexFile,'BinderIndex');

if ~isfield(tmp,'BinderIndex') || ~istable(tmp.BinderIndex)
    warning('BinderIndex is unreadable; population inclusion defaults to true for %s.',marker);
    return
end

B = tmp.BinderIndex;

if ~ismember('Marker',B.Properties.VariableNames) || ...
        ~ismember('IncludeInPopulation',B.Properties.VariableNames)
    warning('BinderIndex lacks inclusion fields; population inclusion defaults to true for %s.',marker);
    return
end

idx = find(string(B.Marker) == string(marker),1);

if isempty(idx)
    warning('%s is not in BinderIndex; population inclusion defaults to true.',marker);
    return
end

include = logical(B.IncludeInPopulation(idx));

end


function [Population,PopulationLong] = removeCellFromPopulationFile(populationFile,marker)

Population = table;
PopulationLong = table;

if ~isfile(populationFile)
    return
end

loaded = load(populationFile);

if isfield(loaded,'Population') && istable(loaded.Population)
    Population = loaded.Population;

    if ismember('CellID',Population.Properties.VariableNames)
        Population(strcmp(string(Population.CellID),string(marker)),:) = [];
    end
end

if isfield(loaded,'PopulationLong') && istable(loaded.PopulationLong)
    PopulationLong = loaded.PopulationLong;

    if ismember('CellID',PopulationLong.Properties.VariableNames)
        PopulationLong(strcmp(string(PopulationLong.CellID),string(marker)),:) = [];
    end
end

save(populationFile,'Population','PopulationLong');

end


function mask = getDualMask(Population)

if ismember('DualReprocessed',Population.Properties.VariableNames)
    mask = Population.DualReprocessed == true;
else
    mask = false(height(Population),1);
end

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

extraVars = setdiff(T.Properties.VariableNames,templateVars,'stable');

for k = 1:numel(extraVars)
    varName = extraVars{k};
    template.(varName) = missingColumnLike(T.(varName),height(template));
end

T = T(:,template.Properties.VariableNames);

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
