function MINIS_exportForPrism(Expt,S)
% Export baseline-versus-washout population data for Prism.
%
% Population is selected from Expt.recordingType and Expt.studyID.

%% LOAD POPULATION

paths = MINIS_getPopulationPaths(Expt);
populationFile = paths.populationFile;

if ~isfile(populationFile)
    error('Population file not found: %s',populationFile);
end

tmp = load(populationFile,'Population');

if ~isfield(tmp,'Population')
    error('Population variable not found in %s.',populationFile);
end

Population = tmp.Population;

%% OUTPUT FILE

prefix = [char(string(Expt.recordingType)) '_' char(string(Expt.studyID))];
prismFile = fullfile(paths.folder,[prefix '_Prism.xlsx']);

% Remove old workbook so obsolete sheets cannot remain.
if isfile(prismFile)
    delete(prismFile);
end

%% HOLDING CURRENT

Holding = table(Population.CellID,Population.avgBaselineHolding,Population.avgWashoutHolding, ...
    'VariableNames',{'CellID',S.controlCondition,S.washCondition});

%% SYNAPTIC EXCESS FRACTION

SynapticExcess = table(Population.CellID, ...
    Population.avgBaselineSynapticExcessFraction, ...
    Population.avgWashoutSynapticExcessFraction, ...
    'VariableNames',{'CellID',S.controlCondition,S.washCondition});

%% DELTAS

Delta = table(Population.CellID,Population.DeltaHolding,Population.DeltaSynapticExcessFraction, ...
    'VariableNames',{'CellID','DeltaHolding_pA','DeltaSynapticExcessFraction'});

%% WRITE

writetable(Holding,prismFile,'Sheet','Holding Current');
writetable(SynapticExcess,prismFile,'Sheet','Synaptic Excess');
writetable(Delta,prismFile,'Sheet','Change from Baseline');

fprintf('Prism data exported to:\n%s\n',prismFile);

end