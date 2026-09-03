function plotAverageEPSCs(WaveData)

temp = load('TrialTime_sec.mat');
TrialTime = temp.TrialTime;

conditions = WaveData.condList;
colors = assignColors(conditions);

displayNames = struct( ...
    'SingleStim', 'Single Stim', ...
    'Hz_20',      '20 Hz / Paired Pulse');

figure('Position', [312 127 1000 500]);
tiledlayout(1,2);

protocolsToPlot = {'SingleStim','Hz_20'};

for p = 1:numel(protocolsToPlot)

    protocol = protocolsToPlot{p};

    nexttile;
    hold on;

    legendEntries = {};

    for c = 1:numel(conditions)

        cond = conditions{c};

        if ~isfield(WaveData.avgWave, protocol) || ...
                ~isfield(WaveData.avgWave.(protocol), cond)
            continue
        end

        y = WaveData.avgWave.(protocol).(cond);

        if isempty(y) || all(isnan(y))
            continue
        end

        t = TrialTime.sec.ephys(:);
        nPts = min(numel(t), numel(y));

        plot(t(1:nPts), y(1:nPts), ...
            'Color', colors{c}, ...
            'LineWidth', 2, ...
            'DisplayName', cond);

        nWaves = WaveData.n.(protocol).(cond);
        legendEntries{end+1} = sprintf('%s, n=%d', cond, nWaves);
    end

    title(displayNames.(protocol), 'Interpreter', 'none');
    xlabel('Time (sec)');
    ylabel('EPSC (pA)');
    set(gca, 'FontSize', 14);

    legend(legendEntries, 'Location', 'best', 'Interpreter', 'none');

    switch protocol
        case 'SingleStim'
            xlim([0.08 0.20]);
        case 'Hz_20'
            xlim([0.08 0.40]);   % adjust this later to cut off last 3 peaks
    end

    ylim([-300 50]);
end

sgtitle(sprintf('Average EPSCs, %d matched cells', ...
    numel(WaveData.commonExpts)), ...
    'FontWeight', 'bold');

end