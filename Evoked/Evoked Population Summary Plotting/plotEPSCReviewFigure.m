function plotEPSCReviewFigure(ComparisonData, pairID)
% plotEPSCReviewFigure
%
% Plots average EPSC traces plus Rs/Rin QC for one matched cell-comparison.

if pairID > numel(ComparisonData.PairEntries)
    error('PairID %d exceeds number of PairEntries.', pairID);
end

entry = ComparisonData.PairEntries(pairID);

protocolsToPlot = {'SingleStim', 'Hz_20'};

traceColors = assignColors({entry.BaseCondition, entry.TestCondition});
baseColor = traceColors{1};
testColor = traceColors{2};

QC = extractRsRinFromFigure(entry.Source.rsFigureFile);
QC.PairID = pairID;
QC.Expt = entry.Expt;
QC.BaseCondition = entry.BaseCondition;
QC.TestCondition = entry.TestCondition;
QC.ComparisonLabel = entry.ComparisonLabel;

fig = figure( ...
    'Name', sprintf('Review | PairID %d - %s', pairID, entry.Expt), ...
    'NumberTitle', 'off', ...
    'Position', [250 100 950 800]);

t = tiledlayout(numel(protocolsToPlot) + 1, 1, ...
    'TileSpacing', 'compact', ...
    'Padding', 'compact');

sgtitle(sprintf('PairID %d | %s | %s', ...
    pairID, entry.Expt, entry.ComparisonLabel), ...
    'Interpreter', 'none');

%% Plot average traces 
for p = 1:numel(protocolsToPlot)

    protocol = protocolsToPlot{p};

    ax = nexttile(t);
    hold(ax, 'on');

    baseTrace = entry.(protocol).baseTrace;
    testTrace = entry.(protocol).testTrace;
    firstPeak = min(baseTrace(1080:1140, :));
    secondPeak = min(baseTrace(1580:1620,:));

    n = max(numel(baseTrace), numel(testTrace));
    x = (0:n-1)' * 0.0001; % seconds, assuming 10 kHz sampling
    
    if p == 1
        ylim([firstPeak-100 100])
    else
        ylim([secondPeak-100 100])
    end

    if ~isempty(baseTrace)
        plot(ax, x, baseTrace(:), ...
            'Color', baseColor, ...
            'LineWidth', 1.5, ...
            'DisplayName', entry.BaseCondition);
    end

    if ~isempty(testTrace)
        plot(ax, x, testTrace(:), ...
            'Color', testColor, ...
            'LineWidth', 1.5, ...
            'DisplayName', entry.TestCondition);
    end

    yline(ax, 0, '--', 'HandleVisibility', 'off');

    title(ax, protocol, 'Interpreter', 'none');
    xlabel(ax, 'Time (s)');
    ylabel(ax, 'pA');
    xlim(ax, [0.08 0.2]);

    legend(ax, 'Interpreter', 'none', 'Location', 'best');

end


%% ---- QC tile ----
axQC = nexttile(t);
hold(axQC, 'on');

if ~isempty(QC.Rs.y)
    plot(axQC, QC.Rs.x, QC.Rs.y, 'o', ...
        'LineWidth', 1.2, ...
        'DisplayName', 'Rs');
end

if isfield(QC, 'Rin') && ~isempty(QC.Rin.y)
    plot(axQC, QC.Rin.x, QC.Rin.y, 'o', ...
        'LineWidth', 1.2, ...
        'DisplayName', 'Rin');
end

maxQC = max(QC.Rs.y);

title(axQC, 'R_s');
xlabel(axQC, 'Trial');
ylabel(axQC, 'M\Omega');
ylim([0 maxQC+5])


end