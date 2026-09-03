% version 1: 6/7/25
% v2: 6/24/25-6/26/25. Tweaked colors in avgviewparts to bone and removed NaNs from Rs. Added more plotting to plot PPR and a section to choose to plot all waves, and a figure to overlay avgWave with first peak sub
% v3: 7/8/25: Redid order, added section to plot peaks over time with
% pharmacology

%%
tic
folder = "\\bunson\bunson\Higley_Lab\Lauren bunsen\250811 - LP166 - EPSCs cono muscarine\cell E";
figurefolder = fullfile(folder, 'Matlab figures');
mkdir(figurefolder)
addpath(genpath(figurefolder))
start = '7:32';

Expt.marker = 'LP166e'; 
Expt.internal = 'CsGluc';
Expt.stim = 'theta';
Expt.temp = 'RT';
Expt.CaMg = '1.2mM Ca, 1mM Mg';
Expt.region = 'V1';
Expt.trialInterval = 15; % ISI seconds

ControlTrial = 'e5';         Epoch1 = 'Control';     
      Epoch2 = 'e6';         Pharm1 = 'ConoGVIA';
      Epoch3 = 'e7';         Pharm2 = 'ConoGVIA_Muscarine'; %'AgaTK_CdCl2'; % can't have a +
    
Hzs = {'x1', 'x5_5Hz', 'x5_20Hz', 'x5_40Hz'};
NumPositions = 4; %number of stim paradigms 
ps = arrayfun(@(x) ['p' num2str(x)], 1:NumPositions, 'UniformOutput', false);

epochs = {ControlTrial, Epoch2, Epoch3};
pharms = {Epoch1, Pharm1, Pharm2};

pharmSave = {'Control', 'ConoGVIA', 'ConoGVIA Muscarine'};
concentrations = {'1uM', '10uM'};

% List of pharmacology conditions and colors
Colors
color = cell(1, numel(pharms));  % initialize color cell array
color{1} = colors.gray;          % always assign gray to the first condition

if numel(pharms) >= 2
    if strcmp(pharms{2}, 'AgaTK')
        color{2} = colors.Aga;
    elseif strcmp(pharms{2}, 'ConoGVIA')
        color{2} = colors.Cono;
    elseif strcmp(pharms{2}, 'Muscarine')
        color{2} = colors.Muscarine;
    end
end

if numel(pharms) >= 3
    if contains(pharms{3}, 'CdCl2')
        color{3} = colors.CdCl2;
    elseif strcmp(pharms{3}, 'Muscarine_ConoGVIA')
        color{3} = colors.Cono;
    elseif strcmp(pharms{3}, 'AgaTK_Muscarine')
        color{3} = colors.Muscarine;
    elseif strcmp(pharms{3}, 'ConoGVIA_Muscarine')
        color{3} = colors.Muscarine;
    else 
        color{3} = colors.black;
    end
end

Data = struct;

for j = 1:length(epochs)
    epoch = epochs{j};
    pharm = pharms{j};

    % Find all ITX files matching the current epoch
    FileNames = dir(fullfile(folder, ['*' epoch '*.itx']));

    for k = 1:numel(FileNames)
        avgdName = FileNames(k).name;
        fullPath = fullfile(folder, avgdName);

        % Extract position from filename: look for "p1", "p2", etc.
        posMatch = regexp(avgdName, 'p(\d)', 'tokens');
        posNum = str2double(posMatch{1}{1});  % Convert '1' to 1
        if posNum < 1 || posNum > NumPositions
            warning('Position %d out of range in file: %s', posNum, avgdName);
            continue;
        end

        Hz = Hzs{posNum};  % Map position to Hz label

        % Read data and store it
        data = readITXwaves(fullPath);
        Data.(pharm).(Hz) = data;
    end
end

Time.TimeStart = 0;
Time.dt = 1/10000; 
Time.Trialpts = 14000;
Time.sec= mod(Time.TimeStart + (0:Time.Trialpts-1)*Time.dt, 1024);% WHY DOES THIS WORK??
Time.sec = Time.sec';
Time.ms = 1000*Time.sec;
Colors
clear posNum        clear posMatch
toc

load('physCellRs0.mat')
Rs = physCellRs0.data'; clear physCellRs0
    if any(isnan(Rs))
        Rs = Rs(~isnan(Rs));     
    end
Rs = real(Rs);

% pull individual trials into an alltrials matrix + baseline subtract 

