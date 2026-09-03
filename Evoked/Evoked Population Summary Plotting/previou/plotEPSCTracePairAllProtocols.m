function plotEPSCTracePairAllProtocols(ComparisonData, pairID)
% plotEPSCTracePairAllProtocols
%
% Plots all available protocols for one matched cell-comparison entry.
%
% Example:
%   plotEPSCTracePairAllProtocols(ComparisonData, 3)

if pairID > numel(ComparisonData.PairEntries)
    error('PairID %d exceeds number of PairEntries.', pairID);
end

entry = ComparisonData.PairEntries(pairID);r
protocolNames = ComparisonData.protocolNames;

figure;
tiledlayout(numel(protocolNames), 1);

for p = 1:numel(protocolNames)

    protocol = protocolNames{p};

    nexttile

    baseTrace = entry.(protocol).baseTrace;
    testTrace = entry.(protocol).testTrace;

    if isempty(baseTrace) && isempty(testTrace)
        title(sprintf('%s: no trace data', protocol), 'Interpreter', 'none');
        continue
    end

    n = max(numel(baseTrace), numel(testTrace));

    if ~isempty(baseTrace)
        baseTrace = padTrace(baseTrace, n);
        plot(1:n, baseTrace, 'LineWidth', 1.5);
        hold on
    end

    if ~isempty(testTrace)
        testTrace = padTrace(testTrace, n);
        plot(1:n, testTrace, 'LineWidth', 1.5);
    end

    yline(0, '--');

    title(protocol, 'Interpreter', 'none');
    xlabel('Sample');
    ylabel('Amplitude');

    legend({entry.BaseCondition, entry.TestCondition}, ...
        'Interpreter', 'none', ...
        'Location', 'best');

    box off
end

sgtitle(sprintf('PairID %d | %s | %s', ...
    pairID, entry.Expt, entry.ComparisonLabel), ...
    'Interpreter', 'none');

end


function trace = padTrace(trace, n)

trace = trace(:);

if numel(trace) < n
    trace(end+1:n, 1) = nan;
end

end