% version 1: 6/7/25
% v2: 6/24/25-6/26/25. Tweaked colors in avgviewparts to bone and removed NaNs from Rs. Added more plotting to plot PPR and a section to choose to plot all waves, and a figure to overlay avgWave with first peak sub
% v3: 7/8/25: Redid order, added section to plot peaks over time with
% pharmacology
% v4: 8/14/25. Stopped using scanimage calculation of Rs, redo with actual
% calculations

%%

folder = "\\bunson\bunson\Higley_Lab\Lauren bunsen\260505 - LP254 - cono amn082 estim\cell B";
figureFolder = fullfile(folder, 'Matlab figures cell C');
mkdir(figureFolder)
addpath(genpath(figureFolder))

Expt.marker = 'LP254c';
Expt.date = '260505';
Expt.internal = 'CsGluc';
Expt.stim = 'theta L2/3';
Expt.temp = 'RT';
Expt.CaMg = '1.2mM Ca, 1mM Mg';
Expt.region = 'V1';
Expt.trialInterval = 15; % ISI seconds
Expt.cellType = 'pyramidal L2/3';


dataset = 'ConoGVIA'; % what datasum variable do you want to pull at the end?
Epoch1 = 'e8';        Cond1 = 'ConoGVIA';
Epoch2 = 'e9';        Cond2 = 'ConoGVIA_AMN082'; % ConoGVIA, can't have -
%Epoch3 = 'e12';        Cond3 = 'ConoGVIA_AMN082';
Expt.concentrations = {'1uM', '100uM'};

Hzs = {'x1', 'Hz_20'}; % must have letter first
HzNames = {'1','20Hz'};

ps = arrayfun(@(x) ['p' num2str(x)], 1:numel(Hzs), 'UniformOutput', false);

epochs = {Epoch1, Epoch2};
conditions = {Cond1, Cond2};
numPositions = numel(ps);

assignColors(conditions); Colors
[Expt, Data] = compileEphysData(epochs, folder, conditions, Hzs, Expt, figureFolder);

%% Delete waves (only delete spiking, trials that are obviously off, not just not averaged for pharmacology)
clear h; clear lineHandles;

for p = 1:length(conditions)
    pharm = conditions{p};

    fig = figure('Name', pharm, 'NumberTitle', 'off', 'Position', [310 50 1254 946]);
    t = tiledlayout(2, 2, 'TileSpacing', 'compact');
    sgtitle(pharm);

    lineHandles = cell(numPositions, 1);
    allData = cell(numPositions, 1);

    for j = 1:numPositions
        Hz = Hzs{j};

        nexttile;
        hold on;
        allTrials = Data.(pharm).(Hz).allTrials; % pulls all trials from a particular epoch/position
        allData{j} = allTrials;
        lineHandles{j} = gobjects(size(allTrials, 2), 1); % preallocates graphics placeholders

        ADNames = Data.(pharm).(Hz).ADNames; % AD0_104 etc
        nTrials = size(allTrials,2);
        boneMap = flipud(bone(nTrials));
        boneMap(boneMap == 1) = 0.9;% Light to dark from bone colormap
        for trialIdx = 1:size(allTrials, 2)
            traceColor = boneMap(trialIdx, :);  %parula(trialIdx, :)
            h = plot(allTrials(:, trialIdx), 'color', traceColor, 'DisplayName', ADNames{trialIdx});
            h.ButtonDownFcn = @(src, ~) set(src, 'Visible', 'off');
            lineHandles{j}(trialIdx) = h;
        end

        title(Hz, 'Interpreter', 'none');
        xlabel('Time'); ylabel('pA');
        legend('interpreter', 'none', 'Location', 'bestoutside');

        % Calculate ylim
        lines = findall(gca, 'Type', 'line');

        % Desired x-range to find minimum of first peaks
        xrange = [1050 1200];
        allY = [];  % collect y-values within the range

        for i = 1:numel(lines)
            x = get(lines(i), 'XData');
            y = get(lines(i), 'YData');

            % Keep only y-values within your x-range
            inRange = x >= xrange(1) & x <= xrange(2);
            allY = [allY, y(inRange)];
        end

        % Now set Y-limits based on that range
        ymin = min(allY);
        ymax = max(allY);
        ylim([ymin-200, ymax+100]);  % add buffer
    end

    % Corrected 'Done' button callback with fig handle
    uicontrol('Style', 'pushbutton', 'String', 'Done', ...
        'Position', [20, 20, 100, 30], ...
        'Callback', @(~, ~) finalizeCurrentFigure(Hzs, lineHandles, pharm, allData, fig));

    waitfor(fig);  % Will unblock only when fig is closed
