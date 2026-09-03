%% version 1: 6/7/25

%%
tic
folder = "\\gonzo\gonzo\Lauren gonzo\250605 - LP142 - EPSCs cono-gvia\cell G";
figurefolder = fullfile(folder, 'Matlab figures');
mkdir(figurefolder)
addpath(genpath(figurefolder))

Expt.marker = 'LP142g';
Expt.internal = 'CsGluc';
Expt.stim = 'theta';
Expt.temp = 'RT';
Expt.CaMg = '1.2mM Ca, 1mM Mg';
Expt.region = 'V1';

Epoch1 = 'Control';     ControlTrial = 'e9';
Epoch2 = 'e10';         Pharm1 = 'ConoGVIA';
% Epoch3 = 'e11';         Pharm2 = 'Aga_CdCl2';

Hzs = {'x1', 'x5_5Hz', 'x5_20Hz', 'x5_40Hz'};
NumPositions = 4; %number of stim paradigms 
ps = arrayfun(@(x) ['p' num2str(x)], 1:NumPositions, 'UniformOutput', false);

epochs = {ControlTrial, Epoch2};
pharms = {Epoch1, Pharm1};
pharmSave = {'Control', 'Cono-GVIA'};
concentrations = {'1uM'};

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
    if ~isreal(Rs)
        Rsreal = real(Rs);
        disp('Rs contained imaginary values')
    else Rsreal = Rs;
    end