% Loop over all pharm and Hz combinations
for p = 1:length(pharms)
    pharm = pharms{p};
    for h = 1:length(Hzs)
        Hz = Hzs{h};
         Data.(pharm).(Hz).allTrials = struct();
         
        % Get the struct that contains the waveforms
        waveStruct = Data.(pharm).(Hz);

        % Find all field names matching AD0_<number> (excluding *_avg)
        fieldNames = fieldnames(waveStruct);
        trialFields = {};

        for i = 1:numel(fieldNames)
            field = fieldNames{i};

            if ~isempty(regexp(field, '^AD0_\d+$', 'once'))
                trialFields{end+1} = field; 
            end
        end

        % Sort field names by numeric index (so AD0_10 doesn't come before AD0_2)
        % trialFields = sort(trialFields);  % Optional: sort to keep order predictable
        Data.(pharm).(Hz).ADNames = trialFields;
        % Convert to matrix
        nTrials = numel(trialFields);
        if nTrials > 0
            waveformLength = length(waveStruct.(trialFields{1}));
            allTrials = zeros(waveformLength, nTrials);

            for k = 1:nTrials
                allTrials(:, k) = waveStruct.(trialFields{k});
            end

            % Save to struct
            Data.(pharm).(Hz).allTrials = allTrials;
        else
            warning('No AD0_x waveforms found for %s %s', pharm, Hz);
        end
    end
end

% Baseline subtract trials
for p = 1:length(pharms)
    pharm = pharms{p};

    for j = 1:length(Hzs)
        Hz = Hzs{j};
        Data.(pharm).(Hz).basesubTrials = [];
        for k = 1:size(Data.(pharm).(Hz).allTrials,2)
        Data.(pharm).(Hz).basesubTrials(:,k) = Data.(pharm).(Hz).allTrials(:,k) - mean(Data.(pharm).(Hz).allTrials(1:800,k));
        end
    end
end


%% Delete waves (only delete spiking, trials that are obviously off, not just not averaged for pharmacology)
clear h; clear lineHandles;

for p = 1:length(pharms)
    pharm = pharms{p};

    fig = figure('Name', pharm, 'NumberTitle', 'off', 'Position', [310 50 1254 946]);
    t = tiledlayout(2, 2, 'TileSpacing', 'compact');
    sgtitle(pharm);
    
    lineHandles = cell(NumPositions, 1);
    allData = cell(NumPositions, 1);

    for j = 1:NumPositions
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
% only plots one figure at a time.. can't debug


% Get user selection via checkbox dialog
selectedIdx = selectPharmsWithCheckbox(pharmSave);

if isempty(selectedIdx)
    disp('No conditions selected. Aborting.');
    return;
end

%Proceed only with selected conditions
for idx = selectedIdx'
    pharm = pharms{idx};
    pharmName = pharmSave{idx};
    disp(['Plotting: ' pharm])  % Debug output

    fig = figure('Name', pharm, 'NumberTitle', 'off', 'Position', [310 50 1254 946]);
    t = tiledlayout(2, 2, 'TileSpacing', 'compact');
    sgtitle(pharmName);

    lineHandles = cell(NumPositions, 1);
    allData = cell(NumPositions, 1);

    for j = 1:NumPositions
        Hz = Hzs{j};
        nexttile;
        hold on;

        allTrials = Data.(pharm).(Hz).allTrials;
        allData{j} = allTrials;
        lineHandles{j} = gobjects(size(allTrials, 2), 1);

        ADNames = Data.(pharm).(Hz).waveNames;
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



%% Collect all trials, base subtract and calculate minima of first stim. Choose trials for averaging.
Data.allTrials = {};
Data.basesuballTrials = struct();
Data.allfirststimPeaks = struct();

for i = 1:numel(pharms)
    pharm = pharms{i};

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
f = figure('Position', [199 256 880 643]);
hold on;
xlabel('Trial');
ylabel('Peak EPSC Amplitude');
title('Peak EPSCs Over Time by Condition');

% Create color map
colorMap = containers.Map;
for p = 1:numel(pharms)
    pharm = pharms{p};
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
    for p = 1:numel(pharms)
        pharm = pharms{p};
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
legendHandles = gobjects(1, numel(pharms));  % preallocate graphic handles
for p = 1:numel(pharms)
    pharm = pharms{p};
    c = colorMap(pharm);  % color for this condition
    pharmLegend = pharmSave{p};

    % Plot 1 invisible point for legend
    legendHandles(p) = scatter(nan, nan, 40, ...
        'MarkerFaceColor', c, ...
        'MarkerEdgeColor', 'k', ...
        'DisplayName', pharmLegend);
end

% Draw vertical lines every 10 minutes
legend(legendHandles, 'Location', 'northwest');
lineSpacing = 40; % 10 minutes 
xMax = ceil(max(timePoints) / 5) * 5;
xlim([0 xMax]);
vlineTimes = lineSpacing * (1:ceil(xMax/lineSpacing));
for x = vlineTimes
    xline(x, 'k:', 'LineWidth', 1.5);
end


saveas(gcf, sprintf('%s/%s', figurefolder, 'EPSC amplitude peaks over conditions'))
 
% CREATE GUI TO INPUT FIRST/LAST TRIALS FOR AVERAGING
% Create figure
for p = 1:length(pharms)
    pharm = pharms{p};
    parts = split(Data.(pharm).ADNames(1,1), '_');
    Data.(pharm).firstTrialNum = parts(2);
    parts = split(Data.(pharm).ADNames(1,end),'_');
    Data.(pharm).lastTrialNum = parts(2);
end

f = figure('Name','Input First/Last Trials for Averaging', 'position', [1126 623 389 159]);

avginghandles = struct();
guidata(f, avginghandles)

row = length(pharms);
trialCount = 1;

for p = 1:length(pharms)
    pharm = pharms{p}; 

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


uicontrol(f, 'Style','pushbutton','String','Submit', 'Position', [150, 10, 100, 30], ...
    'callback', @(src, event) submitCallbackEPHYS(f, Data, avginghandles, pharms));
% Wait for user to press submit
uiwait(f);  % Execution will pause here

% After user clicks Submit
close all;  % Or just: close(f);

% Do your next steps here
disp('Submit clicked and figure closed.');

%% Calculate first stim averages, plot all averages by Hz
for p = 1:length(pharms)
    pharm = pharms{p};
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
plotHandles = gobjects(1, length(pharms)); 

for p = 1:length(pharms)
    pharm = pharms{p};
    
    hold on;
    plotHandles(p) = plot(0:1:352,Data.(pharm).firststimavgTrace, 'color',color{p}, 'linewidth', 1.5);
    title('Average EPSCs')
    ylabel('pA')
    xlabel('Time (msec)')
    xlim([0 350])
    % ylim([-350 100])
end
legend(plotHandles, pharmSave, 'location','southwest')

saveas(gcf,sprintf('%s/%s%s', figurefolder, 'Average first stim EPSCs over conditions'));
close all


% Calculate frequency averages
for p = 1:length(pharms)
    pharm = pharms{p};
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

figure('position',[448 150 1093 772]);

for j = 1:length(Hzs)
    Hz = Hzs{j};
    nexttile
    hold on

    for p = 1:length(pharms)
    pharm = pharms{p};
    pharmName = pharmSave{p};
    
    plot(Time.ms, Data.(pharm).(Hz).avgWave,'DisplayName', pharmName, 'color', color{p},'linewidth',1.5);
            switch j
            case 1; xlim([80 200]); 
            case 2; xlim([80 1100]); 
            case 3; xlim([80 400]); 
            case 4; xlim([80 300]);
            end

            
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
            ylim([ymin-300, ymax+40]);  % add buffer
end
saveas(gcf,sprintf('%s/%s', figurefolder, 'averages of all freqs and conds'))

%% Find relative peaks of trains & normalize peaks
% Define detection windows
minWindows.x1 = [1050 1200];
minWindows.x5_5Hz = [1050 1200; 3050 3200; 5050 5200; 7050 7200; 9050 9200];
minWindows.x5_20Hz = [1050 1200; 1550 1700; 2050 2200; 2550 2700; 3050 3200];
minWindows.x5_40Hz = [1050 1200; 1300 1450; 1550 1700; 1800 1950; 2050 2200];

for p = 1:length(pharms)
    pharm = pharms{p};

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
for p = 1:length(pharms)
    pharm = pharms{p};

    for j = 1:length(Hzs)
        Hz = Hzs{j};
    
            if j == 1
                
                Data.(pharm).NormPeaks.(Hz)(1) = Data.(pharm).Peaks.(Hz)/Data.(pharm).Peaks.(Hz);
                
            elseif j > 1
                for stim = 1:5
                Data.(pharm).NormPeaks.(Hz)(stim) = Data.(pharm).Peaks.(Hz)(1,stim)/Data.(pharm).Peaks.(Hz)(1,1);
                end
            end
        end
    end

% Plot normalized peaks
HzNames = {'1','5Hz','20Hz','40Hz'};
if numel(pharms) >= 2
    if strcmp(pharms{2}, 'AgaTK')
        color{2} = colors.Aga;
    elseif strcmp(pharms{2}, 'CdCl2')
        color{2} = colors.Cono;
    end
end

if numel(pharms) >= 3
    if contains(pharms{3}, 'CdCl2')
        color{3} = colors.CdCl2;
    end
end

figure;
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
        pharm = pharms{p};  
        pharmName = pharmSave{p};
            plot(Data.(pharm).NormPeaks.(Hz),'-o','DisplayName', pharmName, 'color', color{p});
            title(HzName)        
            ylim([0 2])
            xticks(1:5)
            xlabel(t,'Stim Number')
            ylabel(t,'Normalized EPSC amplitude')
            yline(1,'--','color',colors.gray)

    end
end

saveas(gcf, sprintf('%s/%s', figurefolder, 'normalized EPSC amplitudes'))

%% Subtract first peak, calculate PPR and RS 

for p = 1:length(pharms)
    pharm = pharms{p};

    for j = 2:length(Hzs)
        Hz = Hzs{j};
        
        Data.PPR.(pharm).firstPkSubtrd.(Hz) = Data.(pharm).(Hz).avgWave - Data.(pharm).x1.avgWave;
    end
end
n = 1:length(Data.Control.x1.avgWave);


% Plot overlaid traces
figure('position',[312 127 1365 823],'visible','off');
tiledlayout(2,3)
for p = 1:(length(pharms))-1
    pharm = pharms{p};

    for j = 2:length(Hzs)
        Hz = Hzs{j};

        nexttile
        hold on
        plot(Data.(pharm).x1.avgWave,'--','linewidth',1.5,'color',colors.gray)
        plot(Data.(pharm).(Hz).avgWave,'color',color{2})
        plot(Data.PPR.(pharm).firstPkSubtrd.(Hz),'color',colors.blues.medium)
            switch j
            case 1; xlim([800 2000]); 
            case 2; xlim([800 11000]); 
            case 3; xlim([800 4000]); 
            case 4; xlim([800 3000]);
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
        title(pharm, Hz,'interpreter','none')
        legend('Single stim','Average','First Peak Subtracted','location','best')
    end
end
saveas(gcf,sprintf('%s/%s', figurefolder,'Overlaid Averages with First Peak subtracted'))

% Calculate PPR
for p = 1:2
    pharm = pharms{p};

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
% Plot PPR
HzNames = {'1','5Hz','20Hz','40Hz'};
color{1} = colors.black;
if strcmp(Pharm1, 'ConoGVIA') || strcmp(Pharm1, 'Cono-GVIA')
    color{2} = colors.Cono;
elseif strcmp(Pharm1, 'AgaTK') || strcmp(Pharm1, 'Aga-TK')
    color{2} = colors.Aga;
else color{2} = colors.turq;
end

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
        pharm = pharms{p};  
        pharmName = pharmSave{p};
        
        plot(1,Data.PPR.(pharm).(Hz).PPR,'o','MarkerSize',8, 'color', color{p},'DisplayName',pharmName);
        yline(1,'--','color', colors.grays.medium,'HandleVisibility','off')
            title(HzName)        
            ylim([0 2])
            xticks([])
            ylabel(t,'PPR')

    end
end

saveas(gcf, sprintf('%s/%s', figurefolder, 'PPR'))

% Plot Rs
% Get first and last fieldnames
firstField = fieldNames{1};
lastField  = fieldNames{end};

% Extract the numeric suffix using regexp
firstAD = str2double(regexp(firstField, '\d+$', 'match', 'once'));
lastAD  = str2double(regexp(lastField, '\d+$', 'match', 'once'));

figure;

scatter(1:length(Rs),Rs)
xlim([firstAD lastAD])
ylabel('R_s')
xlabel('Trial')
title(Expt.marker)
saveas(gcf,sprintf('%s/%s', figurefolder, 'Rs'))


%%
tic

% Mapping of Pharm1 to mat file + variable name
map = struct( ...
    'AgaTK',     struct('matfile', 'EPSCsAgaTK.mat',   'varname', 'AgaTK'), ...
    'ConoGVIA',  struct('matfile', 'EPSCsConoGVIA.mat',  'varname', 'ConoGVIA'), ...
    'Muscarine', struct('matfile', 'EPSCsMuscarine.mat',  'varname', 'Muscarine') ...
);

% Check Pharm1 is valid
if ~isfield(map, Pharm1)
    error('Pharm1 "%s" not recognized. Valid options are: %s', ...
          Pharm1, strjoin(fieldnames(map), ', '));
end

% Load the MAT file
load(map.(Pharm1).matfile, '-mat');  % This puts e.g. Agasum into the workspace

% Get the struct into a local variable
SummaryStruct = eval(map.(Pharm1).varname);

% Your existing loop to populate SummaryStruct
for p = 1:length(pharms)
    pharm = pharms{p};
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

        if strcmp(pharm, 'Control') && numel(pharms) > 1
            SummaryStruct.(pharm)(SummStructNumber).Pharmacology = pharms(end);
            SummaryStruct.Control(SummStructNumber).allTrials = Data.allTrials;
            SummaryStruct.Control(SummStructNumber).basesuballTrials = Data.basesuballTrials;
            SummaryStruct.Control(SummStructNumber).allfirststimPeaks = Data.allfirststimPeaks;
        end
    end
end

% Assign it back to the original variable name in the workspace
assignin('base', map.(Pharm1).varname, SummaryStruct);

