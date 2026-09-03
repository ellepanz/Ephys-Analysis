function plotEPSCTrains(DataSum, condList)

HzList = {'x1','x5_5Hz','x5_20Hz','x5_40Hz'};
titles = {'Single Stim','5 Hz','20 Hz','40 Hz'};
condColors = getCondColors(condList);

% load TrialTime
load('TrialTime_sec.mat');
x = TrialTime.sec.ephys;

% Create figure and tiled layout once
figure('Name','EPSC Trains');
t = tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

% Assume last condition is the “combined” condition to pair experiments
lastCond = condList{end};
expIDs = {DataSum.(lastCond).Expt};  % cell array of strings for combined experiments

for h = 1:numel(HzList)
    Hz = HzList{h};
    ax = nexttile;
    hold(ax,'on');

    for i = 1:numel(condList)
        cond = condList{i};

        % Find experiments in this condition that match lastCond
        thisExp = DataSum.(cond);
        if ~isfield(thisExp, 'Expt')
            warning('%s missing Expt field', cond);
            continue;
        end

        % Get indices in this condition that match expIDs of lastCond
        matchIdx = find(ismember({thisExp.Expt}, expIDs));
        if isempty(matchIdx)
            warning('%s has no matching experiments with %s', cond, lastCond);
            continue;
        end

        % collect avgWaves across matched experiments
        allTraces = [];
        for idx = matchIdx
            if isfield(thisExp(idx), Hz) && isfield(thisExp(idx).(Hz),'avgWave')
                thisTrace = thisExp(idx).(Hz).avgWave(:);
                L = min(length(thisTrace), length(x));
                padded = nan(length(x),1);
                padded(1:L) = thisTrace(1:L);
                allTraces(:,end+1) = padded;
            end
        end

        numExpts = size(allTraces, 2);
        if isempty(allTraces)
            continue
        end

        % population mean
        popMean = mean(allTraces, 2, 'omitnan');
        plot(ax, x, popMean, 'Color', condColors{i}, 'LineWidth', 2);
    end

    % xlim per Hz
    switch h
        case 1; xlim(ax,[0.09 0.2]);
        case 2; xlim(ax,[0.09 1]);
        case 3; xlim(ax,[0.09 0.6]);
        case 4; xlim(ax,[0.09 0.8]);
    end

    % ylim based on first EPSC peaks
    lines = findall(ax, 'Type', 'line');
    xrange = [0.105 0.120];
    allY = [];
    for li = 1:numel(lines)
        lx = get(lines(li), 'XData');
        ly = get(lines(li), 'YData');
        inRange = lx >= xrange(1) & lx <= xrange(2);
        allY = [allY, ly(inRange)];
    end
    if ~isempty(allY)
        ymin = min(allY)-100;
        ymax = max(allY)+60;
        ylim(ax,[ymin ymax]);
    end

    title(ax, titles{h});
end

xlabel(t, 'Time (sec)');
ylabel(t, 'pA');
legend(condList,'interpreter','none')
sgtitle(sprintf('Average EPSCs, n = %d cells', numExpts))
end
