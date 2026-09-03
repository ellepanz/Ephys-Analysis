function ComparisonData = buildEPSCComparisonData(compiledData, condList)
% called by GUI_selectPlots if 'Plot all EPSC cell averages' is checked.
%
% Builds a drug-agnostic, cell-by-cell comparison structure linking each
% summary dot to its underlying average EPSC traces.
%
% This function:
%   1. Compares adjacent conditions in condList.
%        Example:
%           {'Control','AgaTK','AgaTK_AMN082'}
%        creates:
%           Control -> AgaTK
%           AgaTK   -> AgaTK_AMN082
%
%   2. Stores average traces for all available protocols:
%           SingleStim
%           Hz_5
%           Hz_20
%           Hz_40
%
%   3. Calculates percent change ONLY from SingleStim peaks.
%
% INPUTS:
%   compiledData : struct containing condition fields
%                  e.g. compiledData.Control, compiledData.AgaTK, etc.
%
%   condList     : cell array/string array of condition names
%                  e.g. {'AgaTK','AgaTK_AMN082'}
%
% OUTPUT:
%   ComparisonData.PairEntries
%       One entry per matched cell per adjacent condition comparison.
%
%   ComparisonData.DotTable
%       One row per matched cell-comparison.
%       Percent change is calculated from SingleStim peaks only.
%
% Example:
%   ComparisonData = buildEPSCComparisonData(compiledData, condList);

condList = cellstr(condList);

if numel(condList) < 2
    error('condList must contain at least two conditions.');
end

%% Define analysis-level protocol groups
protocolMap = getEPSCProtocolMap();
protocolNames = fieldnames(protocolMap);

%% Initialize output
ComparisonData = struct();
ComparisonData.condList = condList;
ComparisonData.protocolMap = protocolMap;
ComparisonData.protocolNames = protocolNames;
ComparisonData.PairEntries = struct([]);
ComparisonData.DotTable = table();

pairCounter = 0;
dotCounter = 0;

