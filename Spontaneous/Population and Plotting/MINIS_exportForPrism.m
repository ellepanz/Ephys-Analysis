function prismFile = MINIS_exportForPrism(Expt,S)
% Export dual-analysis population data for GraphPad Prism.
%
% Exports only cells marked DualReprocessed = true.
%
% Sheets:
%   Whole19 Holding
%   Whole19 Synaptic Current
%   Local1s Holding
%   Local1s Synaptic Current
%   Holding Delta Comparison
%   Synaptic Delta Comparison
%   Whole19 Trial Counts
%
% Each Baseline/Washout sheet is arranged as paired data:
%   CellID | Baseline | Washout
%
% Each delta-comparison sheet is arranged as paired method data:
%   CellID | Whole19 | Local1s

%% LOAD POPULATION

paths = MINIS_getPopulationPaths(Expt);
populationFile = paths.populationFile;

if ~isfile(populationFile)
    error('Population file not found: %s',populationFile);
end

tmp = load(populationFile,'Population');

if ~isfield(tmp,'Population') || ~istable(tmp.Population)
    error('Population variable not found in %s.',populationFile);
end

Population = tmp.Population;

%% VERIFY DUAL-ANALYSIS COLUMNS

requiredVars = { ...
    'CellID','DualReprocessed', ...
    'Whole19_avgBaselineHolding','Whole19_avgWashoutHolding','Whole19_DeltaHolding', ...
    'Whole19_avgBaselineSynapticCurrent_pA','Whole19_avgWashoutSynapticCurrent_pA','Whole19_DeltaSynapticCurrent_pA', ...
    'Local1s_avgBaselineHolding','Local1s_avgWashoutHolding','Local1s_DeltaHolding', ...
    'Local1s_avgBaselineSynapticCurrent_pA','Local1s_avgWashoutSynapticCurrent_pA','Local1s_DeltaSynapticCurrent_pA', ...
    'Whole19_nBaselineSelectedStable','Whole19_nWashoutSelectedStable', ...
    'Whole19_nBaselineExcluded','Whole19_nWashoutExcluded', ...
    'Whole19_nBaselineAnalyzed','Whole19_nWashoutAnalyzed'};

missingVars = setdiff(requiredVars,Population.Properties.VariableNames);

if ~isempty(missingVars)
    error('Population is missing dual-analysis columns: %s',strjoin(missingVars,', '));
end

Population = Population(Population.DualReprocessed == true,:);

if isempty(Population)
    error('No dual-reprocessed cells are currently in Population.');
end

%% OUTPUT FILE

prefix = [char(string(Expt.recordingType)) '_' char(string(Expt.studyID))];
prismFile = fullfile(paths.folder,[prefix '_Prism_DualAnalysis.xlsx']);

if isfile(prismFile)
    delete(prismFile);
end

baseLabel = matlab.lang.makeValidName(char(string(S.controlCondition)));
washLabel = matlab.lang.makeValidName(char(string(S.washCondition)));

%% WHOLE19: HOLDING CURRENT

Whole19Holding = table( ...
    Population.CellID, ...
    Population.Whole19_avgBaselineHolding, ...
    Population.Whole19_avgWashoutHolding, ...
    'VariableNames',{'CellID',baseLabel,washLabel});

%% WHOLE19: SYNAPTIC CURRENT

Whole19Synaptic = table( ...
    Population.CellID, ...
    Population.Whole19_avgBaselineSynapticCurrent_pA, ...
    Population.Whole19_avgWashoutSynapticCurrent_pA, ...
    'VariableNames',{'CellID',baseLabel,washLabel});

%% LOCAL1S: HOLDING CURRENT

Local1sHolding = table( ...
    Population.CellID, ...
    Population.Local1s_avgBaselineHolding, ...
    Population.Local1s_avgWashoutHolding, ...
    'VariableNames',{'CellID',baseLabel,washLabel});

%% LOCAL1S: SYNAPTIC CURRENT

Local1sSynaptic = table( ...
    Population.CellID, ...
    Population.Local1s_avgBaselineSynapticCurrent_pA, ...
    Population.Local1s_avgWashoutSynapticCurrent_pA, ...
    'VariableNames',{'CellID',baseLabel,washLabel});

%% METHOD COMPARISON: DELTA HOLDING

HoldingDelta = table( ...
    Population.CellID, ...
    Population.Whole19_DeltaHolding, ...
    Population.Local1s_DeltaHolding, ...
    'VariableNames',{'CellID','Whole19','Local1s'});

%% METHOD COMPARISON: DELTA SYNAPTIC CURRENT

SynapticDelta = table( ...
    Population.CellID, ...
    Population.Whole19_DeltaSynapticCurrent_pA, ...
    Population.Local1s_DeltaSynapticCurrent_pA, ...
    'VariableNames',{'CellID','Whole19','Local1s'});

%% WHOLE19 TRIAL COUNTS / EXCLUSIONS

Whole19Counts = table( ...
    Population.CellID, ...
    Population.Whole19_nBaselineSelectedStable, ...
    Population.Whole19_nBaselineExcluded, ...
    Population.Whole19_nBaselineAnalyzed, ...
    Population.Whole19_nWashoutSelectedStable, ...
    Population.Whole19_nWashoutExcluded, ...
    Population.Whole19_nWashoutAnalyzed, ...
    'VariableNames',{ ...
    'CellID', ...
    'BaselineSelectedStable','BaselineExcluded','BaselineAnalyzed', ...
    'WashoutSelectedStable','WashoutExcluded','WashoutAnalyzed'});

%% WRITE

writetable(Whole19Holding,prismFile,'Sheet','Whole19 Holding');
writetable(Whole19Synaptic,prismFile,'Sheet','Whole19 Synaptic Current');
writetable(Local1sHolding,prismFile,'Sheet','Local1s Holding');
writetable(Local1sSynaptic,prismFile,'Sheet','Local1s Synaptic Current');
writetable(HoldingDelta,prismFile,'Sheet','Holding Delta Comparison');
writetable(SynapticDelta,prismFile,'Sheet','Synaptic Delta Comparison');
writetable(Whole19Counts,prismFile,'Sheet','Whole19 Trial Counts');

fprintf('Prism dual-analysis data exported to:\n%s\n',prismFile);
fprintf('Exported %d dual-reprocessed cells.\n',height(Population));

end
