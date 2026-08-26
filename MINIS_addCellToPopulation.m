function Population = MINIS_addCellToPopulation(Data,S,Expt,dataFile)
% Add/update one analyzed cell in the master MINIS population table.
%
% One row = one cell.
% The full per-cell analysis remains in Data and is accessed through DataFile.
%
% Example:
% Population = MINIS_addCellToPopulation(Data,S,'LP279_B','LP279',dataFile,populationFile);

controlCond = S.controlCondition;
washCond = S.washCondition;
populationFolder = '\\bunson\bunson\Higley_Lab\Lauren bunsen\Data Summaries\mIPSCs with NMDA';
populationFile = fullfile(populationFolder,'NMDAmIPSCs_population.mat'); 
%% Get 1-s measurements

baseHolding = Data.(controlCond).oneSecEpoch.epochHoldingCurrent;
washHolding = Data.(washCond).oneSecEpoch.epochHoldingCurrent;

basePhasic = Data.(controlCond).oneSecEpoch.epochPhasicImean;
washPhasic = Data.(washCond).oneSecEpoch.epochPhasicImean;

%% Average 1-s epochs within each trial

baseHoldingTrialMeans = mean(baseHolding,1);
washHoldingTrialMeans = mean(washHolding,1);

basePhasicTrialMeans = mean(basePhasic,1);
washPhasicTrialMeans = mean(washPhasic,1);

%% Average stable trials to get one value per cell/condition

baselineHoldingMean = mean(baseHoldingTrialMeans);
washoutHoldingMean = mean(washHoldingTrialMeans);

baselinePhasicMean = mean(basePhasicTrialMeans);
washoutPhasicMean = mean(washPhasicTrialMeans);

%% Build one population row

row = struct;

row.CellID = string(Expt.marker);
row.DataFile = string(dataFile);

row.avgBaselineHolding = baselineHoldingMean;
row.avgWashoutHolding = washoutHoldingMean;
row.DeltaHolding = washoutHoldingMean - baselineHoldingMean;

row.avgBaselinePhasic = baselinePhasicMean;
row.avgWashoutPhasic = washoutPhasicMean;
row.DeltaPhasic = washoutPhasicMean - baselinePhasicMean;

row.BaselineHoldingTrialMeans = {baseHoldingTrialMeans};
row.WashoutHoldingTrialMeans = {washHoldingTrialMeans};

row.BaselinePhasicTrialMeans = {basePhasicTrialMeans};
row.WashoutPhasicTrialMeans = {washPhasicTrialMeans};

row.BaselineTrialNames = {Data.(controlCond).stableTrialNames};
row.WashoutTrialNames = {Data.(washCond).stableTrialNames};

row.nBaselineTrials = numel(baseHoldingTrialMeans);
row.nWashoutTrials = numel(washHoldingTrialMeans);

row.BaselineRs = mean(Data.(controlCond).stableRs,'omitNan');
row.WashoutRs = mean(Data.(washCond).stableRs,'omitNan');

row.BaselineRin = mean(Data.(controlCond).stableRin,'omitNaN');
row.WashoutRin = mean(Data.(washCond).stableRin,'omitnan');

row.exptDate = Expt.date;
row.analysisData = datetime('today');
newRow = struct2table(row,'AsArray',true);

%% Load existing population table

if isfile(populationFile)
    loaded = load(populationFile,'Population');

    if ~isfield(loaded,'Population')
        error('Population file exists but does not contain a variable named Population.');
    end

    Population = loaded.Population;
else
    Population = newRow([],:);
end

%% Add new cell or replace existing cell

existingIdx = find(strcmp(string(Population.CellID),string(Expt.marker)));

if isempty(existingIdx)
    Population = [Population; newRow];
    fprintf('Added %s to Population.\n',Expt.marker);
else
    Population(existingIdx(1),:) = newRow;

    if numel(existingIdx) > 1
        Population(existingIdx(2:end),:) = [];
    end

    fprintf('Updated existing cell %s in Population.\n',Expt.marker);
end

%% Save

save(populationFile,'Population');

fprintf('Population now contains %d cells.\n',height(Population));

end