%% Loop through adjacent condition pairs
for pairIdx = 1:(numel(condList)-1)

    baseCond = condList{pairIdx};
    testCond = condList{pairIdx+1};

    if strcmpi(baseCond, 'None') || strcmpi(testCond, 'None')
        continue
    end

    if ~isfield(compiledData, baseCond)
        error('Condition "%s" not found in compiledData.', baseCond);
    end

    if ~isfield(compiledData, testCond)
        error('Condition "%s" not found in compiledData.', testCond);
    end

    baseData = compiledData.(baseCond);
    testData = compiledData.(testCond);

    baseExpts = {baseData.Expt};
    testExpts = {testData.Expt};

    sharedExpts = intersect(baseExpts, testExpts, 'stable');

    if isempty(sharedExpts)
        warning('No shared experiments found for %s -> %s.', baseCond, testCond);
        continue
    end

    %% Loop through matched cells/experiments
    for e = 1:numel(sharedExpts)

        exptName = sharedExpts{e};

        baseIdx = find(strcmp(baseExpts, exptName), 1);
        testIdx = find(strcmp(testExpts, exptName), 1);

        if isempty(baseIdx) || isempty(testIdx)
            continue
        end

        baseCellData = baseData(baseIdx);
        testCellData = testData(testIdx);

        pairCounter = pairCounter + 1;

        %% Basic metadata for this matched pair
        ComparisonData.PairEntries(pairCounter).PairID = pairCounter;
        ComparisonData.PairEntries(pairCounter).Expt = exptName;
        ComparisonData.PairEntries(pairCounter).ComparisonIndex = pairIdx;
        ComparisonData.PairEntries(pairCounter).BaseCondition = baseCond;
        ComparisonData.PairEntries(pairCounter).TestCondition = testCond;
        ComparisonData.PairEntries(pairCounter).ComparisonLabel = sprintf('%s -> %s', baseCond, testCond);

        %% Extract traces and peaks for every protocol
        for p = 1:numel(protocolNames)

            analysisProtocol = protocolNames{p};
            possibleSourceProtocols = protocolMap.(analysisProtocol);

            [baseTrace, baseTraceSource] = getAvgTrace(baseCellData, possibleSourceProtocols);
            [testTrace, testTraceSource] = getAvgTrace(testCellData, possibleSourceProtocols);

            [basePeaks, basePeakSource] = getAvgPeaks(baseCellData, possibleSourceProtocols);
            [testPeaks, testPeakSource] = getAvgPeaks(testCellData, possibleSourceProtocols);

            basePeakForPlot = choosePeakForSummary(basePeaks);
            testPeakForPlot = choosePeakForSummary(testPeaks);

            ComparisonData.PairEntries(pairCounter).(analysisProtocol).baseTrace = baseTrace;
            ComparisonData.PairEntries(pairCounter).(analysisProtocol).testTrace = testTrace;

            ComparisonData.PairEntries(pairCounter).(analysisProtocol).baseTraceSource = baseTraceSource;
            ComparisonData.PairEntries(pairCounter).(analysisProtocol).testTraceSource = testTraceSource;

            ComparisonData.PairEntries(pairCounter).(analysisProtocol).basePeaks = basePeaks;
            ComparisonData.PairEntries(pairCounter).(analysisProtocol).testPeaks = testPeaks;

            ComparisonData.PairEntries(pairCounter).(analysisProtocol).basePeakSource = basePeakSource;
            ComparisonData.PairEntries(pairCounter).(analysisProtocol).testPeakSource = testPeakSource;

            ComparisonData.PairEntries(pairCounter).(analysisProtocol).basePeakForSummary = basePeakForPlot;
            ComparisonData.PairEntries(pairCounter).(analysisProtocol).testPeakForSummary = testPeakForPlot;

            % Important:
            % Percent change is only meaningful here for SingleStim.
            % Train protocols are stored for trace review, but not used
            % for the percent-change dot plot.
            if strcmp(analysisProtocol, 'SingleStim')
                [percentBlock, percentChanged] = calculateEPSCPercentChanges( ...
                    basePeakForPlot, testPeakForPlot);
            else
                percentBlock = nan;
                percentChanged = nan;
            end

            ComparisonData.PairEntries(pairCounter).(analysisProtocol).percentBlock = percentBlock;
            ComparisonData.PairEntries(pairCounter).(analysisProtocol).percentChanged = percentChanged;
        end

        %% Add one DotTable row for this cell-comparison
        % This uses SingleStim peaks only.

        baseSinglePeak = ComparisonData.PairEntries(pairCounter).SingleStim.basePeakForSummary;
        testSinglePeak = ComparisonData.PairEntries(pairCounter).SingleStim.testPeakForSummary;

        baseSinglePeakSource = ComparisonData.PairEntries(pairCounter).SingleStim.basePeakSource;
        testSinglePeakSource = ComparisonData.PairEntries(pairCounter).SingleStim.testPeakSource;

        percentBlock = ComparisonData.PairEntries(pairCounter).SingleStim.percentBlock;
        percentChanged = ComparisonData.PairEntries(pairCounter).SingleStim.percentChanged;

        hasUsableSingleStimPeak = ~isnan(baseSinglePeak) && ~isnan(testSinglePeak);

        if hasUsableSingleStimPeak

            dotCounter = dotCounter + 1;

            newRow = table( ...
                dotCounter, ...
                pairCounter, ...
                pairIdx, ...
                string(exptName), ...
                string(baseCond), ...
                string(testCond), ...
                string(sprintf('%s -> %s', baseCond, testCond)), ...
                baseSinglePeak, ...
                testSinglePeak, ...
                percentBlock, ...
                percentChanged, ...
                string(baseSinglePeakSource), ...
                string(testSinglePeakSource), ...
                'VariableNames', { ...
                'DotID', ...
                'PairID', ...
                'ComparisonIndex', ...
                'Expt', ...
                'BaseCondition', ...
                'TestCondition', ...
                'ComparisonLabel', ...
                'BaseSingleStimPeak', ...
                'TestSingleStimPeak', ...
                'PercentBlock', ...
                'PercentChanged', ...
                'BasePeakSource', ...
                'TestPeakSource'});

            ComparisonData.DotTable = [ComparisonData.DotTable; newRow];
        end
    end