end


%% Plot all waves for particular epoch
% Get user selection via checkbox dialog
selectPharmsWithCheckbox(conditions);

if isempty(selectedIdx)
    disp('No conditions selected. Aborting.');
    return;
end

%Proceed only with selected conditions
for idx = selectedIdx
    pharm = conditions{idx};
    pharmName = conditions{idx};
    disp(['Plotting: ' pharm])  % Debug output

    fig = figure('Name', pharm, 'NumberTitle', 'off', 'Position', [310 50 1254 946]);
    t = tiledlayout(2, 2, 'TileSpacing', 'compact');
    sgtitle(pharmName);

    lineHandles = cell(numPositions, 1);
    allData = cell(numPositions, 1);

    for j = 1:numPositions
        Hz = Hzs{j};
        nexttile;
        hold on;

        allTrials = Data.(pharm).(Hz).allTrials;
        allData{j} = allTrials;
        lineHandles{j} = gobjects(size(allTrials, 2), 1);

        ADNames = Data.(pharm).(Hz).ADNames;
        nTrials = size(allTrials, 2);
        boneMap = flipud(bone(nTrials));
        boneMap(boneMap == 1) = 0.9;

        for trialIdx = 1:nTrials
            traceColor = boneMap(trialIdx, :);
            h = plot(allTrials(:, trialIdx), 'color', traceColor, 'DisplayName', ADNames{trialIdx});
            h.ButtonDownFcn = @(src, ~) set(src, 'Visible', 'off');
            lineHandles{j}(trialIdx) = h;
        end

        title(Hz, 'Interpreter', 'none');
        xlabel('Time'); ylabel('pA');
        legend('interpreter', 'none', 'Location', 'bestoutside');

        switch j
            case 1; xlim([800 1600]);
            case 2; xlim([800 12000]);
            case 3; xlim([800 5000]);
            case 4; xlim([800 4000]);
        end
        % Calculate ylim
        lines = findall(gca, 'Type', 'line');

        % Desired x-range to find minimum of first peaks
        xrange = [1050 1200];
        allY = [];  % collect y-values within the range

        for i = 1:numel(lines)
            x = get(lines(i), 'XData');
            y = get(lines(i), 'YData');

            % Keep only y-values within your x-range
            inRange = x >= xrange(1) & x <= xrange(2);
            allY = [allY, y(inRange)];
        end

        % Now set Y-limits based on that range
        ymin = min(allY);
        ymax = max(allY);
        ylim([ymin-100, ymax+40]);  % add buffer
    end
end



%% Collect all trials, base subtract and calculate minima of first stim. Choose trials for averaging. Plot Rs and Rin
Data.allTrials = {};
Data.basesuballTrials = struct();
Data.allfirststimPeaks = struct();

for i = 1:numel(conditions)
    pharm = conditions{i};

    for j = 1:numel(Hzs)
        Hz = Hzs{j};

        adFields = fieldnames(Data.(pharm).(Hz).finalallTrials);  % e.g., {'AD_09', 'AD_10', ...}

        for k = 1:numel(adFields)
            ADName = adFields{k};
            if  ~isempty(regexp(ADName, '^AD0_\d+$', 'once')) %^=start of string, \d+ = one or more digits, $ = end of string

                Data.allTrials.(ADName) = Data.(pharm).(Hz).finalallTrials.(ADName);
            end
        end
    end
