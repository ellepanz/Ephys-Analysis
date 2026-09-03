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

for h = 1:numel(HzList)
    Hz = HzList{h};
    nexttile;
    hold on

    for i = 1:numel(condList)
        cond = condList{i};

        if ~isfield(DataSum.(cond)(1), Hz)
            warning('%s missing field %s', cond, Hz);
            continue;
        end

        % collect avgWaves across experiments
        allTraces = [];
        for e = 1:numel(DataSum.(cond))
            if isfield(DataSum.(cond)(e), Hz) && ...
                    isfield(DataSum.(cond)(e).(Hz),'avgWave')
                thisTrace = DataSum.(cond)(e).(Hz).avgWave(:);

                % pad or truncate to match x length
                L = min(length(thisTrace), length(x));
                padded = nan(length(x),1);
                padded(1:L) = thisTrace(1:L);

                allTraces(:,end+1) = padded;
            end
        end

        if isempty(allTraces)
            continue
        end

        % population mean
        popMean = mean(allTraces, 2, 'omitnan');
        plot(x, popMean, 'Color', condColors{i}, 'LineWidth', 2);
    end

    % Calculate xlim based on Hz
    switch h
        case 1; xlim([0.09 0.2]);
        case 2; xlim([0.09 1]);
        case 3; xlim([0.09 0.6]);
        case 4; xlim([0.09 0.8]);
    end

    % Calculate ylim based on first EPSC peaks
    lines = findall(gca, 'Type', 'line');
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
        ylim([ymin ymax]);
    end

    title(titles{h});
    legend(condList, 'Interpreter','none');

end
xlabel(t, 'Time (sec)');
ylabel(t, 'pA');

end

