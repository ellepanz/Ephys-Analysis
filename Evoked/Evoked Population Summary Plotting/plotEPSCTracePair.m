function plotEPSCTracePair(ComparisonData, pairID)

% Plots the average EPSC traces for one matched cell-comparison entry.
%
% INPUTS:
%   ComparisonData : output from buildEPSCComparisonData
%   pairID         : PairID from ComparisonData.DotTable
%
% Example:
%   row = ComparisonData.DotTable(ComparisonData.DotTable.DotID == 4, :);
%   plotEPSCTracePair(ComparisonData, row.PairID)

if istable(pairID)
    error('Input pairID should be a number, not a table row.');
end

if numel(pairID) > 1
    pairID = pairID(1);
end

if pairID > numel(ComparisonData.PairEntries)
    error('PairID %d exceeds number of PairEntries.', pairID);
end

entry = ComparisonData.PairEntries(pairID);

% Get colors for base and test condition
traceColors = assignColors({entry.BaseCondition, entry.TestCondition});
baseColor = traceColors{1};
testColor = traceColors{2};

protocolsToPlot = {'SingleStim', 'Hz_20'};

figure;
tiledlayout(numel(protocolsToPlot), 1);

for p = 1:numel(protocolsToPlot)

    protocol = protocolsToPlot{p};

    nexttile

    if ~isfield(entry, protocol)
        title(sprintf('%s: not found', protocol), 'Interpreter', 'none');
        continue
    end

    baseTrace = entry.(protocol).baseTrace;
    testTrace = entry.(protocol).testTrace;
   
    if isempty(baseTrace) && isempty(testTrace)
        title(sprintf('%s: no trace data', protocol), 'Interpreter', 'none');
        continue
    end

    n = max([numel(baseTrace), numel(testTrace)]);
    x = (0:0.0001:1.3999)'; % assume trial length = 1.4s
    
    if ~isempty(baseTrace)
        baseTrace = padTrace(baseTrace, n);
        plot(x, baseTrace, 'color', baseColor, 'LineWidth', 1.5);
        hold on
    end

    if ~isempty(testTrace)
        testTrace = padTrace(testTrace, n);
        plot(x, testTrace, 'color', testColor, 'LineWidth', 1.5);
    end


    yline(0, '--');

    basePeak = ComparisonData.DotTable.BaseSingleStimPeak(pairID);
    secondPeak = min(baseTrace(1580:1620,:));
    percentChange = ComparisonData.DotTable.PercentChanged(pairID);


    xlim([0.08 0.2])
    ylim([secondPeak-150 100])

    xlabel('Time (ms)');
    ylabel('Amplitude (pA)'); 

    title(sprintf('%s', protocol), 'Interpreter', 'none');

    legend({entry.BaseCondition, entry.TestCondition}, ...
        'Interpreter', 'none', ...
        'Location', 'best');

    box off
end

sgtitle(sprintf('%% Change: %.1f | %s | %s', ...
    percentChange, entry.Expt, entry.ComparisonLabel), ...
    'Interpreter', 'none');



function trace = padTrace(trace, n)

trace = trace(:);

if numel(trace) < n
    trace(end+1:n, 1) = nan;
end

end
end