end


% Sort allTrials
fieldNames = fieldnames(Data.allTrials);  % e.g., {'AD0_32', 'AD0_124', 'AD0_24'}

% Step 2: Extract numeric parts from the names
fieldNums = cellfun(@(s) sscanf(s, 'AD0_%d'), fieldNames);

% Step 3: Sort by numeric value
[~, sortIdx] = sort(fieldNums);
sortedFieldNames = fieldNames(sortIdx);

% Step 4: Rebuild struct in sorted order
sortedStruct = struct();
for i = 1:numel(sortedFieldNames)
    name = sortedFieldNames{i};
    sortedStruct.(name) = Data.allTrials.(name);
end

% Step 5: Replace original with sorted version
Data.allTrials = sortedStruct;

% Baseline subtract
for i = 1:numel(fieldnames(Data.allTrials))
    name = sortedFieldNames{i};
    wave = Data.allTrials.(name);
    baseline = mean(wave(1:800,:));
    Data.basesuballTrials.(name) = wave - baseline;
end

win = 1050:1200;
% Calculate peaks
for i = 1:numel(fieldnames(Data.basesuballTrials))
    name = sortedFieldNames{i};
    wave = Data.basesuballTrials.(name);

    [~, localMinIdx] = min(wave(win)); % calculate minima
    minCenter = win(1) + localMinIdx -1;
    avgWindow = minCenter-4:minCenter+4; % average over a total of 1.3ms
    minima = mean(wave(avgWindow));

    Data.allfirststimPeaks.(name) = minima;

end

disp('Trials compiled and baseline subtracted.')

% Plot EPSC peaks of all first stims

% Setup figure
f = figure('Position', [199         636        1560         263]);
hold on;
xlabel('Trial');
ylabel('Peak EPSC Amplitude');
title('Peak EPSCs Over Time by Condition');

% Create color map
colorMap = containers.Map;
for p = 1:numel(conditions)
    pharm = conditions{p};
    colorMap(pharm) = color{p};
    Data.(pharm).ADNames = {};  % initialize
end

trialCount = 0;  % running total trial index
fieldNames = fieldnames(Data.basesuballTrials);

for i = 1:numel(fieldNames)
    ADName = fieldNames{i};  % e.g., 'AD0_32'
    peakVals = Data.allfirststimPeaks.(ADName);  % vector of amplitudes for that AD

    % Identify matching pharmacology condition
    pharmMatch = '';
    for p = 1:numel(conditions)
        pharm = conditions{p};
        for h = 1:numel(Hzs)
            Hz = Hzs{h};
            if isfield(Data.(pharm).(Hz), ADName)
                pharmMatch = pharm;
                Data.(pharm).ADNames{end+1} = ADName;
                break;
            end
            nums = cellfun(@(s) str2double(erase(s, 'AD0_')), Data.(pharm).ADNames);
            [~, order] = sort(nums);
            Data.(pharm).ADNames = Data.(pharm).ADNames(order);

        end
        if ~isempty(pharmMatch), break; end

    end

    if isempty(pharmMatch)
        warning('No matching pharm found for %s', ADName);
        continue;
    end

    nTrials = numel(peakVals);  % trials for this ADName
    timePoints = (trialCount + (1:nTrials));

    scatter(timePoints, peakVals, 40, ...
        'MarkerFaceColor', colorMap(pharm), ...
        'MarkerEdgeColor', 'k', ...
        'DisplayName', pharm);
    datacursormode on;
    trialCount = trialCount + nTrials;  % increment for next ADName
end

% Plot invisible point for legend
legendHandles = gobjects(1, numel(conditions));  % preallocate graphic handles
for p = 1:numel(conditions)
    pharm = conditions{p};
    c = colorMap(pharm);  % color for this condition
    pharmLegend = conditions{p};

    % % Plot 1 invisible point for legend
    legendHandles(p) = scatter(nan, nan, 40, ...
        'MarkerFaceColor', c, ...
        'MarkerEdgeColor', 'k', ...
        'DisplayName', pharmLegend);