end

assignin('base', 'ComparisonData', ComparisonData);

fprintf('Built ComparisonData with %d matched cell-comparison entries and %d single-stim dot rows.\n', ...
    numel(ComparisonData.PairEntries), height(ComparisonData.DotTable));

end


%% ------------------------------------------------------------------------
function protocolMap = getEPSCProtocolMap()
% Maps analysis-level protocol names to possible source fields in compiledData.
%
% This keeps the function flexible for experiments where 20 Hz paired-pulse
% data may be stored as either x5_20Hz or Hz_20.

protocolMap = struct();

protocolMap.SingleStim = {'x1'};
protocolMap.Hz_5       = {'x5_5Hz'};
protocolMap.Hz_20      = {'x5_20Hz', 'Hz_20'};
protocolMap.Hz_40      = {'x5_40Hz'};

end


%% ------------------------------------------------------------------------
function [trace, sourceProtocol] = getAvgTrace(cellData, possibleProtocols)
% Finds the first available average trace from a list of possible protocols.

trace = [];
sourceProtocol = '';

for p = 1:numel(possibleProtocols)

    protocol = possibleProtocols{p};

    if isfield(cellData, protocol) && ...
            isstruct(cellData.(protocol)) && ...
            isfield(cellData.(protocol), 'avgWave') && ...
            ~isempty(cellData.(protocol).avgWave)

        trace = cellData.(protocol).avgWave(:);
        sourceProtocol = protocol;
        return
    end
end

end


%% ------------------------------------------------------------------------
function [peaks, sourceProtocol] = getAvgPeaks(cellData, possibleProtocols)
% Finds the first available AvgPeaks entry from a list of possible protocols.

peaks = [];
sourceProtocol = '';

if ~isfield(cellData, 'AvgPeaks') || isempty(cellData.AvgPeaks)
    return
end

for p = 1:numel(possibleProtocols)

    protocol = possibleProtocols{p};

    if isfield(cellData.AvgPeaks, protocol) && ...
            ~isempty(cellData.AvgPeaks.(protocol))

        peaks = cellData.AvgPeaks.(protocol)(:).';
        sourceProtocol = protocol;
        return
    end
end

end


%% ------------------------------------------------------------------------
function peakForSummary = choosePeakForSummary(peaks)
% Chooses the peak used for summary calculations.
%
% For SingleStim, this is the one EPSC peak.
% For train protocols, this returns the first peak, but those train values
% are NOT used for the DotTable percent-change calculation in this function.
    
if isempty(peaks)
    peakForSummary = nan;
else
    peakForSummary = peaks(1);
end

end



%% ------------------------------------------------------------------------
function [percentBlock, percentChange] = calculateEPSCPercentChanges(basePeak, testPeak)
% Calculates percent change for EPSC amplitudes.
%
% For negative EPSCs, PercentBlock is usually the useful value.
%
% Example:
%   basePeak = -135 pA
%   testPeak =  -88 pA
%
%   PercentBlock = 100 * ((-135) - (-88)) / (-135)
%                = 34.8
%
% Interpretation:
%   The EPSC amplitude was reduced by 34.8%.
%
% PercentSignedValueChange uses the signed current value:
%   100 * (testPeak - basePeak) / (basePeak)
%
% For standard negative EPSCs that get smaller, these two values will often
% be numerically the same.

if isnan(basePeak) || isnan(testPeak) || basePeak == 0
    percentBlock = nan;
    percentChange = nan;
    return
end

percentBlock = 100 * ((basePeak) - (testPeak)) / (basePeak);
percentChange = 100 * (testPeak - basePeak) / (basePeak);

end