figure;
scatter((1:length(Rsreal)),Rsreal)
ylim([0 30])
xlim([216 334])
ylabel('R_s')
xlabel('Trial')
title(Expt.marker)
saveas(gcf,sprintf('%s/%s', figurefolder, 'Rs'))
%% Avgviewparts (pull individual trials into an alltrials matrix 
% Loop over all pharm and Hz combinations
for p = 1:length(pharms)
    pharm = pharms{p};
    for h = 1:length(Hzs)
        Hz = Hzs{h};
        
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
        trialFields = sort(trialFields);  % Optional: sort to keep order predictable
        Data.(pharm).(Hz).waveNames = trialFields;
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

%% Plot all trials - save for the x/ylim mods
for p = 1:length(pharms)
    pharm = pharms{p};

    figure('Name', pharm, 'NumberTitle', 'off');

    for j = 1:NumPositions
        Hz = Hzs{j};
        nexttile;

            allTrials = Data.(pharm).(Hz).allTrials;

            plot(allTrials, 'LineWidth', 1);  % Each column is a trial
            title(Hz, 'Interpreter', 'none');
            xlabel('Time');
            ylabel('Amplitude');
              
            if j == 1
                xlim([800 1600]);
                 ymin = min(allTrials(:))+100;
                ylim([ymin, 100]);
               
            elseif j == 2
                xlim([800 12000]);
                 ymin = min(allTrials(:))+100;
                ylim([ymin, 100]);
            elseif j ==3 
                xlim([800 5000]);
                 ymin = min(allTrials(:))+100;
                ylim([ymin, 100]);
            elseif j == 4
                xlim([800 4000])
                 ymin = min(allTrials(:))+100;
                ylim([ymin, 100]);
            end
       
    end
    sgtitle(pharm)
end

%% Delete waves + avgwin
 
for p = 1:length(pharms)
    pharm = pharms{p};
    deletedTrials.(pharm) = struct;

    fig = figure('Name', pharm, 'NumberTitle', 'off', 'Position',[ 310          50        1254         946]);
    t = tiledlayout(2, 2, 'TileSpacing', 'compact');
    sgtitle(pharm);

    lineHandles = cell(NumPositions, 1);
    allData = cell(NumPositions, 1);

    for j = 1:NumPositions
        Hz = Hzs{j};
        deletedTrials.(pharm).(Hz) = [];

        nexttile;
        hold on;
        allTrials = Data.(pharm).(Hz).allTrials;
        allData{j} = allTrials;
        lineHandles{j} = gobjects(size(allTrials, 2), 1);
        
        waveNames = Data.(pharm).(Hz).waveNames;
        for trialIdx = 1:size(allTrials, 2)
            h = plot(allTrials(:, trialIdx), 'DisplayName', waveNames{trialIdx});
            h.ButtonDownFcn = @(src, ~) set(src, 'Visible', 'off');
            lineHandles{j}(trialIdx) = h;
        end

        title(Hz, 'Interpreter', 'none');
        xlabel('Time'); ylabel('Amplitude');
        legend('interpreter', 'none', 'Location', 'bestoutside');  % optional but useful
        switch j
            case 1; xlim([800 1600]);
            case 2; xlim([800 12000]);
            case 3; xlim([800 5000]);
            case 4; xlim([800 4000]);
        end

        ymin = min(allTrials(:)) + 100;
        ylim([ymin, 100]);
    end

    % Corrected 'Done' button callback with fig handle
    uicontrol('Style', 'pushbutton', 'String', 'Done', ...
        'Position', [20, 20, 100, 30], ...
        'Callback', @(~, ~) finalizeCurrentFigure(pharm, Hzs, lineHandles, allData, fig));

    waitfor(fig);  % Will unblock only when fig is closed
end

%getavgwin
for p = 1:length(pharms)
    pharm = pharms{p};

    for j = 1:length(Hzs)
        Hz = Hzs{j};

        Data.(pharm).(Hz).finalAvg = mean(Data.(pharm).(Hz).finalallTrials,2);
    end
end

%% Baseline subtract
for p = 1:length(pharms)
    pharm = pharms{p};

    for j = 1:length(Hzs)
        Hz = Hzs{j};
        
        for k = 1:size(Data.(pharm).(Hz).finalallTrials,2)
        Data.(pharm).(Hz).basesubTrials(:,k) = Data.(pharm).(Hz).finalallTrials(:,k) - mean(Data.(pharm).(Hz).finalallTrials(1:800,k));
        end
        Data.(pharm).(Hz).basesubAvg = mean(Data.(pharm).(Hz).basesubTrials,2);
        end
end

for p = 1:length(pharms)
    pharm = pharms{p};

    for j = 1:length(Hzs)
        Hz = Hzs{j};
        
        for k = 1:size(Data.(pharm).(Hz).allTrials,2)
        Data.(pharm).(Hz).basesubAllTrials(:,k) = Data.(pharm).(Hz).allTrials(:,k) - mean(Data.(pharm).(Hz).allTrials(1:800,k));
        end
        end
end


%% plot stacked plot 


 figure;
        s = stackedplot(Data.Control.x1.basesubAllTrials);
        xlim([800  1500])
        for i = 1:length(s.AxesProperties)
    s.AxesProperties(i).YLimits = [-200 1000];  % uniform y-limits
        end 
   title('Control Trials, single stim')

    figure;
        s = stackedplot(Data.ConoGVIA.x1.basesubAllTrials);
        xlim([800  1500])
        for i = 1:length(s.AxesProperties)
    s.AxesProperties(i).YLimits = [-200 1000];  % uniform y-limits
        end 
   title('Cono-GVIA Trials, single stim')

    figure;
        s = stackedplot(Data.Control.x5_5Hz.basesubAllTrials);
        xlim([800  10000])
        for i = 1:length(s.AxesProperties)
    s.AxesProperties(i).YLimits = [-200 1000];  % uniform y-limits
        end 
   title('Control Trials, 5Hz')

    figure;
        s = stackedplot(Data.ConoGVIA.x5_5Hz.basesubAllTrials);
        xlim([800  10000])
        for i = 1:length(s.AxesProperties)
    s.AxesProperties(i).YLimits = [-200 1000];  % uniform y-limits
        end 
   title('Cono-GVIA Trials, 5Hz')

    figure;
        s = stackedplot(Data.Control.x5_20Hz.basesubAllTrials);
        xlim([800  4000])
        for i = 1:length(s.AxesProperties)
    s.AxesProperties(i).YLimits = [-200 1000];  % uniform y-limits
        end 
   title('Control Trials, 20Hz')

    figure;
        s = stackedplot(Data.ConoGVIA.x5_20Hz.basesubAllTrials);
        xlim([800  4000])
        for i = 1:length(s.AxesProperties)
    s.AxesProperties(i).YLimits = [-200 1000];  % uniform y-limits
        end 
   title('Cono-GVIA Trials, 20Hz')

    figure;
        s = stackedplot(Data.Control.x5_40Hz.basesubAllTrials);
        xlim([800  2500])
        for i = 1:length(s.AxesProperties)
    s.AxesProperties(i).YLimits = [-200 1000];  % uniform y-limits
        end 
   title('Control Trials, 40Hz')

    figure;
        s = stackedplot(Data.ConoGVIA.x5_40Hz.basesubAllTrials);
        xlim([800  2500])
        for i = 1:length(s.AxesProperties)
    s.AxesProperties(i).YLimits = [-200 1000];  % uniform y-limits
        end 
   title('Cono-GVIA Trials, 40Hz')


   %% plot stim artifacts
% Define Hzs and the corresponding row indices for each i
rowIndices = {
    1005,                                   % for i = 1
    [1005, 3005, 5005, 7005, 9005],         % for i = 2
    [1005, 1505, 2005, 2505, 3005],         % for i = 3
    [1005, 1255, 1505, 1755, 2005]          % for i = 4
};

figure;

% Choose the Hz index (i)
for i = 1:length(Hzs) 
    Hz = Hzs{i};
    b = rowIndices{i};

% Extract peak data for each condition


for p = 1:2
    pharm = pharms{p};
    
    % Get the corresponding rows from allTrials
    Data.(pharm).(Hz).artifactpeaks = (Data.(pharm).(Hz).allTrials(b, :));  % size: 5 x nTrials
end
end
    % 
    % nexttile 
    % hold on
    % if i == 1
    %     plot(peaks)
    % else 
    % plot(1:5, peaks, '-o', 'DisplayName', Hz);
    % title([pharm ' - ' Hz], 'Interpreter', 'none');
    % xlabel('Stimulation Number');
    % ylabel('Peak Response');
    % ylim padded
end
end
end

sgtitle([pharm], 'Interpreter', 'none');


%% Plot averages of all freqs and conds
figure('position',[448         150        1093         772]);
color = {colors.black, colors.blues.blue};
for j = 1:length(Hzs)
    Hz = Hzs{j};
    nexttile
    hold on

    for p = 1:length(pharms)
    pharm = pharms{p};
    
    plot(Time.ms, Data.(pharm).(Hz).basesubAvg,'DisplayName', pharm, 'color', color{p});
    end
    legend('interpreter', 'none')
    xlabel('Time (ms)')
    ylabel('pA')
end

saveas(gcf,sprintf('%s/%s', figurefolder, 'averages of all freqs and conds'))


%% Find relative peaks (5 peaks without subtraction)
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
            wave = Data.(pharm).(Hz).basesubAvg;

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

figure;
t = tiledlayout(2,1);
for p = 1:2
    pharm = pharms{p};
    if p == 1
                color = {colors.black, colors.grays.gray, colors.grays.medium};
            else 
                color = {colors.blues.dark, colors.blues.blue, colors.blues.medium};
            end
    nexttile
    hold on
    for j = 2:length(Hzs)
            Hz = Hzs{j};
            
            plot(Data.(pharm).NormPeaks.(Hz),'-o','DisplayName', Hz, 'color', color{j-1});
            title(pharm)
            legend('interpreter', 'none', 'location','best')
            ylim([0 4])
            xticks(1:5)
            xlabel(t,'Stim Number')
            ylabel(t,'Normalized EPSC amplitude')
    end
end

saveas(gcf, sprintf('%s/%s', figurefolder, 'normalized EPSC amplitudes'))

% %% Find peaks 
% % Define detection windows
% minWindows.x1 = [1050 1200];
% minWindows.x5_5Hz = [1050 1200; 3050 3200; 5050 5200; 7050 7200; 9050 9200];
% minWindows.x5_20Hz = [1050 1200; 1550 1700; 2050 2200; 2550 2700; 3050 3200];
% minWindows.x5_40Hz = [1050 1200; 1300 1450; 1550 1700; 1800 1950; 2050 2200];
% 
% % Loop over pharms and Hzs
% for p = 1:length(pharms)
%     pharm = pharms{p};
%     Data.(pharm).Peaks = struct;
% 
%     for h = 1:length(Hzs)
%         Hz = Hzs{h};
%         if h == 1
%         wave = Data.(pharm).(Hz).basesubAvg;
% 
%         elseif h > 1
%         wave = Data.(pharm).PPR.firstPkSubtrd.(Hz);
%         winList = minWindows.(Hz);
% 
%         minima = nan(1, size(winList, 1));
%         for stim = 1:size(winList, 1)
%             win = winList(stim, 1):winList(stim, 2);
%             [~, localMinIdx] = min(wave(win));
%             minCenter = win(1) + localMinIdx - 1;
% 
%             avgWindow = max(minCenter-4,1) : min(minCenter+4, length(wave));
%             minima(stim) = mean(wave(avgWindow));
%         end
%         if h == 1
%             Data.(pharm).Peaks.x1 = minima;
%         elseif h > 1
%             Data.(pharm).Peaks.(Hz) = minima;
%         end
%     end
%     end
% end
% 
% % Plotting
% figure;
% for p = 1:length(pharms)
%     pharm = pharms{p};
%     nexttile;
%     hold on;
% 
%     for h = 2:length(Hzs)
%         Hz = Hzs{h};
%         yvals = Data.(pharm).Peaks.(Hz);
%         plot(1:length(yvals), yvals, '-o', 'DisplayName', Hz);
%     end
% 
%     title(pharm); xlabel('Stim Number'); ylabel('Min dF/F');
%     legend('Location', 'best'); grid on;
% end
% 
% saveas(gcf, sprintf('%s/%s', figurefolder, 'EPSC peaks over trials'))
% 
%% Subtract first peak 

for p = 1:length(pharms)
    pharm = pharms{p};

    for j = 2:length(Hzs)
        Hz = Hzs{j};
        
        Data.PPR.(pharm).firstPkSubtrd.(Hz) = Data.(pharm).(Hz).basesubAvg - Data.(pharm).x1.basesubAvg;
    end
end

figure;
for p = 1:length(pharms)
    pharm = pharms{p};

    for j = 2:length(Hzs)
        Hz = Hzs{j};

        nexttile
        hold on
        plot(Data.(pharm).(Hz).basesubAvg)
        plot(Data.PPR.(pharm).firstPkSubtrd.(Hz))
        xlim([800 12000])
        ylim([-200 50])
        title(pharm, Hz,'interpreter','none')
    end
end

%% Calculate PPR
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

%%
EPSCsum

for p = 1:length(pharms)
    pharm = pharms{p};
    SummStructNumber = (size(EPSC_SUMMARY.(pharm),2)+1);

    for h = 1:length(Hzs)
        Hz = Hzs{h};
         

         EPSC_SUMMARY.(pharm)(SummStructNumber).Expt = Expt.marker;
         EPSC_SUMMARY.(pharm)(SummStructNumber).Internal = Expt.internal;
         EPSC_SUMMARY.(pharm)(SummStructNumber).stim = Expt.stim;
         EPSC_SUMMARY.(pharm)(SummStructNumber).temp = Expt.temp;
         EPSC_SUMMARY.(pharm)(SummStructNumber).CaMg = Expt.CaMg;
         EPSC_SUMMARY.(pharm)(SummStructNumber).region = Expt.region;
         EPSC_SUMMARY.(pharm)(SummStructNumber).(Hz) = Data.(pharm).(Hz);
         EPSC_SUMMARY.(pharm)(SummStructNumber).Peaks = Data.(pharm).Peaks;
         EPSC_SUMMARY.(pharm)(SummStructNumber).NormPeaks = Data.(pharm).NormPeaks;
         EPSC_SUMMARY.(pharm)(SummStructNumber).PPR = Data.PPR.(pharm);


  if strcmp(pharm, 'Control') && numel(pharms) >1
                 EPSC_SUMMARY.(pharm)(SummStructNumber).Pharmacology = pharms(end);
       
  end
    end
end