end

% Draw vertical lines every 10 minutes
legend(legendHandles, 'Location', 'westoutside');
lineSpacing = (60/Expt.trialInterval)*5; % 5 minutes
xMax = ceil(max(timePoints) / 5) * 5;
xlim([0 xMax]);
vlineTimes = lineSpacing * (1:ceil(xMax/lineSpacing));
for x = vlineTimes
    xline(x, 'k:', 'LineWidth', 1.5);
end


saveas(gcf, sprintf('%s/%s', figureFolder, 'EPSC amplitude peaks over conditions'))

%---- CREATE GUI TO INPUT FIRST/LAST TRIALS FOR AVERAGING ----
% Create figure
for p = 1:length(conditions)
    pharm = conditions{p};
    parts = split(Data.(pharm).ADNames(1,1), '_');
    Data.(pharm).firstTrialNum = parts(2);
    parts = split(Data.(pharm).ADNames(1,end),'_');
    Data.(pharm).lastTrialNum = parts(2);
end

f = figure('Name','Input First/Last Trials for Averaging', 'position', [1126 623 389 159]);

avginghandles = struct();
guidata(f, avginghandles)

row = length(conditions);
trialCount = 1;

for p = 1:length(conditions)
    pharm = conditions{p};

    nTrials = numel(fieldnames(Data.basesuballTrials));

    uicontrol(f,"Style","text", 'String',...
        sprintf('%s, First Trial:', pharm),'Position',...
        [10, 40*row, 180, 20], 'HorizontalAlignment', 'left');
    avginghandles.(pharm).start = ...
        uicontrol(f, 'Style', 'edit', 'Position', [190, 40*row, 60, 20]);

    uicontrol(f, 'Style', 'text', 'String', ...
        sprintf('Last Trial:'), ...
        'Position', [260, 40*row, 100, 20], 'HorizontalAlignment', 'left');
    avginghandles.(pharm).end = ...
        uicontrol(f, 'Style', 'edit', 'Position', [315, 40*row, 60, 20]);

    row = row - 1;
end

% Submit trials for averaging UI
uicontrol(f, 'Style','pushbutton','String','Submit', 'Position', [150, 10, 100, 30], ...
    'callback', @(src, event) submitCallbackEPHYS(f, Data, avginghandles, conditions));
uiwait(f);  
close all;
disp('Submit clicked and figure closed.');

% ---- Calculate Rs and Rin ----
calcRs = NaN(1,length(fieldNames));
voltageStep = 0.005; % (V)
for i = 1:length(fieldNames)
    trial = fieldNames{i};
    wave = Data.basesuballTrials.(trial);
    Rs = abs(5/(wave(12003)-mean(wave(11980:12000)))*1000);
    Rin = 
    calcRs(i) = Rs;
end

% Plot Rs
figure;
scatter(1:length(fieldNames),calcRs)
ylabel('R_s')
xlabel('Trial')
title(Expt.marker)
ymax = round(max(calcRs))+3;
ylim([0 ymax])
saveas(gcf,sprintf('%s/%s', figureFolder, 'Rs'))
ymax = round(max(calcRs))+3;
ylim([0 ymax]) 


%% Calculate first stim averages, plot all averages by Hz
for p = 1:length(conditions)
    pharm = conditions{p};
    startIdx = Data.(pharm).firstTrialAvgIdx;
    endIdx = Data.(pharm).lastTrialAvgIdx;

    % Get trial names for this condition
    trialNames = fieldnames(Data.basesuballTrials);
    nTrials = numel(trialNames);

    % Bounds check
    if startIdx < 1 || endIdx > nTrials
        warning('%s: Trial index out of bounds (start=%d, end=%d, total=%d). Skipping.', ...
            pharm, startIdx, endIdx, nTrials);
        continue;
    end

    % Initialize array to hold selected trials
    win = [900 1252];
    trialLength = win(2) - win(1) + 1;
    Data.(pharm).firststimavgingTrials = zeros(trialLength, endIdx - startIdx + 1);


    % Collect data
    for i = startIdx:endIdx
        thisTrialName = trialNames{i};
        Data.(pharm).firststimavgingTrials(:, i - startIdx + 1) = Data.basesuballTrials.(thisTrialName)(win(1):win(2));

    end

    % Compute the average trace
    Data.(pharm).firststimavgTrace = mean(Data.(pharm).firststimavgingTrials, 2);

end
% Plot first stim average of all conditions
figure('Position',[317   454   560   420], 'Visible','off');
plotHandles = gobjects(1, length(conditions));

for p = 1:length(conditions)
    pharm = conditions{p};

    hold on;
    plotHandles(p) = plot(0:1:352,Data.(pharm).firststimavgTrace, 'color',color{p}, 'linewidth', 1.5);
    title('Average EPSCs')
    ylabel('pA')
    xlabel('Time (msec)')
    xlim([0 350])
    % ylim([-350 100])
end
legend(plotHandles, conditions, 'location','southwest')

saveas(gcf,sprintf('%s/%s%s', figureFolder, 'Average first stim EPSCs over conditions'));
close all


% Calculate frequency averages
for p = 1:length(conditions)
    pharm = conditions{p};
    firstIdx = Data.(pharm).firstTrialAvgIdx;
    lastIdx = Data.(pharm).lastTrialAvgIdx;

    trialNamesToAvg = trialNames(firstIdx:lastIdx);  % the trials to average that you've determined are stable

    for h = 1:length(Hzs)
        Hz = Hzs{h};

        % Check that the Hz field exists
        if ~isfield(Data.(pharm), Hz) || ~isfield(Data.(pharm).(Hz), 'basesubTrials')
            continue;
        end

        % Get the list of trials in this Hz condition
        if isfield(Data.(pharm).(Hz), 'ADNames')
            hzTrialNames = Data.(pharm).(Hz).ADNames;
        end   %else
        %     % If ADNames doesn't exist, extract it from the fieldnames
        %     hzTrialNames = fieldnames(Data.(pharm).(Hz));
        %     % Remove non-trial fields
        %     exclude = {'allTrials', 'waveNames', 'basesubTrials', 'finalallTrials', 'avgdWaves', 'avgWave'};
        %     hzTrialNames = setdiff(hzTrialNames, exclude);
        %     Data.(pharm).(Hz).ADNames = hzTrialNames;  % store it for future use
        % end

        % Match trials from averaging list to this Hz
        matchedCols = []; % indexs of which ADs in hzNames ((Hz).ADNames to pull, should be index of
        for i = 1:length(trialNamesToAvg)
            trial = trialNamesToAvg{i};
            colIdx = find(strcmp(hzTrialNames, trial));
            if ~isempty(colIdx)
                matchedCols(end+1) = colIdx;
            end
        end

        % Extract and average if any matched
        if ~isempty(matchedCols)
            basesub = Data.(pharm).(Hz).basesubTrials;
            Data.(pharm).(Hz).avgdWaves = basesub(:, matchedCols);
            Data.(pharm).(Hz).avgWave = mean(basesub(:, matchedCols), 2);
        else
            warning('%s.%s: No matching trials found for averaging.', pharm, Hz);
        end
    end
end

% Plot average traces of all freqs and conds List of pharmacology

figure('position',[787   181   536   706]);

for j = 1:length(Hzs)
    Hz = Hzs{j};
    nexttile
    hold on

    for p = 1:length(conditions)
        pharm = conditions{p};
        pharmName = conditions{p};

        plot(Expt.ms, Data.(pharm).(Hz).avgWave,'DisplayName', pharmName, 'color', color{p},'linewidth',1.5);
        % switch j
        %     case 1; xlim([80 200]);
        %     case 2; xlim([80 1100]);
        %     case 3; xlim([80 400]);
        %     case 4; xlim([80 300]);
        % end
        xlim([0 600])

    end
    legend('interpreter', 'tex','location','best')
    xlabel('Time (ms)')
    ylabel('pA')
    sgtitle('Average EPSCs','FontSize', 18)
    % Calculate ylim
    lines = findall(gca, 'Type', 'line');

    % Desired x-range to find minimum of first peaks
    xrange = [105 120];
    allY = [];  % collect y-values within the range

    for i = 1:numel(lines)
        x = get(lines(i), 'XData');
        y = get(lines(i), 'YData');

        % Keep only y-values within your x-range
        inRange = x >= xrange(1) & x <= xrange(2);
        allY = [allY, y(inRange)];
    end

    % % Now set Y-limits based on that range
    ymin = min(allY);
    ymax = max(allY);
    ylim([ymin-200, ymax+10]);  % add buffer
end
saveas(gcf,sprintf('%s/%s', figureFolder, 'averages of all freqs and conds'))

%% Find relative peaks of trains & normalize peaks
% Define detection windows
minWindows = [];
minWindows.x1 = [1050 1200];
% minWindows.x5_5Hz = [1050 1200; 3050 3200; 5050 5200; 7050 7200; 9050 9200];
% minWindows.Hz_20 = [1050 1200; 1550 1700; 2050 2200; 2550 2700; 3050 3200];
minWindows.Hz_20 = [1050 1200; 1550 1700]; % current expts only doing paired pulse not 5stim trains
% minWindows.x5_40Hz = [1050 1200; 1300 1450; 1550 1700; 1800 1950; 2050 2200];

for p = 1:length(conditions)
    pharm = conditions{p};

    for j = 1:length(Hzs)
        Hz = Hzs{j};

        winList = minWindows.(Hz);
        wave = Data.(pharm).(Hz).avgWave;

        for stim = 1:size(winList, 1)
            win = winList(stim, 1):winList(stim, 2);
            [~, localMinIdx] = min(wave(win));
            minCenter = win(1) + localMinIdx - 1;

            avgWindow = minCenter-4:minCenter+4;
            minima= mean(wave(avgWindow));

            Data.(pharm).Peaks.(Hz)(stim) = minima;

            if stim == 1 && j == 1
                Data.PPR.(pharm).x1peak = minima;
            end
        end
    end
end


% Normalize Peaks
for p = 1:length(conditions)
    pharm = conditions{p};

    for j = 1:length(Hzs)
        Hz = Hzs{j};

        if j == 1

            Data.(pharm).NormPeaks.(Hz)(1) = Data.(pharm).Peaks.(Hz)/Data.(pharm).Peaks.(Hz);

        elseif j > 1
            for stim = 1:numPositions
                Data.(pharm).NormPeaks.(Hz)(stim) = Data.(pharm).Peaks.(Hz)(1,stim)/Data.(pharm).Peaks.(Hz)(1,1);
            end
        end
    end
end
 % Plot normalized peaks

 % HzNames = {'1','5Hz','20Hz','40Hz'};
% if numel(conditions) >= 2
%     if strcmp(conditions{2}, 'AgaTK')
%         color{2} = colors.Aga;
%     elseif strcmp(conditions{2}, 'CdCl2')
%         color{2} = colors.Cono;
%     end
% end
% 
% if numel(conditions) >= 3
%     if contains(conditions{3}, 'CdCl2')
%         color{3} = colors.CdCl2;
%     end
% end

figure;

for j = 2:length(Hzs)
    Hz = Hzs{j};
    HzName = HzNames{j};
    ax = nexttile;
    hold on
    if j == 2
        legend(ax, 'interpreter', 'none', 'location','bestoutside')
    end
    for p = 1:2
        pharm = conditions{p};
        pharmName = conditions{p};
        plot(Data.(pharm).NormPeaks.(Hz),'-o','DisplayName', pharmName, 'color', color{p});
        title(HzName)

        xticks(1:5)
        xlabel('Stim Number')
        ylabel('Normalized EPSC amplitude')
        yline(1,'--','color',colors.gray)

    end
end

saveas(gcf, sprintf('%s/%s', figureFolder, 'normalized EPSC amplitudes'))

%% Subtract first peak, calculate PPR

for p = 1:length(conditions)
    pharm = conditions{p};

    for j = 2:length(Hzs)
        Hz = Hzs{j};

        Data.PPR.(pharm).firstPkSubtrd.(Hz) = Data.(pharm).(Hz).avgWave - Data.(pharm).x1.avgWave;
    end
end
% n = 1:length(Data.Control.x1.avgWave);


% Plot overlaid traces
figure('position',[312 127 1365 823],'visible','off');
for p = 1:(length(conditions))-1
    pharm = conditions{p};

    for j = 2:length(Hzs)
        Hz = Hzs{j};

        nexttile
        hold on
        plot(Data.(pharm).x1.avgWave,'--','linewidth',1.5,'color',colors.gray)
        plot(Data.(pharm).(Hz).avgWave,'color',color{2})
        plot(Data.PPR.(pharm).firstPkSubtrd.(Hz),'color',colors.blues.medium)
        % switch j
        %     case 1; xlim([800 2000]);
        %     case 2; xlim([800 11000]);
        %     case 3; xlim([800 4000]);
        %     case 4; xlim([800 3000]);
        % end
        % Calculate ylim
        lines = findall(gca, 'Type', 'line');

        % Desired x-range to find minimum of first peaks
        xrange = [1050 1200];
        allY = [];  % collect y-values within the range

        for i = 1:numel(lines)
            x = get(lines(i), 'XData');
            y = get(lines(i), 'YData');

            % Keep only y-values within your x-range
            inRange = x >= xrange(1) & x <= xrange(2);
            allY = [allY, y(inRange)];
        end

        % Now set Y-limits based on that range
        ymin = min(allY);
        ymax = max(allY);
        ylim([ymin-100, ymax+40]);  % add buffer
        title(pharm, Hz,'interpreter','none')
        legend('Single stim','Average','First Peak Subtracted','location','best')
    end
end
saveas(gcf,sprintf('%s/%s', figureFolder,'Overlaid Averages with First Peak subtracted'))

% Calculate PPR
for p = 1:2
    pharm = conditions{p};

    for j = 2:length(Hzs)
        Hz = Hzs{j};

        winList = minWindows.(Hz);
        wave = Data.PPR.(pharm).firstPkSubtrd.(Hz);

        for stim = 2
            win = winList(stim, 1):winList(stim, 2);
            [~, localMinIdx] = min(wave(win));
            minCenter = win(1) + localMinIdx - 1;

            avgWindow = minCenter-4:minCenter+4;
            minima= mean(wave(avgWindow));

            Data.PPR.(pharm).(Hz).secondPeak = minima;

        end
        Data.PPR.(pharm).(Hz).PPR = Data.PPR.(pharm).(Hz).secondPeak / Data.PPR.(pharm).x1peak;
    end
end
disp('PPR calculated.')


figure('Position',[680 219 484 659]);
t = tiledlayout(3,1);
for j = 2:length(Hzs)
    Hz = Hzs{j};
    HzName = HzNames{j};
    ax = nexttile;
    hold on
    if j == 2
        legend(ax, 'interpreter', 'none', 'location','bestoutside')
    end
    for p = 1:2
        pharm = conditions{p};
        pharmName = conditions{p};

        plot(1,Data.PPR.(pharm).(Hz).PPR,'o','MarkerSize',8, 'color', color{p},'DisplayName',pharmName);
        yline(1,'--','color', colors.grays.medium,'HandleVisibility','off')
        title(HzName)
        xticks([])
        ylabel(t,'PPR')

    end
end

saveas(gcf, sprintf('%s/%s', figureFolder, 'PPR'))

%%
tic

% Mapping of Pharm1 to mat file + variable name
map = struct( ...
    'AgaTK',     struct('matfile', 'EPSCsAgaTK.mat',   'varname', 'AgaTK'), ...
    'ConoGVIA',  struct('matfile', 'EPSCsConoGVIA.mat',  'varname', 'ConoGVIA'), ...
    'Muscarine', struct('matfile', 'EPSCsMuscarine.mat',  'varname', 'Muscarine'), ...
    'WIN', struct('matfile', 'EPSCsWIN.mat',  'varname', 'WIN') ...
    );

% Check Pharm1 is valid
if ~isfield(map, dataset)
    error('Pharm1 "%s" not recognized. Valid options are: %s', ...
        Cond2, strjoin(fieldnames(map), ', '));
end

% Load the MAT file
load(map.(dataset).matfile, '-mat');  % This puts e.g. Agasum into the workspace

% Get the struct into a local variable
SummaryStruct = eval(map.(dataset).varname);

% Your existing loop to populate SummaryStruct
for p = 1:length(conditions)
    pharm = conditions{p};
    SummStructNumber = size(SummaryStruct.(pharm), 2) + 1;

    for h = 1:length(Hzs)
        Hz = Hzs{h};

        SummaryStruct.(pharm)(SummStructNumber).Expt = Expt.marker;
        SummaryStruct.(pharm)(SummStructNumber).Internal = Expt.internal;
        SummaryStruct.(pharm)(SummStructNumber).stim = Expt.stim;
        SummaryStruct.(pharm)(SummStructNumber).temp = Expt.temp;
        SummaryStruct.(pharm)(SummStructNumber).CaMg = Expt.CaMg;
        SummaryStruct.(pharm)(SummStructNumber).stimInterval = Expt.trialInterval;
        SummaryStruct.(pharm)(SummStructNumber).region = Expt.region;
        SummaryStruct.(pharm)(SummStructNumber).(Hz) = Data.(pharm).(Hz);
        SummaryStruct.(pharm)(SummStructNumber).AvgPeaks = Data.(pharm).Peaks;
        SummaryStruct.(pharm)(SummStructNumber).NormPeaks = Data.(pharm).NormPeaks;
        SummaryStruct.(pharm)(SummStructNumber).PPR = Data.PPR.(pharm);

        if strcmp(pharm, 'Control') && numel(conditions) > 1
            SummaryStruct.(pharm)(SummStructNumber).Pharmacology = conditions(end);
            SummaryStruct.Control(SummStructNumber).allTrials = Data.allTrials;
            SummaryStruct.Control(SummStructNumber).basesuballTrials = Data.basesuballTrials;
            SummaryStruct.Control(SummStructNumber).allfirststimPeaks = Data.allfirststimPeaks;
        end

        % if ~strcmp(pharm, 'Control')
        %     SummaryStruct.(pharm)(SummStructNumber).Concentration = Data.(pharm).Concentration;
        % end

    end
end

% Assign it back to the original variable name in the workspace
assignin('base', map.(dataset).varname, SummaryStruct);
clear adFields ADName ADNames allData allTrials allY avginghandles avgWindow ax baseline basesub boneMap
clear c calcRs colIdx endIdx f fieldNames fieldNums firstIdx h Hz HzName hzTrialNames i inRange 
clear j k lasIdx legendHandles lineHandles lines lineSpacing localMinIdx map matchedCols minCenter minima 
clear minWindows name nTrials nums order parts peakVals pharm pharmLegend pharmMatch pharmName plotHandles 
clear row Rs sortedFieldNames sortedStruct sortIdx startIdx stim SummaryStruct SummStructNumber t thisTrialName timePoints
clear traceColor trial trialCount trialIdx trialLength trialNames trialNamesToAvg vlineTimes wave win
clear winList x xMax xrange y ymax ymin

    save(fullfile(folder, sprintf('%s.mat', Expt.marker)))
toc